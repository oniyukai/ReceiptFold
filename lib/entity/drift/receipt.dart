import 'package:drift/drift.dart';
import 'package:receipt_fold/entity/drift/drift_database.dart';

class Receipts extends Table with ModifiedMixin {
  late final uuid = text().withLength(max: 36)();
  late final valueString = text()();

  @override
  Set<Column> get primaryKey => {uuid};
}

class ReceiptDao extends SyncableDao {
  ReceiptDao(super.attachedDatabase);

  $ReceiptsTable get receiptTable => attachedDatabase.receipts;

  Future<int> insertReceipt(ReceiptsCompanion entry) =>
      into(receiptTable).insert(entry);

  // 取得所有收據
  Future<List<Receipt>> getAllReceipts() => select(receiptTable).get();

  // 監聽所有收據的變化 (以 purchaseDate 降序排列)
  Stream<List<Receipt>> watchAllReceiptsSortedByDate() {
    return (select(receiptTable)..orderBy([(t) => OrderingTerm.desc(t.modified)]))
        .watch();
  }

  // 刪除所有收據
  Future<int> deleteAllReceipts() => delete(receiptTable).go();

  // 更新收據項目名稱
  Future<bool> updateItemName(int id, String newItemName) {
    return (update(receiptTable)..where((t) => t.rowId.equals(id))).write(
      ReceiptsCompanion(),
    ).then((affectedRows) => affectedRows > 0);
  }

  @override
  Future<void> mergeFrom(MyDriftDatabase otherDb) {
    // TODO: implement syncFrom
    throw UnimplementedError();
  }
}