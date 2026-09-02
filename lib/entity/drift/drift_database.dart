import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/entity/drift/key_value_store.dart';
import 'package:receipt_fold/entity/drift/receipt.dart';
import 'package:receipt_fold/services/drift_service.dart';
import 'package:uuid/v7.dart';

part 'drift_database.g.dart';

/// 給分批查詢 isIn 用的
const int chunkSize = 900;

class BasicTypeConverter<R, S> extends TypeConverter<R, S> {
  final S Function(R fromR) _toS;
  final R Function(S fromS) _toR;

  const BasicTypeConverter({required this._toS, required this._toR});

  S toS(R fromR) => _toS(fromR);

  R toR(S fromS) => _toR(fromS);

  @override
  S toSql(R value) => _toS(value);

  @override
  R fromSql(S fromDb) => _toR(fromDb);
}

final dateTimeConverter = BasicTypeConverter<DateTime, int>(
  toS: (fromR) => fromR.millisecondsSinceEpoch,
  toR: DateTime.fromMillisecondsSinceEpoch,
);

mixin ModifiedMixin on Table {
  late final modified = integer()
      .clientDefault(() => UnitUtils.nowUnixTime)
      .map(dateTimeConverter)();
}

mixin UuidMixin on Table {
  static const v7 = UuidV7();

  late final uuid = text()
      .clientDefault(() => UuidMixin.v7.generate())
      .withLength(max: 36)();
}

/// 保持一個 [Table] 不出現在另一個 [SyncableDao] 中
abstract class SyncableDao extends DatabaseAccessor<MyDriftDatabase> {
  SyncableDao(super.attachedDatabase);

  /// 實現不需要另外包 [transaction], 也別手動呼叫
  Future<void> selfTidy() async {}

  /// 完成將新內容合併的處理, 如果自身是空庫, 要能夠實現覆蓋結果
  ///
  /// 實現不需要另外包 [transaction], 也別手動呼叫
  Future<void> mergeFrom(MyDriftDatabase otherDb);
}

@DriftDatabase(
  tables: [KeyValueStores, Receipts, ReceiptProducts, DeletedUuids],
)
class MyDriftDatabase extends _$MyDriftDatabase {
  MyDriftDatabase([QueryExecutor? executor])
    : super(executor ?? _openConnection()) {
    if (executor == null) DriftService.appDb = this;
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

  Future<void> mergeFrom(MyDriftDatabase otherDb) => transaction(
    () => Future.wait(daoSet.map((dao) => dao.mergeFrom(otherDb))),
  );

  Future<void> selfTidy() async {
    await transaction(() => Future.wait(daoSet.map((dao) => dao.selfTidy())));
    await customStatement('VACUUM');
  }
}
