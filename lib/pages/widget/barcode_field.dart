import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:receipt_fold/entity/barcode_format.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:string_validator/string_validator.dart';
import 'package:barcode/barcode.dart';

class BarcodeField extends StatelessWidget {
  final BarcodeFormat? format;
  final String name;
  final GlobalKey<FormBuilderState> formKey;
  final String? initialValue;

  const BarcodeField({
    super.key,
    required this.format,
    required this.name,
    required this.formKey,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    final isNumbers = format?.isNumbers ?? false;
    return FormBuilderTextField(
      name: name,
      maxLines: _allowLineBreaks,
      initialValue: initialValue,
      decoration: InputDecoration(
        prefixIcon: Icon(isNumbers ? Icons.pin_outlined : Icons.format_size),
        labelText: format?.composition ?? AppLocale.barcodeTextCompositionLabel.s,
        errorMaxLines: 8,
      ),
      keyboardType: isNumbers ? TextInputType.number : TextInputType.text,
      validator: (value) => barcodeValidator(value, format),
      onEditingComplete: () {
        formKey.currentState?.fields[name]?.validate();
      },
    );
  }

  int? get _allowLineBreaks => const <BarcodeFormat>{
    BarcodeFormat.qrCode,
    BarcodeFormat.dataMatrix,
    BarcodeFormat.aztec,
    BarcodeFormat.pdf417,
    BarcodeFormat.code128
  }.contains(format) ? null : 1;
}

extension _BarcodeFormatForValid on BarcodeFormat {
  bool get isNumbers => const <BarcodeFormat>{
    BarcodeFormat.ean13,
    BarcodeFormat.ean8,
    BarcodeFormat.upcA,
    BarcodeFormat.upcE,
    BarcodeFormat.codebar,
    BarcodeFormat.itf
  }.contains(this);

  int? get maxLength => const <BarcodeFormat, int>{
    BarcodeFormat.qrCode: 2953,
    BarcodeFormat.pdf417: 990,
    BarcodeFormat.aztec: 2335,
    BarcodeFormat.dataMatrix: 1559,
    BarcodeFormat.code128: 2046,
    BarcodeFormat.code93: 47,
    BarcodeFormat.code39: 43,
    BarcodeFormat.codebar: 20,
    BarcodeFormat.itf: 20,
  }[this];

  int? get hardLength => const <BarcodeFormat, int>{
    BarcodeFormat.ean13: 13,
    BarcodeFormat.ean8: 8,
    BarcodeFormat.upcA: 12,
    BarcodeFormat.upcE: 8,
  }[this];

  String? get encodingErrorMessage => <BarcodeFormat, String>{
    BarcodeFormat.aztec: AppLocale.errorBarcodeEncodingIso88591ErrorMessage.s,
    BarcodeFormat.dataMatrix: AppLocale.errorBarcodeEncodingIso88591ErrorMessage.s,
    BarcodeFormat.code128: AppLocale.errorBarcodeEncodingUsAsciiErrorMessage.s,
    BarcodeFormat.code93: AppLocale.errorBarcode93RegexErrorMessage.s,
    BarcodeFormat.code39: AppLocale.errorBarcode39RegexErrorMessage.s,
  }[this];

  bool get hasCheckDigit => const <BarcodeFormat>{
    BarcodeFormat.ean13,
    BarcodeFormat.ean8,
    BarcodeFormat.upcA,
    BarcodeFormat.upcE,
  }.contains(this);
}

String? barcodeValidator(String? value, BarcodeFormat? format){

  if (format == null) {
    return null;
  }
  if (value==null || value.replaceAll('\n', '').replaceAll(' ', '').isEmpty) {
    return AppLocale.errorEmptyFields.s;
  }

  final bool isNumbers = format.isNumbers;
  final int? maxLength = format.maxLength;
  final int? hardLength = format.hardLength;
  final String? encodingErrorMessage = format.encodingErrorMessage;
  final barcodeFunc = format.barcodeFunc;

  if (isNumbers && !value.isNumeric) {
    return AppLocale.errorBarcodeNotANumberMessage.s;
  }
  if (format == BarcodeFormat.upcE && value[0] != '0') {
    return AppLocale.errorBarcodeUpcENotStartWith0ErrorMessage.s;
  }
  if (format == BarcodeFormat.itf && (value.length % 2) != 0) {
    return AppLocale.errorBarcodeItfErrorMessage.s;
  }
  if (maxLength != null && value.length > maxLength) {
    return '${AppLocale.errorBarcodeWrongLengthMessage.s}< $maxLength';
  }
  if (hardLength != null && value.length != hardLength) {
    return '${AppLocale.errorBarcodeWrongLengthMessage.s}$hardLength';
  }
  if (encodingErrorMessage != null && !barcodeFunc().isValid(value)) {
    return encodingErrorMessage;
  }
  if (format.hasCheckDigit) {
    final String checkDigit = _trytoFindCheck(value, format.barcodeFunc);
    if (value[value.length - 1] != checkDigit) {
      return '${AppLocale.errorBarcodeWrongKeyMessage.s}$checkDigit';
    }
  }
  if (format == BarcodeFormat.code128 && !value.isAscii) {
    return AppLocale.errorBarcodeEncodingUsAsciiErrorMessage.s;
  }
  return null;
}

String _trytoFindCheck(String value, Barcode Function() codeType) {
  final valueNoCheck = value.substring(0, value.length - 1);
  for (int i=0; i < 10; i++) {
    final bool isValid = codeType().isValid('$valueNoCheck$i');
    if (isValid) return i.toString();
  }
  return value[value.length - 1];
}