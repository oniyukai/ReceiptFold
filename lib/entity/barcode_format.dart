import 'package:barcode/barcode.dart';
import 'package:flutter/material.dart';
import 'package:receipt_fold/locale/app_language.dart';

enum BarcodeFormat {
  qrCode,
  dataMatrix,
  aztec,
  pdf417,
  ean13,
  ean8,
  upcA,
  upcE,
  code128,
  code93,
  code39,
  codabar,
  itf;

  String toJson() => name;

  ValueGetter<Barcode> get barcodeFunc => switch (this) {
    qrCode => Barcode.qrCode,
    dataMatrix => Barcode.dataMatrix,
    aztec => Barcode.aztec,
    pdf417 => Barcode.pdf417,
    ean13 => Barcode.ean13,
    ean8 => Barcode.ean8,
    upcA => Barcode.upcA,
    upcE => Barcode.upcE,
    code128 => Barcode.code128,
    code93 => Barcode.code93,
    code39 => Barcode.code39,
    codabar => Barcode.codabar,
    itf => Barcode.itf,
  };

  String get locale => switch (this) {
    qrCode => DictKey.barcodeFormatQrCode,
    dataMatrix => DictKey.barcodeFormatDataMatrix,
    aztec => DictKey.barcodeFormatAztec,
    pdf417 => DictKey.barcodeFormatPdf417,
    ean13 => DictKey.barcodeFormatEan13,
    ean8 => DictKey.barcodeFormatEan8,
    upcA => DictKey.barcodeFormatUpcA,
    upcE => DictKey.barcodeFormatUpcE,
    code128 => DictKey.barcodeFormatCode128,
    code93 => DictKey.barcodeFormatCode93,
    code39 => DictKey.barcodeFormatCode39,
    codabar => DictKey.barcodeFormatCodabar,
    itf => DictKey.barcodeFormatItf,
  }.s;

  String get composition => switch (this) {
    qrCode => DictKey.barcodeCompositionText,
    dataMatrix => DictKey.barcodeCompositionTextSimple,
    aztec => DictKey.barcodeCompositionTextSimple,
    pdf417 => DictKey.barcodeCompositionText,
    ean13 => DictKey.barcodeComposition12Digits1Check,
    ean8 => DictKey.barcodeComposition7Digits1Check,
    upcA => DictKey.barcodeComposition11Digits1Check,
    upcE => DictKey.barcodeComposition7Digits1Check,
    code128 => DictKey.barcodeCompositionTextSimple,
    code93 => DictKey.barcodeCompositionTextUpperSimple,
    code39 => DictKey.barcodeCompositionTextUpperSimple,
    codabar => DictKey.barcodeCompositionDigits,
    itf => DictKey.barcodeCompositionEvenLengthNumbers,
  }.s;
}
