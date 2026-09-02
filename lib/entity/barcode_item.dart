import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/entity/barcode_format.dart';
import 'package:receipt_fold/locale/app_language.dart';

class MobileBarcodeItem {
  final String code;
  final String? name;

  const MobileBarcodeItem({required this.code, this.name});

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': ?Utils.noEmptyStr(name),
  };

  factory MobileBarcodeItem.fromString(String jsonString) {
    String? code;
    String? name;
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      code = json['code'];
      name = Utils.noEmptyStr(json['name']);
    } catch (e) {
      debugPrint('$MobileBarcodeItem.fromString: $e');
    }
    return MobileBarcodeItem(code: code ?? StaticString.nullString, name: name);
  }
}

class MemberBarcodeItem {
  final String code;
  final String? name;
  final String? imageUrl;
  final BarcodeFormat format;

  const MemberBarcodeItem({
    required this.code,
    this.name,
    this.imageUrl,
    this.format = BarcodeFormat.code128,
  });

  Map<String, dynamic> toJson() => {
    'code': code,
    'name': ?Utils.noEmptyStr(name),
    'imageUrl': ?Utils.noEmptyStr(imageUrl),
    'format': format,
  };

  factory MemberBarcodeItem.fromString(String jsonString) {
    String? code;
    String? name;
    String? imageUrl;
    BarcodeFormat? format;
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      code = json['code'];
      name = Utils.noEmptyStr(json['name']);
      imageUrl = Utils.noEmptyStr(json['imageUrl']);
      format = BarcodeFormat.values.fromName(json['format']);
    } catch (e) {
      debugPrint('$MemberBarcodeItem.fromString: $e');
    }
    return MemberBarcodeItem(
      code: code ?? StaticString.nullString,
      name: name,
      imageUrl: imageUrl,
      format: format ?? BarcodeFormat.code128,
    );
  }
}
