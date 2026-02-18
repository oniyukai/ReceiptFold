import 'dart:convert';
import 'package:flutter/material.dart' as material;

class SeqConverter<R, S> {
  final S Function(R fromR) toS;
  final R Function(S fromS) toR;

  const SeqConverter({
    required this.toS,
    required this.toR,
  });

  /// 用於資料庫時，僅少量大小的列表才使用，大量請使用標準資料庫方案
  static SeqConverter<List<T>, String> list<T>({
    required T? Function(String jsonString) stringFactory,
    dynamic Function(T item)? itemConverter,})
  {
    return SeqConverter<List<T>, String>(
      toS: (fromRun) => (itemConverter == null)
          ? jsonEncode(fromRun)
          : jsonEncode(fromRun.map(itemConverter)),
      toR: (fromSeq) {
        final List<T> list = [];
        if (fromSeq.isEmpty) return list;
        try {
          final List jsonList = jsonDecode(fromSeq);
          for (final dynamic json in jsonList) {
            final T? item = stringFactory(jsonEncode(json));
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
