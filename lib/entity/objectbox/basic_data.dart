import 'package:objectbox/objectbox.dart';
import 'package:receipt_fold/entity/barcode_item.dart';
import 'package:receipt_fold/entity/invoice_prize.dart';

abstract class SingleEntity {
  int get id;
  set id(int value);
}

@Entity()
class ReceiptFoldDataStore extends SingleEntity {
  @override
  @Id() int id = 0;
  String mobileBarcodeList_;
  String memberBarcodeList_;
  String invoiceWinningNumberList_;

  ReceiptFoldDataStore({
    this.mobileBarcodeList_ = '[]',
    this.memberBarcodeList_ = '[]',
    this.invoiceWinningNumberList_ = '[]',
  });

  @Transient()
  List<MobileBarcodeItem> get mobileBarcodeList => MobileBarcodeItem.listConverter.toR(mobileBarcodeList_);
  set mobileBarcodeList(List<MobileBarcodeItem> value) => mobileBarcodeList_ = MobileBarcodeItem.listConverter.toS(value);

  @Transient()
  List<MemberBarcodeItem> get memberBarcodeList => MemberBarcodeItem.listConverter.toR(memberBarcodeList_);
  set memberBarcodeList(List<MemberBarcodeItem> value) => memberBarcodeList_ = MemberBarcodeItem.listConverter.toS(value);

  @Transient()
  List<InvoiceWinningNumber> get invoiceWinningNumberList => InvoiceWinningNumber.listConverter.toR(invoiceWinningNumberList_);
  set invoiceWinningNumberList(List<InvoiceWinningNumber> value) => invoiceWinningNumberList_ = InvoiceWinningNumber.listConverter.toS(value);
}
