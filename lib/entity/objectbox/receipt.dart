import 'package:objectbox/objectbox.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/locale/app_language.dart';

@Entity()
class ReceiptHeader {
  @Id() int id = 0;
  int invoiceInstantDate;
  String receiptOrigin_;
  @Backlink()
  final ToMany<ReceiptDetail> details = ToMany<ReceiptDetail>();
  double totalAmount;
  String? invoiceStatus_;
  String? invoiceNumber;
  String? currency;
  String? mainRemark;
  String? randomNumber;
  String? sellerAddress;
  String? sellerBanId;
  String? sellerName;
  String? carrierId2;
  String? carrierType;
  String? carrierName;
  int? prizeAmount;
  String? prizeInformation;
  String? userNote;

  ReceiptHeader({
    required this.invoiceInstantDate,
    required this.receiptOrigin_,
    required this.totalAmount,
    this.invoiceStatus_,
    this.invoiceNumber,
    this.currency,
    this.mainRemark,
    this.randomNumber,
    this.sellerAddress,
    this.sellerBanId,
    this.sellerName,
    this.carrierId2,
    this.carrierType,
    this.carrierName,
    this.prizeAmount,
    this.prizeInformation,
    this.userNote,
  });


  @Transient()
  ReceiptOrigin get receiptOrigin => ReceiptOrigin.values.fromName(receiptOrigin_) ?? ReceiptOrigin.unknown;
  set receiptOrigin(ReceiptOrigin value) => receiptOrigin_ = value.name;

  @Transient()
  InvoiceStatus? get invoiceStatus => InvoiceStatus.values.fromName(invoiceStatus_);
  set invoiceStatus(InvoiceStatus? value) => invoiceStatus_ = value?.name;

  @Transient()
  DateTime get invoiceDateTime => DateTime.fromMillisecondsSinceEpoch(invoiceInstantDate);
}


enum ReceiptOrigin {
  unknown,
  cloudPlatform,
  manualAddition;

  String get locale => switch (this) {
    unknown => AppLocale.unknownLabel.s,
    cloudPlatform => AppLocale.receiptOriginCloudPlatform.s,
    manualAddition => AppLocale.receiptOriginManualAddition.s,
  };
}


enum InvoiceStatus {
  unconfirmed,
  confirmed,
  invalidated,
  donated,
  confirmedNotDonated;

  String get locale => switch (this) {
    unconfirmed => AppLocale.invoiceStatusUnconfirmed.s,
    confirmed => AppLocale.invoiceStatusConfirmed.s,
    invalidated => AppLocale.invoiceStatusInvalidated.s,
    donated => AppLocale.invoiceStatusDonated.s,
    confirmedNotDonated => AppLocale.invoiceStatusConfirmedNotDonated.s,
  };
}


@Entity()
class ReceiptDetail {
  @Id() int id = 0;
  String sequenceNumber;
  String itemDescription;
  double unitPrice;
  double quantity;
  double amount;
  final ToOne<ReceiptHeader> receiptHeader = ToOne<ReceiptHeader>();

  ReceiptDetail({
    required this.sequenceNumber,
    required this.itemDescription,
    required this.unitPrice,
    required this.quantity,
    required this.amount,
  });

  static void sortList(List<ReceiptDetail> list) {
    list.sort((a, b) {
      final int? numA = int.tryParse(a.sequenceNumber);
      final int? numB = int.tryParse(b.sequenceNumber);
      if (numA != null && numB != null) {
        return numA.compareTo(numB); // 數字小的優先
      } else if (numA != null) {
        return -1; // numA可以轉成數字，優先
      } else if (numB != null) {
        return 1; // numB可以轉成數字，優先
      } else {
        return a.sequenceNumber.compareTo(b.sequenceNumber);
      }
    });
  }
}