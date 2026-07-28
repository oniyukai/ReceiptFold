import 'dart:convert';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:receipt_fold/entity/drift/key_value_store.dart';
import 'package:receipt_fold/entity/period.dart';
import 'package:receipt_fold/locale/app_language.dart';

class InvoicePrize {
  final int amount;
  final String name;
  final String number;

  InvoicePrize(this.amount, this.name, this.number);

  Map<String, dynamic> toJson() => {
    'amount': amount,
    'name': name,
    'number': number,
  };

  factory InvoicePrize.fromString(String jsonString) {
    int? amount;
    String? name;
    String? number;
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      amount = json['amount'];
      name = json['name'];
      number = json['number'];
    } catch (e) {
      debugPrint('$InvoicePrize.fromString: $e');
    }
    return InvoicePrize(
      amount ?? -1,
      name ?? StaticString.nullString,
      number ?? StaticString.nullString,
    );
  }
}

class InvoicePrizeAward {
  /// 與 [Period.invQuery] 對應
  final String invQuery;
  final int lastWebQueryTime;
  final List<InvoicePrize> prizes;

  InvoicePrizeAward({
    required this.invQuery,
    required this.lastWebQueryTime,
    required this.prizes,
  });

  static final _prizesConverter = KVConverter.listCustom<InvoicePrize>(
    jsonEncode,
    InvoicePrize.fromString,
    const [],
  );

  Map<String, dynamic> toJson() => {
    'invQuery': invQuery,
    'lastWebQueryTime': lastWebQueryTime,
    'prizes': _prizesConverter.toS(prizes)!,
  };

  factory InvoicePrizeAward.fromString(String jsonString) {
    String? invQuery;
    int? lastWebQueryTime;
    List<InvoicePrize>? prizes;
    try {
      final Map<String, dynamic> json = jsonDecode(jsonString);
      invQuery = json['invQuery'];
      lastWebQueryTime = json['lastWebQueryTime'];
      prizes = _prizesConverter.toR(json['prizes']);
    } catch (e) {
      debugPrint('$InvoicePrizeAward.fromString: $e');
    }
    return InvoicePrizeAward(
      invQuery: invQuery ?? StaticString.nullString,
      lastWebQueryTime: lastWebQueryTime ?? -1,
      prizes: [...?prizes],
    );
  }

  Period get period => Period.inv(invQuery);

  InvoicePrize? checkAll(String? number) {
    if (number == null || number.length < 3) return null;
    return prizes.firstWhereOrNull((prize) => number.endsWith(prize.number));
  }

  List<InvoicePrize> checkEnd(String number) => [
    for (final prize in prizes)
      if (prize.number.endsWith(number)) prize,
  ];
}
