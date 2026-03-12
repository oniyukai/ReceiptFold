import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:receipt_fold/entity/drift/drift_database.dart';

enum OriginStatus {
  platformUnconfirmed(16),
  platformConfirmed(32), // 已确认 或 無效
  platformInvalidated(48), // 已确认 或 無效
  platformDonated(64), //  // 已确认 或 且捐贈
  platformConfirmedNotDonated(80), // 已确认且不捐贈後 已開獎
  platformExpired(96), // 兌換期已過 可能還能查到雲端但已經不重要了
  manualScan(112),
  manualEntry(128);

  final int sqlValue;

  const OriginStatus(this.sqlValue);

  static final converter = BasicTypeConverter<OriginStatus, int>(
    toS: (fromR) => fromR.sqlValue,
    toR: (fromS) {
      final List<OriginStatus> sorted = values.toList()..sort((a, b) => a.sqlValue.compareTo(b.sqlValue));
      return sorted.firstWhereOrNull((status) => status.sqlValue >= fromS) ?? sorted.last;
    },
  );
}

class Receipts extends Table with ModifiedMixin, UuidMixin {
  // App欄位
  late final originStatus = integer().map(OriginStatus.converter)();
  late final userNote = text().nullable()();

  // 發票欄位
  late final issuedAt = integer().map(dateTimeConverter)();
  late final totalAmount = real()();
  late final invoiceNumber = text().nullable()();
  late final randomNumber = text().nullable()();
  late final carrierName = text().nullable()();
  late final carrierType = text().nullable()();
  late final carrierId2 = text().nullable()();
  late final sellerName = text().nullable()();
  late final sellerTaxId = text().nullable()();
  late final sellerAddress = text().nullable()();
  late final sellerRemark = text().nullable()();
  late final prizeName = text().nullable()();
  late final prizeAmount = real().nullable()();

  // 原始格式
  late final invoiceJsonSummary = text().nullable()();
  late final invoiceJsonData = text().nullable()();
  late final invoiceJsonDetail = text().nullable()();

  @override
  Set<Column> get primaryKey => {uuid};
}

class ReceiptProducts extends Table with ModifiedMixin, UuidMixin {
  late final receiptUuid = text().references(Receipts, #uuid, onDelete: KeyAction.cascade)();
  late final sequence = integer()();
  late final description = text()();
  late final unitPrice = real()();
  late final quantity = real()();
  late final amount = real()();

  @override
  Set<Column> get primaryKey => {uuid};
}

/// 所有被刪除row的 [Receipts], [ReceiptProducts] 的 [uuid] 都要被登記進來
class DeletedUuids extends Table {
  late final uuid = text().withLength(max: 36)();

  @override
  Set<Column> get primaryKey => {uuid};
}

class ReceiptDao extends SyncableDao {
  ReceiptDao(super.attachedDatabase);

  $ReceiptsTable get _receipts => attachedDatabase.receipts;
  $ReceiptProductsTable get _products => attachedDatabase.receiptProducts;
  $DeletedUuidsTable get _deletedUuids => attachedDatabase.deletedUuids;

  @override
  Future<void> selfTidy() {
    // TODO: implement selfTidy
    return super.selfTidy();
  }

  @override
  Future<void> mergeFrom(MyDriftDatabase otherDb) async {
    // TODO: implement mergeFrom
  }
}
