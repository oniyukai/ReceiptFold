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
    qrCode => DictKey.barcodeQrCodeLabel,
    dataMatrix => DictKey.barcodeDataMatrixLabel,
    aztec => DictKey.barcodeAztecLabel,
    pdf417 => DictKey.barcodePdf417Label,
    ean13 => DictKey.barcodeEan13Label,
    ean8 => DictKey.barcodeEan8Label,
    upcA => DictKey.barcodeUpcALabel,
    upcE => DictKey.barcodeUpcELabel,
    code128 => DictKey.barcodeCode128Label,
    code93 => DictKey.barcodeCode93Label,
    code39 => DictKey.barcodeCode39Label,
    codabar => DictKey.barcodeCodabarLabel,
    itf => DictKey.barcodeItfLabel,
  }.s;

  String get composition => switch (this) {
    qrCode => DictKey.barcodeTextCompositionLabel,
    dataMatrix => DictKey.barcodeTextNoSpecialCompositionLabel,
    aztec => DictKey.barcodeTextNoSpecialCompositionLabel,
    pdf417 => DictKey.barcodeTextCompositionLabel,
    ean13 => DictKey.barcode12Digits1CheckCompositionLabel,
    ean8 => DictKey.barcode7Digits1CheckCompositionLabel,
    upcA => DictKey.barcode11Digits1CheckCompositionLabel,
    upcE => DictKey.barcode7Digits1CheckCompositionLabel,
    code128 => DictKey.barcodeTextNoSpecialCompositionLabel,
    code93 => DictKey.barcodeTextUpperNoSpecialCompositionLabel,
    code39 => DictKey.barcodeTextUpperNoSpecialCompositionLabel,
    codabar => DictKey.barcodeDigitsCompositionLabel,
    itf => DictKey.barcodeEvenDigitsCompositionLabel,
  }.s;
}
