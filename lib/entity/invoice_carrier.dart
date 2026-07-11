import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/locale/app_language.dart';

enum CarrierStatus {
  platform,
  platformExpired,
  manual;

  String get locale => switch (this) {
    CarrierStatus.platform => '雲端',
    CarrierStatus.platformExpired => '雲端離線',
    CarrierStatus.manual => '本地',
  };

  String toJson() => name;
}

class InvoiceCarrier {
  final String carrierId2;
  String name;
  CarrierStatus status;
  String? carrierType;
  String? carrierTypeName;
  String? fetchJson;

  InvoiceCarrier({
    required this.carrierId2,
    required this.name,
    required this.status,
    this.carrierType,
    this.carrierTypeName,
    this.fetchJson,
  });

  Map<String, dynamic> toJson() => {
    'carrierId2': carrierId2,
    'name': name,
    'status': status,
    if (carrierType?.isNotEmpty == true) 'carrierType': carrierType,
    if (carrierTypeName?.isNotEmpty == true) 'carrierTypeName': carrierTypeName,
    if (fetchJson?.isNotEmpty == true) 'fetchJson': fetchJson,
  };

  factory InvoiceCarrier.fromString(String jsonString) {
    String? carrierId2;
    String? name;
    CarrierStatus? status;
    String? carrierType;
    String? carrierTypeName;
    String? fetchJson;
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      carrierId2 = json['carrierId2'];
      name = json['name'];
      status = CarrierStatus.values.fromName(json['status']);
      carrierType = json['carrierType'];
      carrierTypeName = json['carrierTypeName'];
      fetchJson = json['fetchJson'];
    } catch (e) {
      debugPrint('$InvoiceCarrier.fromString: $e');
    }
    return InvoiceCarrier(
      carrierId2: carrierId2 ?? StaticString.nullString,
      name: name ?? StaticString.nullString,
      status: status ?? .manual,
      carrierType: carrierType?.isNotEmpty == true ? carrierType : null,
      carrierTypeName: carrierTypeName?.isNotEmpty == true ? carrierTypeName : null,
      fetchJson: fetchJson?.isNotEmpty == true ? fetchJson : null,
    );
  }
}
