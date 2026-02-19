import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:receipt_fold/entity/drift/key_value_store.dart';
import 'package:receipt_fold/entity/drift/receipt.dart';
import 'package:receipt_fold/pages/menu_settings/page_logs_view.dart';
import 'package:path/path.dart' as p;
import 'package:uuid/v7.dart';

part 'drift_database.g.dart';

class BasicTypeConverter<R, S> extends TypeConverter<R, S> {
  final R Function(S fromS) _toR;
  final S Function(R fromR) _toS;

  const BasicTypeConverter({
    required R Function(S fromS) toR,
    required S Function(R fromR) toS,
  }) : _toR = toR, _toS = toS;

  R toR(S fromDb) => _toR(fromDb);
  S toS(R value) => _toS(value);

  @override
  R fromSql(S fromDb) => _toR(fromDb);

  @override
  S toSql(R value) => _toS(value);
}

final dateTimeConverter = BasicTypeConverter<DateTime, int>(
  toR: DateTime.fromMillisecondsSinceEpoch,
  toS: (fromR) => fromR.millisecondsSinceEpoch,
);
const globalUuidV7 = UuidV7();
mixin ModifiedMixin on Table {
  late final modified = integer().clientDefault(() => DateTime.now().millisecondsSinceEpoch).map(dateTimeConverter)();
}
mixin UuidMixin on Table {
  late final uuid = text().clientDefault(() => globalUuidV7.generate())();
}

/// 保持一個 [Table] 不出現在另一個 [SyncableDao] 中
abstract class SyncableDao extends DatabaseAccessor<MyDriftDatabase> {
  SyncableDao(super.attachedDatabase);

  Future<void> selfTidy() => SynchronousFuture(null);

  /// 完成將新內容合併的處理, 如果自身是空庫, 要能夠實現覆蓋結果
  Future<void> mergeFrom(MyDriftDatabase otherDb);
}

@DriftDatabase(tables: [KeyValueStores, Receipts])
class MyDriftDatabase extends _$MyDriftDatabase {
  MyDriftDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection()) {
    if (executor == null) DriftServices.appDb = this;
  }

  static QueryExecutor _openConnection() => driftDatabase(
    name: 'drift',
    native: const DriftNativeOptions(
      databaseDirectory: getApplicationSupportDirectory,
    ),
  );

  @override
  int get schemaVersion => 1;

  late final KeyValueStoreDao keyValueStoreDao = KeyValueStoreDao(this);
  late final ReceiptDao receiptDao = ReceiptDao(this);

  Set<SyncableDao> get daoSet => {keyValueStoreDao, receiptDao};

  Future<void> mergeFrom(MyDriftDatabase otherDb) =>
      transaction(() => Future.wait(daoSet.map((dao) => dao.mergeFrom(otherDb))));

  Future<void> selfTidy() async {
    await transaction(() => Future.wait(daoSet.map((dao) => dao.selfTidy())));
    await customStatement('VACUUM');
    await customStatement('ANALYZE');
  }
}

/// 請確定 [Upload].call([File]) 過程如果不穩定斷連能夠不覆蓋到正常還沒被取代掉的目的地
typedef Upload = Future<bool> Function(File);

/// 請確定 [Download].call() 的 [File] 能夠被刪除的暫存檔, 直接給原檔路徑會被刪
typedef Download = Future<File?> Function();

final class DriftServices {
  const DriftServices._();

  static late final MyDriftDatabase appDb;

  static MyDriftDatabase _openFileDb(File file) => MyDriftDatabase(driftDatabase(
    name: p.basenameWithoutExtension(file.path),
    native: DriftNativeOptions(
      databaseDirectory: () => SynchronousFuture(file.parent),
    ),
  ));

  // /.---------------- 傳遞層 ----------------
  static Future<File?> downloadLocal(String sourceFilePath) async {
    final File sourceFile = File(sourceFilePath);
    if (!await sourceFile.exists()) return null;
    final Directory dir = await getTemporaryDirectory();
    return sourceFile.copy(p.join(
      dir.path,
      'downloadLocal_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}.sqlite',
    ));
  }

  static Future<bool> uploadLocal(String targetFilePath, File file) async {
    final File targetFile = File(targetFilePath);
    if (!await targetFile.parent.exists()) await targetFile.parent.create(recursive: true);
    await file.copy(targetFile.path);
    return true;
  }

  static Future<File?> downloadWebDAV(dynamic args) => throw UnimplementedError();

  static Future<bool> uploadWebDAV(dynamic args, File file) => throw UnimplementedError();
  // ---------------- 傳遞層 ----------------./

  // /.---------------- 交換層 ----------------
  static Future<File?> pushForce(Upload upload) async {
    final Directory dir = await getTemporaryDirectory();
    final String appDbCopyPath = p.join(
      dir.path,
      'pushForce_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}.sqlite',
    );
    await appDb.customStatement("VACUUM INTO '$appDbCopyPath'");
    final File appDbCopyFile = File(appDbCopyPath);
    if (await upload(appDbCopyFile)) return appDbCopyFile;
    if (await appDbCopyFile.exists()) appDbCopyFile.delete();
    return null;
  }

  static Future<File?> pushMerge(Download download, Upload upload) async {
    final File? downloadFile = await download();
    if (downloadFile == null) return await pushForce(upload);
    final MyDriftDatabase downloadDb = _openFileDb(downloadFile);
    try {
      await downloadDb.mergeFrom(appDb);
    } finally {
      await downloadDb.close();
    }
    if (await upload(downloadFile)) return downloadFile;
    if (await downloadFile.exists()) await downloadFile.delete();
    return null;
  }

  static Future<void> pullForce(Download download) async {
    final File? downloadFile = await download();
    if (downloadFile == null) {
      LogService('downloadFile is null.').i();
      return;
    }
    try {
      await appDb.transaction(() async {
        await appDb.batch((batch) {
          for (final table in appDb.allTables) {
            batch.deleteAll(table);
          }
        });
        await pullMerge(() => SynchronousFuture(downloadFile));
      });
    } finally {
      if (await downloadFile.exists()) await downloadFile.delete();
    }
  }

  static Future<void> pullMerge(Download download) async {
    final File? downloadFile = await download();
    if (downloadFile == null) {
      LogService('downloadFile is null.').i();
      return;
    }
    try {
      final MyDriftDatabase downloadDb = _openFileDb(downloadFile);
      try {
        await appDb.mergeFrom(downloadDb);
      } finally {
        await downloadDb.close();
      }
    } finally {
      if (await downloadFile.exists()) await downloadFile.delete();
    }
  }

  static Future<void> syncMerge(Download download, Upload upload) async {
    final File? downloadFile = await pushMerge(download, upload);
    await pullMerge(() => SynchronousFuture(downloadFile));
  }
  // ---------------- 交換層 ----------------./
}

// // pushForce 不關心 Schema 更動, 就不採用該方案
// static Future<File?> pushForceB(Upload upload) async {
//   final Directory dir = await getTemporaryDirectory();
//   final File appDbCopyFile = File(p.join(
//     dir.path,
//     'pushForceB_${DateTime.now().millisecondsSinceEpoch.toRadixString(36)}.sqlite',
//   ));
//   final MyDriftDatabase appDbCopyDb = _openFileDb(appDbCopyFile);
//   try {
//     await appDbCopyDb.mergeFrom(appDb);
//   } finally {
//     await appDbCopyDb.close();
//   }
//   if (await upload(appDbCopyFile)) return appDbCopyFile;
//   if (await appDbCopyFile.exists()) appDbCopyFile.delete();
//   return null;
// }
//
// // Schema 敏感 棄用
// static Future<void> pullForceA(Download download) async {
//   final File? downloadFile = await download();
//   if (downloadFile == null) {
//     LogService.info.log('downloadFile is null.');
//     return;
//   }
//   try {
//     await appDb.transaction(() async {
//       await appDb.customStatement("ATTACH DATABASE '${downloadFile.path}' AS download_db");
//       try {
//         for (final appDbTable in appDb.allTables) {
//           final String tableName = appDbTable.actualTableName;
//           await appDb.customStatement('DELETE FROM "$tableName"');
//           await appDb.customStatement('INSERT INTO "$tableName" SELECT * FROM download_db."$tableName"');
//         }
//       } finally {
//         await appDb.customStatement("DETACH DATABASE download_db");
//       }
//     });
//   } finally {
//     if (await downloadFile.exists()) await downloadFile.delete();
//   }
// }
