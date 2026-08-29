import 'dart:convert';

import 'package:material_ui/material_ui.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/locale/app_language.dart';

enum CarrierStatus {
  platform,
  platformExpired,
  device;

  String get locale => switch (this) {
    platform => DictKey.carrierStatusPlatform,
    platformExpired => DictKey.carrierStatusPlatformExpired,
    device => DictKey.carrierStatusDevice,
  }.s;

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
    'carrierType': ?Utils.noEmptyStr(carrierType),
    'carrierTypeName': ?Utils.noEmptyStr(carrierTypeName),
    'fetchJson': ?Utils.noEmptyStr(fetchJson),
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
      carrierType = Utils.noEmptyStr(json['carrierType']);
      carrierTypeName = Utils.noEmptyStr(json['carrierTypeName']);
      fetchJson = Utils.noEmptyStr(json['fetchJson']);
    } catch (e) {
      debugPrint('$InvoiceCarrier.fromString: $e');
    }
    return InvoiceCarrier(
      carrierId2: carrierId2 ?? StaticString.nullString,
      name: name ?? StaticString.nullString,
      status: status ?? CarrierStatus.device,
      carrierType: carrierType,
      carrierTypeName: carrierTypeName,
      fetchJson: fetchJson,
    );
  }
}
