import 'dart:convert';
import 'dart:typed_data';

import 'package:drift/drift.dart' show Value;
import 'package:enough_convert/big5.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/entity/drift/drift_database.dart';
import 'package:receipt_fold/entity/drift/receipt.dart';

/// ASCII ":"
const int _colon = 0x3A;

class RecognizedInvoice {
  QrCodeInvoice? qrCodeInvoice;
  String? invoiceNumber;
  (String, String, String)? yearMonthDay;
  (String, String, String)? hourMinuteSecond;

  static final rNumber = RegExp(r'^([A-Z]{2})[ -]?(\d{8})$');
  static final rYYYYmmDD = RegExp(r'^(\d{4})[/-](\d{2})[/-](\d{2})$');
  static final rRRRmmDD = RegExp(r'^(\d{3})[/-](\d{2})[/-](\d{2})$');
  static final rHHmmSS = RegExp(r'^(\d{2}):(\d{2}):(\d{2})$');
  static final rHHmm = RegExp(r'^(\d{2}):(\d{2})$');

  (Receipt, List<ReceiptProduct>)? receiptResult() {
    final now = DateTime.now();
    final invoice = qrCodeInvoice;
    final products = <ReceiptProduct>[];
    Receipt receipt = Receipt(
      modified: now,
      uuid: UuidMixin.v7.generate(),
      originStatus: OriginStatus.deviceScan,
      issuedAt: now,
      totalAmount: 0.0,
      invoiceNumber: invoiceNumber,
    );
    var invDate = yearMonthDay;
    if (invoice != null) {
      if (invoiceNumber != null && invoiceNumber != invoice.invoiceNumber) {
        return null;
      }
      invDate = (
        invoice.invoiceDate.substring(0, 3),
        invoice.invoiceDate.substring(3, 5),
        invoice.invoiceDate.substring(5, 7),
      );
      final sellerRemark = <String>[
        if (invoice.sellerUseArea != '**********') invoice.sellerUseArea,
        ?invoice.sellerNote,
      ].join(' ');
      receipt = receipt.copyWith(
        invoiceNumber: Value(invoice.invoiceNumber),
        randomNumber: Value(invoice.randomNumber),
        totalAmount: invoice.totalAmount,
        sellerTaxId: Value(invoice.sellerId),
        sellerRemark: Value(Utils.noEmptyStr(sellerRemark)),
      );
      double totalAmount = 0.0;
      for (int i = 0; i < invoice.items.length; i += 1) {
        final item = invoice.items[i];
        totalAmount += item.unitPrice * item.quantity;
        products.add(
          ReceiptProduct(
            modified: now,
            uuid: UuidMixin.v7.generate(),
            receiptUuid: receipt.uuid,
            sequence: i + 1,
            description: item.name,
            unitPrice: item.unitPrice,
            quantity: item.quantity,
            amount: item.unitPrice * item.quantity,
          ),
        );
      }
      if ((totalAmount - receipt.totalAmount).abs() >= 0.01) {
        products.add(
          ReceiptProduct(
            modified: now,
            uuid: UuidMixin.v7.generate(),
            receiptUuid: receipt.uuid,
            sequence: products.length + 1,
            description: 'Unrecorded Product',
            unitPrice: receipt.totalAmount - totalAmount,
            quantity: 1,
            amount: receipt.totalAmount - totalAmount,
          ),
        );
      }
    }
    if (receipt.invoiceNumber == null || invDate == null) return null;
    final (sYear, sMonth, sDay) = invDate;
    final (year, month, day) = (
      int.parse(sYear) + (sYear.length == 3 ? 1911 : 0),
      int.parse(sMonth),
      int.parse(sDay),
    );
    final (sHour, sMinute, sSecond) = hourMinuteSecond ?? ('0', '0', '0');
    final (hour, minute, second) = (
      int.parse(sHour),
      int.parse(sMinute),
      int.parse(sSecond),
    );
    final dateTimeAdd8 = DateTime.utc(year, month, day, hour, minute, second);
    final dateTime = dateTimeAdd8.subtract(const Duration(hours: 8));
    if ((
              dateTimeAdd8.year,
              dateTimeAdd8.month,
              dateTimeAdd8.day,
              dateTimeAdd8.hour,
              dateTimeAdd8.minute,
              dateTimeAdd8.second,
            ) !=
            (year, month, day, hour, minute, second) ||
        dateTime.isAfter(now)) {
      return null;
    }
    receipt = receipt.copyWith(issuedAt: dateTime);
    return (receipt, products);
  }
}

class QrCodeProduct {
  final String name;
  final double quantity;
  final double unitPrice;

  const QrCodeProduct({
    required this.name,
    required this.quantity,
    required this.unitPrice,
  });

  Map<String, dynamic> toJson() => {
    'name': name,
    'quantity': quantity,
    'unitPrice': unitPrice,
  };
}

/// 專門給 qrCode 解析發票, 依據 "電子發票證明聯一維及二維條碼規格說明 1.9"
class QrCodeInvoice {
  /// 發票字軌號碼 (10碼)
  final String invoiceNumber;

  /// 發票開立日期 (7碼民國年rrrMMdd)
  final String invoiceDate;

  /// 隨機碼 (4碼)
  final String randomNumber;

  /// 銷售額 (未稅)
  final double salesAmount;

  /// 總計額 (含稅)
  final double totalAmount;

  /// 買方統一編號
  final String buyerId;

  /// 賣方統一編號
  final String sellerId;

  /// 加密驗證資訊 (24碼)
  final String encryptData;

  /// 營業人自行使用區
  final String sellerUseArea;

  /// 二維條碼記載品目筆數
  final int itemCountInQr;

  /// 該張發票交易品目總筆數
  final int totalItemCount;

  /// 品目明細清單
  final List<QrCodeProduct> items;

  /// 補充說明
  final String? sellerNote;

  const QrCodeInvoice({
    required this.invoiceNumber,
    required this.invoiceDate,
    required this.randomNumber,
    required this.salesAmount,
    required this.totalAmount,
    required this.buyerId,
    required this.sellerId,
    required this.encryptData,
    required this.sellerUseArea,
    required this.itemCountInQr,
    required this.totalItemCount,
    required this.items,
    required this.sellerNote,
  });

  Map<String, dynamic> toJson() => {
    'invoiceNumber': invoiceNumber,
    'invoiceDate': invoiceDate,
    'randomNumber': randomNumber,
    'salesAmount': salesAmount,
    'totalAmount': totalAmount,
    'buyerId': buyerId,
    'sellerId': sellerId,
    'encryptData': encryptData,
    'sellerUseArea': sellerUseArea,
    'itemCountInQr': itemCountInQr,
    'totalItemCount': totalItemCount,
    'items': items,
    'sellerNote': sellerNote,
  };

  /// 主解析方法：傳入 QR Code 的 Uint8List
  factory QrCodeInvoice.parse(Uint8List bytes) {
    if (bytes.length < 77) {
      throw FormatException('發票資料長度不足 77 Bytes，格式不正確');
    }
    final headerAscii = ascii.decode(bytes.sublist(0, 77));
    final invoiceNumber = headerAscii.substring(0, 10);
    final invoiceDate = headerAscii.substring(10, 17);
    final randomNumber = headerAscii.substring(17, 21);
    final hexSalesAmt = headerAscii.substring(21, 29);
    final hexTotalAmt = headerAscii.substring(29, 37);
    final buyerId = headerAscii.substring(37, 45);
    final sellerId = headerAscii.substring(45, 53);
    final encryptData = headerAscii.substring(53, 77);

    // 切割 77 Bytes 之後的動態欄位
    final remainingBytes = bytes.sublist(77);
    final byteParts = _splitBytes(remainingBytes, _colon);

    // 第一個 element 因為前綴就是 ":"，所以會是空的，跳過它
    int bytePtr = byteParts.isNotEmpty && byteParts[0].isEmpty ? 1 : 0;
    bool inByteParts() => bytePtr < byteParts.length;
    // 提取第 9, 10, 11 欄位
    final sellerUseArea = inByteParts()
        ? ascii.decode(byteParts[bytePtr++])
        : '**********';
    final itemCountInQr = inByteParts()
        ? int.parse(ascii.decode(byteParts[bytePtr++]))
        : 0;
    final totalItemCount = inByteParts()
        ? int.parse(ascii.decode(byteParts[bytePtr++]))
        : 0;

    // 第 12 欄位：中文編碼參數 ('0': Big5, '1': UTF-8, '2': Base64, '3': UTF-8 (境外電商))
    final encodingParam = inByteParts()
        ? ascii.decode(byteParts[bytePtr++])
        : '1';

    // 計算銷售額與總金額
    late final double salesAmount;
    late final double totalAmount;
    if (encodingParam == '3') {
      // 【境外電商規格】 Header 額度為 00000000，金額存放於第 13, 14 欄位
      final foreignSalesHex = inByteParts()
          ? ascii.decode(byteParts[bytePtr++])
          : '0000000000';
      final foreignTotalHex = inByteParts()
          ? ascii.decode(byteParts[bytePtr++])
          : '0000000000';
      salesAmount = _parseForeignHexAmount(foreignSalesHex);
      totalAmount = _parseForeignHexAmount(foreignTotalHex);
    } else {
      salesAmount = int.parse(hexSalesAmt, radix: 16).toDouble();
      totalAmount = int.parse(hexTotalAmt, radix: 16).toDouble();
    }

    int offset = 0;
    for (int i = 0; i < bytePtr; i += 1) {
      offset += byteParts[i].length + 1;
    }
    final extendBytes = offset > remainingBytes.length
        ? Uint8List(0)
        : remainingBytes.sublist(offset);
    final extend = _decodeString(extendBytes, encodingParam);
    final extendParts = extend.split(':');
    int extendPtr = 0;

    // 解析商品明細清單
    final items = <QrCodeProduct>[];
    for (int i = 0; i < itemCountInQr; i += 1) {
      if (extendPtr + 2 < extendParts.length) {
        items.add(
          QrCodeProduct(
            name: extendParts[extendPtr++],
            quantity: double.parse(extendParts[extendPtr++]),
            unitPrice: double.parse(extendParts[extendPtr++]),
          ),
        );
      }
    }

    // 解析補充說明 (若讀取完品目後還有剩餘欄位)
    String? sellerNote;
    if (extendPtr < extendParts.length) {
      sellerNote = Utils.noEmptyStr(extendParts.sublist(extendPtr).join(':'));
      extendPtr = extendParts.length;
    }

    return QrCodeInvoice(
      invoiceNumber: invoiceNumber,
      invoiceDate: invoiceDate,
      randomNumber: randomNumber,
      salesAmount: salesAmount,
      totalAmount: totalAmount,
      buyerId: buyerId,
      sellerId: sellerId,
      encryptData: encryptData,
      sellerUseArea: sellerUseArea,
      itemCountInQr: itemCountInQr,
      totalItemCount: totalItemCount,
      items: items,
      sellerNote: sellerNote,
    );
  }

  /// 輔助方法：依據 byte 分隔符號拆分 Uint8List
  static List<Uint8List> _splitBytes(Uint8List bytes, int separator) {
    final parts = <Uint8List>[];
    int start = 0;
    for (int i = 0; i < bytes.length; i += 1) {
      if (bytes[i] == separator) {
        parts.add(bytes.sublist(start, i));
        start = i + 1;
      }
    }
    if (start <= bytes.length) {
      parts.add(bytes.sublist(start));
    }
    return parts;
  }

  /// 輔助方法：根據中文編碼參數解碼位元組
  static String _decodeString(List<int> bytes, String encodingParam) {
    if (bytes.isEmpty) return '';
    switch (encodingParam) {
      case '0':
        return big5.decoder.convert(bytes);
      case '2':
        final base64Str = ascii.decode(bytes);
        final decodedBytes = base64.decode(base64Str);
        return utf8.decode(decodedBytes, allowMalformed: true);
      case '1':
      case '3':
      default:
        return utf8.decode(bytes, allowMalformed: true);
    }
  }

  /// 輔助方法：解析境外電商 10 碼 Hex 金額 (前8碼整數，後2碼小數)
  static double _parseForeignHexAmount(String hex10) {
    final intHex = hex10.substring(0, 8);
    final decHex = hex10.substring(8, 10);
    final intVal = int.parse(intHex, radix: 16);
    final decVal = int.parse(decHex, radix: 16);
    return intVal + (decVal / 100.0);
  }
}
