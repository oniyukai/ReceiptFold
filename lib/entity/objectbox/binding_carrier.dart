import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:objectbox/objectbox.dart';
import 'package:receipt_fold/common/utils.dart';

@Entity()
class BindingCarrier {
  @Id() int id = 0;
  String cardCode;
  String codeName;
  String carrierId2;
  String carrierName;
  String awardMethod_;
  String claimPrizesMode_;
  String? carrierId1;

  BindingCarrier({
    required this.cardCode,
    required this.codeName,
    required this.carrierId2,
    required this.carrierName,
    required this.awardMethod_,
    required this.claimPrizesMode_,
    this.carrierId1,
  });

  @Transient()
  PrizeRedemptionMode get awardMethod => PrizeRedemptionMode.values.fromName(awardMethod_) ?? PrizeRedemptionMode.unknown;

  @Transient()
  List<PrizeRedemptionMode> get claimPrizesMode {
    final list = <PrizeRedemptionMode>[];
    try {
      final List jsonList = jsonDecode(claimPrizesMode_);
      for (final json in jsonList) {
        final value = PrizeRedemptionMode.values.fromName(jsonEncode(json));
        if (value != null) list.add(value);
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return list;
  }
}


enum PrizeRedemptionMode {
  unknown,
  selfReceive,
  bankTransfer,
  memberReceivel;
}