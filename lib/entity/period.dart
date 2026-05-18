import 'package:intl/intl.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/locale/app_language.dart';

/// 必須要同一個實例中能夠接受同一時刻雙期別制度下可能不同的結果
class Period {
  late final DateTime _localTime;

  Period(DateTime dateTime) {
    _localTime = dateTime.toLocal();
  }

  /// 獲取該期别的開始日期 (該月1日)
  DateTime get start => DateTime(_localTime.year, _localTime.month % 2 + _localTime.month - 1, 1);

  /// 獲取該期别的結束日期 (下兩個月的前一天，並包含當天所有時間)
  DateTime get end => DateTime(_localTime.year, _localTime.month % 2 + _localTime.month + 1, 0, 23, 59, 59, 999);

  /// 台北時間民國年雙月描述, 如 "113-05/06"
  String get invString {
    final DateTime taipeiTime = _localTime.toUtc().add(const Duration(hours: 8));
    final String startMonth = (taipeiTime.month % 2 + taipeiTime.month - 1).toString().padLeft(2, '0');
    final String endMonth = (taipeiTime.month % 2 + taipeiTime.month).toString().padLeft(2, '0');
    return '${taipeiTime.year -1911}-$startMonth/$endMonth';
  }

  /// 台北時間民國年雙月描述, 如 "11305"
  String get invQuery {
    final DateTime taipeiTime = _localTime.toUtc().add(const Duration(hours: 8));
    final String startMonth = (taipeiTime.month % 2 + taipeiTime.month - 1).toString().padLeft(2, '0');
    return '${(taipeiTime.year - 1911).toString().padLeft(3, '0')}$startMonth';
  }

  /// 當地年雙月描述, 如 "2025年 7月, 8月"
  String get localString {
    final DateFormat yearFormatter = DateFormat.y(DictKey.languageTag);
    final String yearPart = yearFormatter.format(start);
    final String month1Name = UnitUtils.singleMonthText(start);
    final String month2Name = UnitUtils.singleMonthText(end);
    return '$yearPart $month1Name, $month2Name';
  }

  /// 獲取下一期
  Period get next => Period(end.add(const Duration(days: 1)));

  /// 獲取上一期
  Period get previous => Period(start.subtract(const Duration(days: 1)));
}
