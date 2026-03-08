import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/entity/barcode_format.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:receipt_fold/locale/app_language.dart';

class MobileBarcodeItem {
  final String code;
  final String? name;

  const MobileBarcodeItem({
    required this.code,
    this.name,
  });

  Map<String, dynamic> toJson() => {
    'code': code,
    if (name!=null && name!='') 'name': name,
  };

  factory MobileBarcodeItem.fromString(String jsonString) {
    String? code;
    String? name;
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      code = json['code'];
      name = json['name'];
      if (name == '') name = null;
    } catch (e) {
      debugPrint('$MobileBarcodeItem.fromString: $e');
    }
    return MobileBarcodeItem(
      code: code ?? StaticString.nullString,
      name: name,
    );
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
    this.format = .code128,
  });

  Map<String, dynamic> toJson() => {
    'code': code,
    if (name!=null && name!='') 'name': name,
    if (imageUrl!=null && imageUrl!='') 'imageUrl': imageUrl,
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
      name = json['name'];
      if (name == '') name = null;
      imageUrl = json['imageUrl'];
      if (imageUrl == '') imageUrl = null;
      format = BarcodeFormat.values.fromName(json['format']);
    } catch (e) {
      debugPrint('$MemberBarcodeItem.fromString: $e');
    }
    return MemberBarcodeItem(
      code: code ?? StaticString.nullString,
      name: name,
      imageUrl: imageUrl,
      format: format ?? .code128,
    );
  }
}
