import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/entity/barcode_format.dart';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:receipt_fold/entity/sequence_converter.dart';
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
      code = json['code'] as String;
      name = json['name'] as String?;
      if (name == '') name = null;
    } catch (e) {
      debugPrint(e.toString());
    }
    return MobileBarcodeItem(
      code: code ?? StaticString.nullString,
      name: name,
    );
  }

  static final listConverter = SeqConverter.list<MobileBarcodeItem>(
    stringFactory: (jsonString) => MobileBarcodeItem.fromString(jsonString),
  );
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
      code = json['code'] as String;
      name = json['name'] as String?;
      imageUrl = json['imageUrl'] as String?;
      format = BarcodeFormat.values.fromName(json['format'] as String?);
      if (name == '') name = null;
      if (imageUrl == '') imageUrl = null;
    } catch (e) {
      debugPrint(e.toString());
    }
    return MemberBarcodeItem(
      code: code ?? StaticString.nullString,
      name: name,
      imageUrl: imageUrl,
      format: format ?? BarcodeFormat.code128,
    );
  }

  static final listConverter = SeqConverter.list<MemberBarcodeItem>(
    stringFactory: (jsonString) => MemberBarcodeItem.fromString(jsonString),
  );
}
