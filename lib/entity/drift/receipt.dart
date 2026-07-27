import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:receipt_fold/entity/drift/drift_database.dart';
import 'package:receipt_fold/entity/period.dart';
import 'package:receipt_fold/locale/app_language.dart';

enum OriginStatus {
  platformUnconfirmed(16),
  platformInvalidated(32),
  platformDonated(48),
  platformConfirmed(64),
  platformConfirmedNotDonated(80),
  platformExpired(96),
  manualImport(112),
  manualScan(128),
  manualEntry(144);

  final int sqlValue;

  const OriginStatus(this.sqlValue);

  String get locale => switch (this) {
    platformUnconfirmed => DictKey.originStatusPlatformUnconfirmed,
    platformInvalidated => DictKey.originStatusPlatformInvalidated,
    platformDonated => DictKey.originStatusPlatformDonated,
    platformConfirmed => DictKey.originStatusPlatformConfirmed,
    platformConfirmedNotDonated => DictKey.originStatusPlatformConfirmedNotDonated,
    platformExpired => DictKey.originStatusPlatformExpired,
    manualImport => DictKey.originStatusManualImport,
    manualScan => DictKey.originStatusManualScan,
    manualEntry => DictKey.originStatusManualEntry,
  }.s;

  int toJson() => sqlValue;

  static final List<OriginStatus> sorted = List.unmodifiable(values.toList()..sort((a, b) => a.sqlValue.compareTo(b.sqlValue)));

  static final converter = BasicTypeConverter<OriginStatus, int>(
    toS: (fromR) => fromR.sqlValue,
    toR: (fromS) => sorted.lastWhereOrNull((status) => fromS >= status.sqlValue) ?? sorted.first,
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
  late final invoiceJsonAward = text().nullable()();

  @override
  Set<Column> get primaryKey => {uuid};
}

class ReceiptProducts extends Table with ModifiedMixin, UuidMixin {
  late final receiptUuid = text().references(Receipts, #uuid, onDelete: .cascade)();
  late final sequence = integer()();
  late final description = text()();
  late final unitPrice = real()();
  late final quantity = real()();
  late final amount = real()();

  @override
  Set<Column> get primaryKey => {uuid};
}

/// 所有被刪除row的 [Receipts], [ReceiptProducts] 的 [uuid] 都要被登記進來
class DeletedUuids extends Table with ModifiedMixin {
  late final uuid = text().withLength(max: 36)();

  @override
  Set<Column> get primaryKey => {uuid};
}

class ReceiptDao extends SyncableDao {
  ReceiptDao(super.attachedDatabase);

  $ReceiptsTable get _receipts => attachedDatabase.receipts;
  $ReceiptProductsTable get _products => attachedDatabase.receiptProducts;
  $DeletedUuidsTable get _deletedUuids => attachedDatabase.deletedUuids;

  Stream<Map<Receipt, List<ReceiptProduct>>> queryStream({
    DateTime? issuedAtStart,
    DateTime? issuedAtEnd,
    List<Expression<bool>> conditionals = const [],
    int? limit,
    int? offset,
    OrderingMode order = .desc,})
  {
    final uuidSubquery = _receipts.selectOnly(distinct: true)
      ..addColumns([_receipts.uuid])
      ..join([
        leftOuterJoin(_products, _products.receiptUuid.equalsExp(_receipts.uuid)),
      ]);
    for (final conditional in [
      if (issuedAtStart != null)
        _receipts.issuedAt.isBiggerOrEqualValue(dateTimeConverter.toS(issuedAtStart)),
      if (issuedAtEnd != null)
        _receipts.issuedAt.isSmallerOrEqualValue(dateTimeConverter.toS(issuedAtEnd)),
      ...conditionals,
    ]) {
      uuidSubquery.where(conditional);
    }
    uuidSubquery.orderBy([
      OrderingTerm(expression: _receipts.issuedAt, mode: order),
      OrderingTerm(expression: _receipts.uuid, mode: order),
    ]);
    if (limit != null) uuidSubquery.limit(limit, offset: offset);
    final statement = _receipts.select().join([
      leftOuterJoin(_products, _products.receiptUuid.equalsExp(_receipts.uuid)),
    ]);
    statement.where(_receipts.uuid.isInQuery(uuidSubquery));
    statement.orderBy([
      OrderingTerm(expression: _receipts.issuedAt, mode: order),
      OrderingTerm(expression: _receipts.uuid, mode: order),
      OrderingTerm(expression: _products.sequence, mode: .asc),
      OrderingTerm(expression: _products.uuid, mode: .asc),
    ]);
    return statement.watch().map((rows) {
      final groupedData = <Receipt, List<ReceiptProduct>>{};
      for (final row in rows) {
        final receipt = row.readTable(_receipts);
        final product = row.readTableOrNull(_products);
        final productList = groupedData.putIfAbsent(receipt, () => []);
        if (product != null) productList.add(product);
      }
      return groupedData;
    }).distinct(const DeepCollectionEquality().equals);
  }

  /// [products] 之中的 sequence, totalAmount 會被忽略並自動處理
  Future<Receipt> upsert(Receipt receipt, List<ReceiptProduct> products) async {
    final oldReceipt = (_receipts.select()
      ..where((tbl) => tbl.uuid.equals(receipt.uuid))
    ).getSingleOrNull();
    final oldProducts = (_products.select()
      ..where((tbl) => tbl.receiptUuid.equals(receipt.uuid))
    ).map((e) => MapEntry(e.uuid, e)).get();
    final productUuids = products.map((e) => e.uuid).toSet();
    final oldProductMap = Map.fromEntries(await oldProducts);
    final productDelUuids = oldProductMap.keys.whereNot((id) => productUuids.contains(id)).toList();

    bool isReceiptModified = productDelUuids.isNotEmpty || await oldReceipt != receipt;
    double totalAmount = 0.0;
    for (int i = 0; i < products.length; i += 1) {
      ReceiptProduct product = products[i];
      product = product.copyWith(
        receiptUuid: receipt.uuid,
        sequence: i + 1,
      );
      totalAmount += product.amount;
      final isProductModified = oldProductMap[product.uuid] != product;
      if (isProductModified) isReceiptModified = true;
      products[i] = product.copyWith(modified: isProductModified ? .now() : null);
    }
    receipt = receipt.copyWith(
      modified: isReceiptModified ? .now() : null,
      totalAmount: totalAmount,
    );

    await batch((batch) {
      batch.insertAllOnConflictUpdate(_deletedUuids, productDelUuids.map((id) => DeletedUuidsCompanion.insert(uuid: id)));
      productDelUuids.slices(chunkSize).forEach((chunk) => batch.deleteWhere(_products, (tbl) => tbl.uuid.isIn(chunk)));
      batch.insertAllOnConflictUpdate(_receipts, [receipt]);
      batch.insertAllOnConflictUpdate(_products, products);
    });
    return receipt;
  }

  /// 專門給 API 調取 與 CSV 匯入 的接口, 與 [upsert] 一樣會自動處理 sequence, totalAmount.
  ///
  /// 這並非是單純查 uuid 並更新, 會嘗試替換掉 invoiceNumber, [Period] 都相同的項目, 否則新增.
  Future<void> upsertMany({
    required Map<Receipt, List<ReceiptProduct>> pairMap,
    required OriginStatus scopeStart,
    required OriginStatus scopeEnd,})
  async {
    assert(scopeStart.sqlValue <= scopeEnd.sqlValue);
    Map<String, MapEntry<Receipt, List<ReceiptProduct>>> pairMapToUnique(Map<Receipt, List<ReceiptProduct>> map) => {
      for (final pair in map.entries)
        if ((pair.key.invoiceNumber?.length ?? 0) >= 3)
          '${Period(pair.key.issuedAt).invQuery}${pair.key.invoiceNumber}': pair,
    };

    final uniquePairMap = pairMapToUnique(pairMap);
    final endIndex = OriginStatus.sorted.indexOf(scopeEnd);
    final oldPairMap = Map.fromEntries((
        await Future.wait(
          uniquePairMap.values.slices(chunkSize).map((chunk) => queryStream(
            order: .asc,
            conditionals: [
              _receipts.invoiceNumber.isIn(chunk.map((e) => e.key.invoiceNumber!)),
              if (scopeStart != OriginStatus.sorted.first)
                _receipts.originStatus.isBiggerOrEqualValue(scopeStart.sqlValue),
              if (scopeEnd != OriginStatus.sorted.last)
                _receipts.originStatus.isSmallerThanValue(OriginStatus.sorted[endIndex + 1].sqlValue),
            ],
          ).first),
        )
    ).expand((map) => map.entries));
    final oldUniquePairMap = pairMapToUnique(oldPairMap);

    final productDelUuids = <String>[];
    uniquePairMap.updateAll((invKey, entry) {
      final oldProducts = oldUniquePairMap[invKey]?.value ?? <ReceiptProduct>[];
      final oldReceipt = oldUniquePairMap[invKey]?.key;
      final products = entry.value;
      Receipt receipt = entry.key.copyWith(
        uuid: oldReceipt?.uuid,
        modified: oldReceipt?.modified,
      );
      bool isReceiptModified = products.length < oldProducts.length || receipt != oldReceipt;

      double totalAmount = 0.0;
      for (int i = 0; i < products.length; i += 1) {
        final oldProduct = i < oldProducts.length ? oldProducts[i] : null;
        ReceiptProduct product = products[i];
        product = product.copyWith(
          uuid: oldProduct?.uuid,
          modified: oldProduct?.modified,
          receiptUuid: receipt.uuid,
          sequence: i + 1,
        );
        totalAmount += product.amount;
        final isProductModified = oldProduct != product;
        if (isProductModified) isReceiptModified = true;
        products[i] = product.copyWith(modified: isProductModified ? .now() : null);
      }

      productDelUuids.addAll(oldProducts.whereNotIndexed((index, _) => index < products.length).map((e) => e.uuid));
      return MapEntry(
        receipt.copyWith(
          modified: isReceiptModified ? .now() : null,
          totalAmount: totalAmount,
        ),
        products,
      );
    });

    await batch((batch) {
      batch.insertAllOnConflictUpdate(_deletedUuids, productDelUuids.map((id) => DeletedUuidsCompanion.insert(uuid: id)));
      productDelUuids.slices(chunkSize).forEach((chunk) => batch.deleteWhere(_products, (tbl) => tbl.uuid.isIn(chunk)));
      batch.insertAllOnConflictUpdate(_receipts, uniquePairMap.values
          .map((p) => p.key.toCompanion(true)));
      batch.insertAllOnConflictUpdate(_products, uniquePairMap.values.map((p) => p.value).expand((ls) => ls)
          .map((e) => e.toCompanion(true)));
    });
  }

  Future<void> remove(Receipt receipt) async {
    final uuidsInsertDeleted = <String>[
      receipt.uuid,
      ...await (_products.selectOnly()
        ..addColumns([_products.uuid])
        ..where(_products.receiptUuid.equals(receipt.uuid))
      ).map((row) => row.read(_products.uuid)!)
          .get()
    ];
    await batch((batch) {
      batch.insertAllOnConflictUpdate(_deletedUuids, uuidsInsertDeleted.map((id) => DeletedUuidsCompanion.insert(uuid: id)));
      batch.deleteWhere(_products, (tbl) => tbl.receiptUuid.equals(receipt.uuid));
      batch.deleteWhere(_receipts, (tbl) => tbl.uuid.equals(receipt.uuid));
    });
  }

  @override
  Future<void> selfTidy() async {
    final deletedUuidsQuery = _deletedUuids.selectOnly()..addColumns([_deletedUuids.uuid]);

    // 找尋來自雲端但是時間與號碼相同的 舊receiptUuid
    final platformDupReceiptIdsQuery = _receipts.selectOnly()
      ..addColumns([_receipts.uuid])
      ..where(
        _receipts.invoiceNumber.isNotNull() &
        _receipts.originStatus.isSmallerThanValue(OriginStatus.manualScan.sqlValue) &
        existsQuery(
          _receipts.select()
            ..where((tbl) => (
                tbl.invoiceNumber.equalsExp(_receipts.invoiceNumber) &
                tbl.issuedAt.equalsExp(_receipts.issuedAt)
            ))
            ..where((tbl) => ( // 篩選出modified不是最大, 都是最大則篩選建構時間不是最新
                tbl.modified.isBiggerThan(_receipts.modified) |
                (tbl.modified.equalsExp(_receipts.modified) & tbl.uuid.isBiggerThan(_receipts.uuid))
            )),
        ),
      );

    final productAddToDeletedIds = (_products.selectOnly()
      ..addColumns([_products.uuid])
      ..where(_products.uuid.isNotInQuery(deletedUuidsQuery))
      ..where(_products.receiptUuid.isInQuery(deletedUuidsQuery) | _products.receiptUuid.isInQuery(platformDupReceiptIdsQuery))
    ).map((row) => row.read(_products.uuid)!)
        .get();
    final platformDupReceiptIds = platformDupReceiptIdsQuery.map((row) => row.read(_receipts.uuid)!).get();

    await batch((batch) async {
      // 清理待刪除與應刪除項目
      batch.insertAllOnConflictUpdate(
        _deletedUuids,
        {...await productAddToDeletedIds, ...await platformDupReceiptIds,}
            .map((id) => DeletedUuidsCompanion.insert(uuid: id)),
      );
      batch.deleteWhere(_products, (tbl) => (
          tbl.uuid.isInQuery(deletedUuidsQuery) |
          tbl.receiptUuid.isInQuery(deletedUuidsQuery) |
          tbl.receiptUuid.isNotInQuery(_receipts.selectOnly()..addColumns([_receipts.uuid])) // 清除不在delIds的孤兒, 這不用加到delIdsTbl
      ));
      batch.deleteWhere(_receipts, (tbl) => tbl.uuid.isInQuery(deletedUuidsQuery));

      // 重新計算總和
      final sumSubquery = coalesce<double>([
        subqueryExpression<double>(_products.selectOnly()
          ..addColumns([_products.amount.sum()])
          ..where(_products.receiptUuid.equalsExp(_receipts.uuid)),
        ),
        const Constant(0.0),
      ]);
      batch.update(
        _receipts,
        ReceiptsCompanion.custom(totalAmount: sumSubquery),
        where: (tbl) => tbl.totalAmount.equalsExp(sumSubquery).not(),
      );
    });
  }

  @override
  Future<void> mergeFrom(MyDriftDatabase otherDb) async {
    final otherDeletedUuidsQuery = otherDb.deletedUuids.selectOnly()..addColumns([otherDb.deletedUuids.uuid]);

    final selfReceiptEntries = (_receipts.selectOnly()
      ..addColumns([_receipts.uuid, _receipts.modified])
    ).map((row) => MapEntry(row.read(_receipts.uuid)!, row.read(_receipts.modified)!))
        .get();
    final otherReceiptEntries = (otherDb.receipts.selectOnly()
      ..addColumns([otherDb.receipts.uuid, otherDb.receipts.modified])
      ..where(otherDb.receipts.uuid.isNotInQuery(otherDeletedUuidsQuery))
    ).map((row) => (
    uuid: row.read(otherDb.receipts.uuid)!,
    modified: row.read(otherDb.receipts.modified)!,))
        .get();

    final selfProductEntries = (_products.selectOnly()
      ..addColumns([_products.uuid, _products.modified])
    ).map((row) => MapEntry(row.read(_products.uuid)!, row.read(_products.modified)!))
        .get();
    final otherProductEntries = (otherDb.receiptProducts.selectOnly()
      ..addColumns([otherDb.receiptProducts.uuid, otherDb.receiptProducts.receiptUuid, otherDb.receiptProducts.modified])
      ..where(otherDb.receiptProducts.uuid.isNotInQuery(otherDeletedUuidsQuery))
      ..where(otherDb.receiptProducts.receiptUuid.isNotInQuery(otherDeletedUuidsQuery))
      ..where(otherDb.receiptProducts.receiptUuid.isInQuery(otherDb.receipts.selectOnly()..addColumns([otherDb.receipts.uuid])))
    ).map((row) => (
    uuid: row.read(otherDb.receiptProducts.uuid)!,
    receiptUuid: row.read(otherDb.receiptProducts.receiptUuid)!,
    modified: row.read(otherDb.receiptProducts.modified)!,))
        .get();

    final selfDeletedUuids = (await (_deletedUuids.selectOnly()
      ..addColumns([_deletedUuids.uuid])
    ).map((row) => row.read(_deletedUuids.uuid)!)
        .get()).toSet();

    final selfReceiptMap = Map.fromEntries(await selfReceiptEntries);
    final otherReceiptUuids = (await otherReceiptEntries).where((other) {
      if (selfDeletedUuids.contains(other.uuid)) return false;
      final selfModified = selfReceiptMap[other.uuid];
      if (selfModified == null) return true;
      return other.modified > selfModified;
    }).map((other) => other.uuid);

    final selfProductMap = Map.fromEntries(await selfProductEntries);
    final otherProductUuids = (await otherProductEntries).where((other) {
      if (selfDeletedUuids.contains(other.uuid) ||
          selfDeletedUuids.contains(other.receiptUuid)) {
        return false;
      }
      final selfModified = selfProductMap[other.uuid];
      if (selfModified == null) return true;
      return other.modified > selfModified;
    }).map((other) => other.uuid);

    final inSelfUuids = <String>{...selfReceiptMap.keys, ...selfProductMap.keys};
    final otherReceipts = Future.wait(otherReceiptUuids.slices(chunkSize)
        .map((chunk) => (otherDb.receipts.select()..where((tbl) => tbl.uuid.isIn(chunk))).get())
    ).then((value) => value.expand((ls) => ls));
    final otherProducts = Future.wait(otherProductUuids.slices(chunkSize)
        .map((chunk) => (otherDb.receiptProducts.select()..where((tbl) => tbl.uuid.isIn(chunk))).get())
    ).then((value) => value.expand((ls) => ls));
    final otherDeletedUuids = Future.wait(inSelfUuids.slices(chunkSize)
        .map((chunk) => (otherDb.deletedUuids.select()..where((tbl) => tbl.uuid.isIn(chunk))).get())
    ).then((value) => value.expand((ls) => ls));

    await batch((batch) async {
      batch.insertAllOnConflictUpdate(_receipts, await otherReceipts);
      batch.insertAllOnConflictUpdate(_products, await otherProducts);
      batch.insertAll(_deletedUuids, await otherDeletedUuids, mode: .insertOrIgnore);
    });
    await selfTidy();
  }
}
