import 'dart:convert';

import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:material_ui/material_ui.dart';
import 'package:receipt_fold/entity/barcode_format.dart';
import 'package:receipt_fold/locale/app_language.dart';

class BarcodeField extends StatelessWidget {
  final BarcodeFormat? format;
  final String name;
  final String? initialValue;

  const BarcodeField({
    super.key,
    required this.format,
    required this.name,
    this.initialValue,
  });

  @override
  Widget build(BuildContext context) {
    final int? maxLines =
        const <BarcodeFormat?>[
          .qrCode,
          .dataMatrix,
          .aztec,
          .pdf417,
          .code128,
          null,
        ].contains(format)
        ? null
        : 1;
    final bool isNumbers = const <BarcodeFormat>[
      .ean13,
      .ean8,
      .upcA,
      .upcE,
      .itf,
    ].contains(format);
    return FormBuilderTextField(
      name: name,
      keyboardType: isNumbers ? TextInputType.number : TextInputType.text,
      autovalidateMode: AutovalidateMode.onUserInteraction,
      maxLines: maxLines,
      initialValue: initialValue,
      decoration: InputDecoration(
        prefixIcon: Icon(isNumbers ? Icons.pin_outlined : Icons.format_size),
        labelText: format?.composition ?? DictKey.barcodeCompositionText.s,
        errorMaxLines: 8,
      ),
      validator: (value) => barcodeValidator(value, format),
    );
  }
}

final RegExp _onlyNumbersRegex = RegExp(r'^[0-9]+$');
final RegExp _code128Regex = RegExp(r'^[\x00-\x7F]+$');

String? barcodeValidator(String? value, BarcodeFormat? format) {
  if (format == null) {
    return null;
  } else if (value == null || value.trim().isEmpty) {
    return DictKey.barcodeErrorEmptyFields.s;
  }

  bool notYetVerified = true;
  late final onlyNumbers = FormBuilderValidators.match(
    _onlyNumbersRegex,
    errorText: DictKey.barcodeErrorNotNumber.s,
  );
  String? validator(bool passConditions, String? errorText) =>
      passConditions ? null : errorText;
  String? hardLength(int length) => validator(
    value.length == length,
    '${DictKey.barcodeErrorWrongLength.s}== $length',
  );
  String? maxLength(int length) => validator(
    value.length <= length,
    '${DictKey.barcodeErrorWrongLength.s}<= $length',
  );
  String? maxByteLength(int length) => validator(
    utf8.encode(value).length <= length,
    '${DictKey.barcodeErrorWrongLength.s}<= $length (Bytes)',
  );
  String? tryVerify([String? errorText]) {
    notYetVerified = false;
    try {
      format.barcodeFunc().verify(value);
    } catch (e) {
      return errorText ?? e.toString();
    }
    return null;
  }

  String? tryCheckDigit() {
    String? errorText = tryVerify();
    final String valueNoCheck = value.substring(0, value.length - 1);
    for (int i = 0; i < 10 && errorText != null; i += 1) {
      if (format.barcodeFunc().isValid('$valueNoCheck$i')) {
        errorText = '${DictKey.barcodeErrorWrongCheckDigit.s}$i';
        break;
      }
    }
    return errorText;
  }

  final List<FormFieldValidator<String>> validators = switch (format) {
    .qrCode => [(_) => maxByteLength(2953)],
    .dataMatrix => [
      (_) => maxByteLength(1556),
      (_) => tryVerify(DictKey.barcodeErrorUnsupportedCharsIso88591.s),
    ],
    .aztec => [
      (_) => maxByteLength(1914),
      (_) => tryVerify(DictKey.barcodeErrorUnsupportedCharsIso88591.s),
    ],
    .pdf417 => [(_) => maxByteLength(1108)],
    .ean13 => [onlyNumbers, (_) => hardLength(13), (_) => tryCheckDigit()],
    .ean8 => [onlyNumbers, (_) => hardLength(8), (_) => tryCheckDigit()],
    .upcA => [onlyNumbers, (_) => hardLength(12), (_) => tryCheckDigit()],
    .upcE => [
      onlyNumbers,
      FormBuilderValidators.startsWith(
        '0',
        errorText: DictKey.barcodeErrorUpcEStartZero.s,
      ),
      (_) => hardLength(8),
      (_) => tryCheckDigit(),
    ],
    .code128 => [
      (_) => maxLength(2046),
      (_) => tryVerify(DictKey.barcodeErrorUnsupportedCharsAscii.s),
      FormBuilderValidators.match(
        _code128Regex,
        errorText: DictKey.barcodeErrorUnsupportedCharsAscii.s,
      ),
    ],
    .code93 => [
      (_) => maxLength(47),
      (_) => tryVerify(DictKey.barcodeErrorRegexCode93.s),
    ],
    .code39 => [
      (_) => maxLength(43),
      (_) => tryVerify(DictKey.barcodeErrorRegexCode39.s),
    ],
    .codabar => [
      (_) => maxLength(40),
      (_) => tryVerify(DictKey.barcodeErrorRegexCodabar.s),
    ],
    .itf => [
      onlyNumbers,
      (_) => validator(
        (value.length % 2) == 0,
        DictKey.barcodeErrorItfEvenLength.s,
      ),
      (_) => maxLength(40),
    ],
  };
  final String? validatorMsg = FormBuilderValidators.compose(validators)(value);
  return validatorMsg ?? (notYetVerified ? tryVerify(value) : null);
}
