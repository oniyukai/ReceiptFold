import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/entity/sequence_converter.dart';
import 'package:receipt_fold/locale/app_language.dart';

enum InvoiceEntityPrize {
  special(10000000),
  grand(2000000),
  first(200000),
  second(40000),
  third(10000),
  fourth(4000),
  fifth(1000),
  sixth(200),
  additionalSixth(200);

  final int amount;

  const InvoiceEntityPrize(this.amount);

  String get locale => switch (this) {
    special => AppLocale.prizeSpecialLabel.s,
    grand => AppLocale.prizeGrandLabel.s,
    first => AppLocale.prizeFirstLabel.s,
    second => AppLocale.prizeSecondLabel.s,
    third => AppLocale.prizeThirdLabel.s,
    fourth => AppLocale.prizeFourthLabel.s,
    fifth => AppLocale.prizeFifthLabel.s,
    sixth => AppLocale.prizeSixthLabel.s,
    additionalSixth => AppLocale.prizeAdditionalSixthLabel.s,
  };
}

class InvoiceWinningNumber {
  final String period; // 期數描述，例如：11405
  final int lastWebQueryTime;
  final Map<InvoiceEntityPrize, List<String>>? prizes; // 獎項: 獎號列表

  InvoiceWinningNumber({
    required this.period,
    required this.lastWebQueryTime,
    required this.prizes,
  });

  Map<String, dynamic> toJson() => {
    'period': period,
    'lastWebQueryTime': lastWebQueryTime,
    if (prizes != null) 'prizes': prizes?.map((key, value) => MapEntry(key.name, value)),
  };

  factory InvoiceWinningNumber.fromString(String jsonString) {
    String? period;
    int? lastWebQueryTime;
    Map<InvoiceEntityPrize, List<String>>? prizes;
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      period = json['period'] as String;
      lastWebQueryTime = json['lastWebQueryTime'] as int;
      final jsonPrizes = json['prizes'] as Map<String, dynamic>?;
      if (jsonPrizes != null && jsonPrizes.isNotEmpty) {
        prizes = {};
        for (final entry in jsonPrizes.entries) {
          final invoiceEntityPrize = InvoiceEntityPrize.values.fromName(entry.key);
          if (invoiceEntityPrize != null) {
            prizes[invoiceEntityPrize] = (entry.value as List<dynamic>).cast<String>().toList();
          }
        }
      }
    } catch (e) {
      debugPrint(e.toString());
    }
    return InvoiceWinningNumber(
      period: period ?? StaticString.nullString,
      lastWebQueryTime: lastWebQueryTime ?? 0,
      prizes: prizes,
    );
  }

  static final listConverter = SeqConverter.list<InvoiceWinningNumber>(
    stringFactory: (jsonString) => InvoiceWinningNumber.fromString(jsonString),
  );
}