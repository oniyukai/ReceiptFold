import 'package:barcode/barcode.dart';
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
  codebar,
  itf;

  String toJson() => name;

  Barcode Function() get barcodeFunc => switch (this) {
    qrCode => Barcode.qrCode,
    dataMatrix=> Barcode.dataMatrix,
    aztec => Barcode.aztec,
    pdf417 => Barcode.pdf417,
    ean13 => Barcode.ean13,
    ean8 => Barcode.ean8,
    upcA => Barcode.upcA,
    upcE => Barcode.upcE,
    code128 => Barcode.code128,
    code93 => Barcode.code93,
    code39 => Barcode.code39,
    codebar => Barcode.codabar,
    itf => Barcode.itf,
  };

  String get locale => switch (this) {
    qrCode => AppLocale.barcodeQrCodeLabel.s,
    dataMatrix=> AppLocale.barcodeDataMatrixLabel.s,
    aztec => AppLocale.barcodeAztecLabel.s,
    pdf417 => AppLocale.barcodePdf417Label.s,
    ean13 => AppLocale.barcodeEan13Label.s,
    ean8 => AppLocale.barcodeEan8Label.s,
    upcA => AppLocale.barcodeUpcALabel.s,
    upcE => AppLocale.barcodeUpcELabel.s,
    code128 => AppLocale.barcodeCode128Label.s,
    code93 => AppLocale.barcodeCode93Label.s,
    code39 => AppLocale.barcodeCode39Label.s,
    codebar => AppLocale.barcodeCodabarLabel.s,
    itf => AppLocale.barcodeItfLabel.s,
  };

  String get composition => switch (this) {
    qrCode => AppLocale.barcodeTextCompositionLabel.s,
    dataMatrix => AppLocale.barcodeTextNoSpecialCompositionLabel.s,
    aztec => AppLocale.barcodeTextNoSpecialCompositionLabel.s,
    pdf417 => AppLocale.barcodeTextCompositionLabel.s,
    ean13 => AppLocale.barcode12Digits1CheckCompositionLabel.s,
    ean8 => AppLocale.barcode7Digits1CheckCompositionLabel.s,
    upcA => AppLocale.barcode11Digits1CheckCompositionLabel.s,
    upcE => AppLocale.barcode7Digits1CheckCompositionLabel.s,
    code128 => AppLocale.barcodeTextNoSpecialCompositionLabel.s,
    code93 => AppLocale.barcodeTextUpperNoSpecialCompositionLabel.s,
    code39 => AppLocale.barcodeTextUpperNoSpecialCompositionLabel.s,
    codebar => AppLocale.barcodeDigitsCompositionLabel.s,
    itf => AppLocale.barcodeEvenDigitsCompositionLabel.s,
  };
}