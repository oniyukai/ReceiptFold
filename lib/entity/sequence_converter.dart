import 'dart:convert';
import 'package:flutter/material.dart' as material;

class SeqConverter<RUN, SEQ> {
  final SEQ Function(RUN fromRun) toSeq;
  final RUN Function(SEQ fromSeq) toRun;

  const SeqConverter({
    required this.toSeq,
    required this.toRun,
  });

  /// 用於資料庫時，僅少量大小的列表才使用，大量請使用標準資料庫方案
  static SeqConverter<List<T>, String> list<T>({
    required T? Function(String jsonString) stringFactory,
    dynamic Function(T item)? itemConverter,})
  {
    return SeqConverter<List<T>, String>(
      toSeq: (fromRun) => (itemConverter == null)
          ? jsonEncode(fromRun)
          : jsonEncode(fromRun.map(itemConverter)),
      toRun: (fromSeq) {
        final list = <T>[];
        if (fromSeq.isEmpty) return list;
        try {
          final List jsonList = jsonDecode(fromSeq);
          for (final json in jsonList) {
            final item = stringFactory(jsonEncode(json));
            if (item != null) list.add(item);
          }
        } catch (e) {
          material.debugPrint('SequenceConverter<$T>: Error parsing "$fromSeq" - $e.');
        }
        return list;
      }
    );
  }
}