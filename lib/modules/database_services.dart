import 'package:path_provider/path_provider.dart';
import 'package:receipt_fold/entity/barcode_item.dart';
import 'package:receipt_fold/entity/objectbox/basic_data.dart';
import 'package:receipt_fold/entity/objectbox/binding_carrier.dart';
import 'package:receipt_fold/entity/invoice_prize.dart';
import 'package:receipt_fold/entity/objectbox/objectbox.g.dart';
import 'package:path/path.dart' as p;
import 'package:receipt_fold/entity/objectbox/receipt.dart';

final class DatabaseServices {

  static late Store _store;
  static late final Box<ReceiptFoldInfo> _receiptFoldInfoBox;
  static late final Box<ReceiptFoldDataStore> _receiptFoldDataStoreBox;
  static late final Box<UserInfo> _userInfoBox;
  static late final Box<BindingCarrier> _bindingCarrierBox;
  static late final ReceiptDao receiptDao;

  static Future<void> init() async {
    final dir = await getApplicationSupportDirectory();
    _store = await openStore(directory: p.join(dir.path, 'objectbox'));
    _receiptFoldInfoBox = _store.box<ReceiptFoldInfo>();
    _receiptFoldDataStoreBox = _store.box<ReceiptFoldDataStore>();
    _userInfoBox = _store.box<UserInfo>();
    _bindingCarrierBox = _store.box<BindingCarrier>();
    receiptDao = ReceiptDao(_store.box<ReceiptHeader>(), _store.box<ReceiptDetail>());
  }

  static void dispose() => _store.close();

  static T getSingleEntity<T extends SingleEntity>(T initialEntity) {
    final box = _store.box<T>();
    final entities = box.getAll();
    if (entities.length == 1) {
      return entities.single;
    } else if (entities.isEmpty) {
      initialEntity.id = 0;
      final id = box.put(initialEntity);
      return box.get(id)!;
    } else {
      final firstEntity = entities.removeAt(0);
      final needRemoveIds = entities.map((entity) => entity.id).toList();
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
    final dataStore = getSingleEntity(ReceiptFoldDataStore());
    dataStore.mobileBarcodeList = newList;
    _receiptFoldDataStoreBox.put(dataStore);
  }

  static List<MemberBarcodeItem> get memberBarcodeList =>
      getSingleEntity(ReceiptFoldDataStore()).memberBarcodeList;
  static void updateMemberBarcodeList(List<MemberBarcodeItem> newList) {
    final dataStore = getSingleEntity(ReceiptFoldDataStore());
    dataStore.memberBarcodeList = newList;
    _receiptFoldDataStoreBox.put(dataStore);
  }

  static List<InvoiceWinningNumber> get invoiceWinningNumberList =>
      getSingleEntity(ReceiptFoldDataStore()).invoiceWinningNumberList;
  static void updateInvoiceWinningNumberList(List<InvoiceWinningNumber> newList) {
    final dataStore = getSingleEntity(ReceiptFoldDataStore());
    dataStore.invoiceWinningNumberList = newList;
    _receiptFoldDataStoreBox.put(dataStore);
  }
}

class ReceiptDao {
  final Box<ReceiptHeader> _headerBox;
  final Box<ReceiptDetail> _detailBox;

  const ReceiptDao(this._headerBox, this._detailBox);

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
    for (final newDetail in details) {
      newDetail
        ..amount = newDetail.unitPrice * newDetail.quantity
        ..sequenceNumber = sequenceCounter.toString().padLeft(3, '0');
      totalAmount += newDetail.amount;
      sequenceCounter += 1;
      if (newDetail.id > 0) newDetailIds.add(newDetail.id);
    }
    header.totalAmount = totalAmount;

    final List<int> removeOldDetailIds = [];
    for (final oldDetail in oldHeader.details) {
      if (oldDetail.id > 0 && !newDetailIds.contains(oldDetail.id)) {
        removeOldDetailIds.add(oldDetail.id);
      }
    }
    if (removeOldDetailIds.isNotEmpty) _detailBox.removeMany(removeOldDetailIds);

    _headerBox.put(header);
    for (final detail in details) {
      detail.receiptHeader.target = header;
      _detailBox.put(detail);
    }
  }

  void remove(ReceiptHeader header) {
    assert(header.id > 0);
    final detailIds = header.details.map((detail) => detail.id).toList();
    if (detailIds.isNotEmpty) _detailBox.removeMany(detailIds);
    _headerBox.remove(header.id);
  }
}