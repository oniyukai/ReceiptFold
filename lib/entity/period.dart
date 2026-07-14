import 'package:flutter/rendering.dart';
import 'package:intl/intl.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/locale/app_language.dart';

enum _PeriodIterationType { local, inv }

/// 必須要同一個實例中能夠接受同一時刻雙期別制度下可能不同的結果
class Period {
  final _PeriodIterationType? _iterationType;
  late final DateTime _localTime;

  Period._iteration(DateTime dateTime, this._iterationType) {
    _localTime = dateTime.toLocal();
  }

  Period(DateTime dateTime) : _iterationType = null {
    _localTime = dateTime.toLocal();
  }

  Period.inv(String invQuery) : _iterationType = .inv {
    int? year;
    int? month;
    try {
      year = int.parse(invQuery.substring(0, 3));
      month = int.parse(invQuery.substring(3, 5));
    } catch (e) {
      debugPrint('$Period.inv: $e');
    }
    _localTime = DateTime.utc((year ?? 0) + 1911, month ?? 1, 1, 8);
  }

  /// 獲取該期别的開始日期 (該月1日)
  DateTime get start {
    assert(_iterationType != .inv);
    return DateTime(
      _localTime.year,
      _localTime.month % 2 + _localTime.month - 1,
      1,
    );
  }

  /// 獲取該期别的結束日期 (下兩個月的前一天，並包含當天所有時間)
  DateTime get end {
    assert(_iterationType != .inv);
    return DateTime(
      _localTime.year,
      _localTime.month % 2 + _localTime.month + 1,
      0,
      23,
      59,
      59,
      999,
    );
  }

  /// 當地年雙月描述, 如 "2025年 7月, 8月"
  String get localString {
    assert(_iterationType != .inv);
    final DateFormat yearFormatter = DateFormat.y(DictKey.languageTag);
    final String yearPart = yearFormatter.format(start);
    final String month1Name = UnitUtils.singleMonthText(start);
    final String month2Name = UnitUtils.singleMonthText(end);
    return '$yearPart $month1Name, $month2Name';
  }

  /// 獲取下一期
  Period get next {
    assert(_iterationType != .inv);
    return Period._iteration(end.add(const Duration(days: 1)), .local);
  }

  /// 獲取上一期
  Period get previous {
    assert(_iterationType != .inv);
    return Period._iteration(start.subtract(const Duration(days: 1)), .local);
  }

  /// 獲取該期别的台北時間開始日期 (該月1日)
  DateTime get invStart {
    assert(_iterationType != .local);
    final DateTime taipeiTime = _localTime.toUtc().add(
      const Duration(hours: 8),
    );
    return DateTime.utc(
      taipeiTime.year,
      taipeiTime.month % 2 + taipeiTime.month - 1,
      1,
      8,
    );
  }

  /// 獲取基於台北時間的上一期，不建議與本地時間混用
  Period get invPrevious {
    assert(_iterationType != .local);
    return Period._iteration(invStart.subtract(const Duration(days: 1)), .inv);
  }

  /// 台北時間民國年雙月描述, 如 "113-05/06"
  String get invString {
    assert(_iterationType != .local);
    final DateTime startTime = invStart;
    final String startMonth = startTime.month.toString().padLeft(2, '0');
    final String endMonth = (startTime.month + 1).toString().padLeft(2, '0');
    return '${startTime.year - 1911}-$startMonth/$endMonth';
  }

  /// 台北時間民國年雙月描述, 如 "11305"
  String get invQuery {
    assert(_iterationType != .local);
    final DateTime startTime = invStart;
    return '${(startTime.year - 1911).toString().padLeft(3, '0')}${startTime.month.toString().padLeft(2, '0')}';
  }
}
