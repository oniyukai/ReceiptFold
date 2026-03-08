import 'dart:convert';
import 'dart:io';
import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/entity/drift/key_value_store.dart';
import 'package:receipt_fold/entity/drift/receipt.dart';
import 'package:receipt_fold/pages/menu_settings/page_logs_view.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as p;
import 'package:webdav_client/webdav_client.dart' as webdav;
import 'package:uuid/v7.dart';

part 'drift_database.g.dart';

class BasicTypeConverter<R, S> extends TypeConverter<R, S> {
  final S Function(R fromR) _toS;
  final R Function(S fromS) _toR;

  const BasicTypeConverter({
    required S Function(R fromR) toS,
    required R Function(S fromS) toR,
  }) :  _toS = toS, _toR = toR;

  S toS(R fromR) => _toS(fromR);
  R toR(S fromS) => _toR(fromS);
  @override S toSql(R value) => _toS(value);
  @override R fromSql(S fromDb) => _toR(fromDb);
}

final dateTimeConverter = BasicTypeConverter<DateTime, int>(
  toS: (fromR) => fromR.millisecondsSinceEpoch,
  toR: DateTime.fromMillisecondsSinceEpoch,
);

mixin ModifiedMixin on Table {
  late final modified = integer().clientDefault(() => UnitUtils.nowUnixTime).map(dateTimeConverter)();
}

const globalUuidV7 = UuidV7();
mixin UuidMixin on Table {
  late final uuid = text().clientDefault(() => globalUuidV7.generate())();
}

/// 保持一個 [Table] 不出現在另一個 [SyncableDao] 中
abstract class SyncableDao extends DatabaseAccessor<MyDriftDatabase> {
  SyncableDao(super.attachedDatabase);

  Future<void> selfTidy() async {}

  /// 完成將新內容合併的處理, 如果自身是空庫, 要能夠實現覆蓋結果
  Future<void> mergeFrom(MyDriftDatabase otherDb);
}

@DriftDatabase(tables: [KeyValueStores, Receipts])
class MyDriftDatabase extends _$MyDriftDatabase {
  MyDriftDatabase([QueryExecutor? executor]) : super(executor ?? _openConnection()) {
    if (executor == null) DriftServices.appDb = this;
    driftRuntimeOptions.dontWarnAboutMultipleDatabases = true;
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
  }
}

/// 請確定 [Upload].call([File]) 過程如果不穩定斷連能夠不覆蓋到正常還沒被取代掉的目的地,  [File] 不要手動刪除.
typedef Upload = Future<bool> Function(File);

/// 請確定 [Download].call() 的 [File] 能夠被刪除的暫存檔, 直接給原檔路徑會被刪.
///
/// 請在錯誤時 throw 中斷, 僅當對應無檔案時為 null 表示.
typedef Download = Future<File?> Function();

String get _timestamp => UnitUtils.nowUnixTime.toRadixString(36);

Future<File> _copyFileToTemp(File sourceFile, [String? newFileName]) async {
  final Directory tempDir = await getTemporaryDirectory();
  return sourceFile.copy(p.join(tempDir.path, newFileName ?? 'copyFileToTemp_$_timestamp.temp'));
}

final class DriftServices {
  const DriftServices._();

  static late final MyDriftDatabase appDb;

  static MyDriftDatabase _openFileDb(File file) => MyDriftDatabase(
    NativeDatabase(
      file,
      setup: (db) => db.execute('PRAGMA journal_mode = DELETE;'),
    ),
  );

  // /.---------------- 傳遞層 ----------------
  static Future<File?> downloadLocal(String sourceFilePath) async {
    final File sourceFile = File(sourceFilePath);
    if (!await sourceFile.exists()) return null;
    return _copyFileToTemp(sourceFile);
  }

  static Future<bool> uploadLocal(File file, String targetFilePath) async {
    final File targetFile = File(targetFilePath);
    if (!await targetFile.parent.exists()) await targetFile.parent.create(recursive: true);
    await file.copy(targetFile.path);
    return true;
  }
  // ---------------- 傳遞層 ----------------./

  // /.---------------- 交換層 ----------------
  static Future<File?> pushForce(Upload upload) async {
    LogService('pushForce...', classType: DriftServices).d();
    await appDb.selfTidy();
    final Directory tempDir = await getTemporaryDirectory();
    final File appDbCopyFile = File(p.join(tempDir.path, 'pushForce_$_timestamp.sqlite'));
    bool success = false;
    try {
      await appDb.customStatement("VACUUM INTO '${appDbCopyFile.path}'");
      if (!await appDbCopyFile.exists()) throw Exception('Copy AppDb ${appDbCopyFile.path} failed.');
      success = await upload(appDbCopyFile);
      return success ? appDbCopyFile : null;
    } finally {
      if (!success && await appDbCopyFile.exists()) await appDbCopyFile.delete();
    }
  }

  static Future<File?> pushMerge(Download download, Upload upload) async {
    LogService('pushMerge...', classType: DriftServices).d();
    final File? downloadFile = await download();
    if (downloadFile == null || !await downloadFile.exists()) return await pushForce(upload);
    await appDb.selfTidy();
    bool success = false;
    try {
      final MyDriftDatabase downloadDb = _openFileDb(downloadFile);
      try {
        await downloadDb.mergeFrom(appDb);
      } finally {
        await downloadDb.close();
      }
      success = await upload(downloadFile);
      return success ? downloadFile : null;
    } finally {
      if (!success && await downloadFile.exists()) await downloadFile.delete();
    }
  }

  static Future<void> pullForce(Download download) async {
    LogService('pullForce...', classType: DriftServices).d();
    final File? downloadFile = await download();
    if (downloadFile == null || !await downloadFile.exists()) {
      LogService('downloadFile(${downloadFile?.path}) does not exists.', classType: DriftServices).d();
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
    LogService('pullMerge...', classType: DriftServices).d();
    final File? downloadFile = await download();
    if (downloadFile == null || !await downloadFile.exists()) {
      LogService('downloadFile(${downloadFile?.path}) does not exists.', classType: DriftServices).d();
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
    LogService('syncMerge...', classType: DriftServices).d();
    final File? downloadFile = await pushMerge(download, upload);
    await pullMerge(() => SynchronousFuture(downloadFile));
  }
  // ---------------- 交換層 ----------------./
}

class WebDAV {
  final webdav.Client client;
  final String remoteDir;
  final String remoteFileName;
  late final String remotePath = p.posix.join(remoteDir, remoteFileName);

  WebDAV._(this.client, this.remoteDir, this.remoteFileName);

  static Future<WebDAV> connect(String url, String user, String password, {
    String remoteDir = 'ReceiptFoldSync',
    String remoteFileName = 'drift.sqlite.gz',
  }) async {
    final WebDAV self = WebDAV._(webdav.newClient(url, user: user, password: password), remoteDir, remoteFileName);
    self.client.setHeaders({'content-type': 'application/octet-stream'});
    await self.client.ping();
    await self.client.mkdirAll(remoteDir);
    return self;
  }

  /// [converter] 可以傳入 [gzip.decoder] 來壓縮, 或是傳入 [gzip.encoder] 解壓縮.
  static Future<File> convertFile(File sourceFile, Converter<List<int>, List<int>> converter) async {
    final Directory tempDir = await getTemporaryDirectory();
    final File file = File(p.join(tempDir.path, 'WebDAV_convertFile_$_timestamp.temp'));
    final Stream<List<int>> input = sourceFile.openRead();
    final IOSink output = file.openWrite();
    bool success = false;
    try {
      await input.transform(converter).pipe(output);
      success = true;
      return file;
    } finally {
      await output.close();
      if (!success && await file.exists()) await file.delete();
    }
  }

  Future<File?> download([Future<File> Function(File)? fileTransform]) async {
    LogService('download...', instance: this).d();
    late final webdav.File remoteFile;
    try {
      final remoteFiles = await client.readDir(remoteDir);
      remoteFile = remoteFiles.firstWhere((f) => f.name == remoteFileName);
    } catch (e) {
      LogService('$remotePath not found.', errorObject: e, instance: this).d();
      return null;
    }
    if (remoteFile.isDir == true) throw Exception('$this.download: ${remoteFile.path} cannot be directory.');
    final Directory tempDir = await getTemporaryDirectory();
    final File downloadFile = File(p.join(tempDir.path, 'WebDAV_download_$_timestamp.temp'));
    try {
      await client.read2File(remoteFile.path!, downloadFile.path);
      return await (fileTransform ?? (file) => convertFile(file, gzip.decoder))(downloadFile);
    } finally {
      if (await downloadFile.exists()) await downloadFile.delete();
    }
  }

  Future<bool> upload(File file, [Future<File> Function(File)? fileTransform]) async {
    LogService('upload...', instance: this).d();
    final String remoteCachePath = '$remotePath.cache';
    try {
      // try {
      //   await client.remove(remoteCachePath);
      // } catch (e) {
      //   LogService('client.remove($remoteCachePath)', errorObject: e, instance: this).t();
      // }
      final File convertedFile = await (fileTransform ?? (file) => convertFile(file, gzip.encoder))(file);
      try {
        await client.writeFromFile(convertedFile.path, remoteCachePath);
        // try {
        //   await client.remove(remotePath);
        // } catch (e) {
        //   LogService('client.remove($remotePath)', errorObject: e, instance: this).t();
        // }
        await client.rename(remoteCachePath, remotePath, true);
      } catch (e) {
        try {
          await client.remove(remoteCachePath);
        } catch (e) {
          LogService('client.remove($remoteCachePath)', errorObject: e, instance: this).t();
        }
        rethrow;
      } finally {
        if (await convertedFile.exists()) await convertedFile.delete();
      }
      return true;
    } catch (e) {
      LogService('Failed.', errorObject: e, instance: this).w();
      return false;
    }
  }
}
