import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/locale/app_language.dart';

enum CarrierStatus {
  platform,
  platformExpired,
  manual;

  String toJson() => name;
}

class InvoiceCarrier {
  final String carrierId2;
  String name;
  CarrierStatus status;
  String? carrierType;
  String? carrierTypeName;
  String? consolidationJson;

  InvoiceCarrier({
    required this.carrierId2,
    required this.name,
    required this.status,
    this.carrierType,
    this.carrierTypeName,
    this.consolidationJson,
  });

  Map<String, dynamic> toJson() => {
    'carrierId2': carrierId2,
    'name': name,
    'status': status,
    if (carrierType?.isNotEmpty == true) 'carrierType': carrierType,
    if (carrierTypeName?.isNotEmpty == true) 'carrierTypeName': carrierTypeName,
    if (consolidationJson?.isNotEmpty == true) 'consolidationJson': consolidationJson,
  };

  factory InvoiceCarrier.fromString(String jsonString) {
    String? carrierId2;
    String? name;
    CarrierStatus? status;
    String? carrierType;
    String? carrierTypeName;
    String? consolidationJson;
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      carrierId2 = json['carrierId2'];
      name = json['name'];
      status = CarrierStatus.values.fromName(json['status']);
      carrierType = json['carrierType'];
      carrierTypeName = json['carrierTypeName'];
      consolidationJson = json['consolidationJson'];
    } catch (e) {
      debugPrint('$InvoiceCarrier.fromString: $e');
    }
    return InvoiceCarrier(
      carrierId2: carrierId2 ?? StaticString.nullString,
      name: name ?? StaticString.nullString,
      status: status ?? .manual,
      carrierType: carrierType?.isNotEmpty == true ? carrierType : null,
      carrierTypeName: carrierTypeName?.isNotEmpty == true ? carrierTypeName : null,
      consolidationJson: consolidationJson?.isNotEmpty == true ? consolidationJson : null,
    );
  }
}
