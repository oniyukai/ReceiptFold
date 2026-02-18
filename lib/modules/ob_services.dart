import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:receipt_fold/entity/barcode_item.dart';
import 'package:receipt_fold/entity/objectbox/basic_data.dart';
import 'package:receipt_fold/entity/invoice_prize.dart';
import 'package:receipt_fold/entity/objectbox/objectbox.g.dart';
import 'package:path/path.dart' as p;
import 'package:receipt_fold/entity/objectbox/receipt.dart';

final class OBServices {
  const OBServices._();

  static late final Store _store;
  static late final Box<ReceiptFoldDataStore> _receiptFoldDataStoreBox;
  static late final ReceiptDao receiptDao;

  static Future<void> init() async {
    final Directory dir = await getApplicationSupportDirectory();
    _store = await openStore(directory: p.join(dir.path, 'objectbox'));
    _receiptFoldDataStoreBox = _store.box<ReceiptFoldDataStore>();
    receiptDao = ReceiptDao._(_store.box<ReceiptHeader>(), _store.box<ReceiptDetail>());
  }

  static T getSingleEntity<T extends SingleEntity>(T initialEntity) {
    final Box<T> box = _store.box<T>();
    final List<T> entities = box.getAll();
    if (entities.length == 1) {
      return entities.single;
    } else if (entities.isEmpty) {
      initialEntity.id = 0;
      final int id = box.put(initialEntity);
      return box.get(id)!;
    } else {
      final T firstEntity = entities.removeAt(0);
      final List<int> needRemoveIds = entities.map((entity) => entity.id).toList();
      box.removeMany(needRemoveIds);
      return firstEntity;
    }
  }

  static Stream<ReceiptFoldDataStore?> get dataStoreStream =>
      _receiptFoldDataStoreBox
          .query()
          .order(ReceiptFoldDataStore_.id)
          .watch(triggerImmediately: true)
          .map((query) => query.findFirst());

  static List<MobileBarcodeItem> get mobileBarcodeList =>
      getSingleEntity(ReceiptFoldDataStore()).mobileBarcodeList;
  static void updateMobileBarcodeList(List<MobileBarcodeItem> newList) {
    final ReceiptFoldDataStore dataStore = getSingleEntity(ReceiptFoldDataStore());
    dataStore.mobileBarcodeList = newList;
    _receiptFoldDataStoreBox.put(dataStore);
  }

  static List<MemberBarcodeItem> get memberBarcodeList =>
      getSingleEntity(ReceiptFoldDataStore()).memberBarcodeList;
  static void updateMemberBarcodeList(List<MemberBarcodeItem> newList) {
    final ReceiptFoldDataStore dataStore = getSingleEntity(ReceiptFoldDataStore());
    dataStore.memberBarcodeList = newList;
    _receiptFoldDataStoreBox.put(dataStore);
  }

  static List<InvoiceWinningNumber> get invoiceWinningNumberList =>
      getSingleEntity(ReceiptFoldDataStore()).invoiceWinningNumberList;
  static void updateInvoiceWinningNumberList(List<InvoiceWinningNumber> newList) {
    final ReceiptFoldDataStore dataStore = getSingleEntity(ReceiptFoldDataStore());
    dataStore.invoiceWinningNumberList = newList;
    _receiptFoldDataStoreBox.put(dataStore);
  }
}

class ReceiptDao {
  final Box<ReceiptHeader> _headerBox;
  final Box<ReceiptDetail> _detailBox;

  const ReceiptDao._(this._headerBox, this._detailBox);

  QueryBuilder<ReceiptHeader> headerTimeFilter(int startUnixTime, int endUnixTime) =>
      _headerBox.query(ReceiptHeader_.invoiceInstantDate.between(startUnixTime, endUnixTime));

  void upsert(ReceiptHeader header, List<ReceiptDetail>? details) {
    final ReceiptHeader oldHeader = header.id > 0 ? _headerBox.get(header.id)! : header;

    if (details == null) {
      assert(header.id > 0);
      oldHeader
        ..invoiceInstantDate = header.invoiceInstantDate
        ..receiptOrigin_ = header.receiptOrigin_
        ..invoiceStatus_ = header.invoiceStatus_
        ..invoiceNumber = header.invoiceNumber
        ..currency = header.currency
        ..mainRemark = header.mainRemark
        ..randomNumber = header.randomNumber
        ..sellerAddress = header.sellerAddress
        ..sellerBanId = header.sellerBanId
        ..sellerName = header.sellerName
        ..carrierId2 = header.carrierId2
        ..carrierType = header.carrierType
        ..carrierName = header.carrierName
        ..prizeAmount = header.prizeAmount
        ..prizeInformation = header.prizeInformation
        ..userNote = header.userNote;
      _headerBox.put(oldHeader);
      return;
    }

    int sequenceCounter = 1;
    double totalAmount = 0;
    final Set<int> newDetailIds = {};
    for (final ReceiptDetail detail in details) {
      detail
        ..amount = detail.unitPrice * detail.quantity
        ..sequenceNumber = sequenceCounter.toString().padLeft(3, '0')
        ..receiptHeader.target = header;
      totalAmount += detail.amount;
      sequenceCounter += 1;
      if (detail.id > 0) newDetailIds.add(detail.id);
    }
    header.totalAmount = totalAmount;

    final List<int> removeOldDetailIds = [];
    for (final ReceiptDetail oldDetail in oldHeader.details) {
      if (oldDetail.id > 0 && !newDetailIds.contains(oldDetail.id)) {
        removeOldDetailIds.add(oldDetail.id);
      }
    }
    if (removeOldDetailIds.isNotEmpty) _detailBox.removeMany(removeOldDetailIds);

    _headerBox.put(header);
    _detailBox.putMany(details);
  }

  void remove(ReceiptHeader header) {
    assert(header.id > 0);
    final List<int> detailIds = header.details.map((detail) => detail.id).toList();
    if (detailIds.isNotEmpty) _detailBox.removeMany(detailIds);
    _headerBox.remove(header.id);
  }
}
