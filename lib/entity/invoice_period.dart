import 'package:intl/intl.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/locale/app_language.dart';

class InvoicePeriod {
  final int year; // 西元年
  final int startMonth; // 1, 3, 5, 7, 9, 11

  InvoicePeriod(this.year, this.startMonth) {
    assert(startMonth % 2 != 0 && startMonth >= 1 && startMonth <= 11, 'startMonth 必須是 1 到 11 之間的奇數月份。');
  }

  /// 獲取該期别的開始日期 (該月1日)
  DateTime get startDateTime => DateTime(year, startMonth, 1);

  /// 獲取該期别的結束日期 (下兩個月的前一天，並包含當天所有時間)
  DateTime get endDateTime => DateTime(year, startMonth + 2, 0, 23, 59, 59, 999);

  /// 獲取期别(民國年)，例如 "11305"
  String get getROCPeriod {
    return '${(year-1911).toString().padLeft(3, '0')}${startMonth.toString().padLeft(2, '0')}';
  }

  /// 以當地年雙月表示, 如 "2025年 7月, 8月"
  @override
  String toString() {
    final DateFormat yearFormatter = DateFormat.y(AppLocale.languageTag);
    final String yearPart = yearFormatter.format(startDateTime);
    final String month1Name = UnitUtils.singleMonthText(startDateTime);
    final String month2Name = UnitUtils.singleMonthText(endDateTime);
    return '$yearPart $month1Name, $month2Name';
  }

  /// 根據給定的[unixMilliseconds]，計算它所屬的發票期别
  factory InvoicePeriod.fromUnixTime(int unixMilliseconds) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(unixMilliseconds);
    final month = (dateTime.month%2 == 0) ? dateTime.month-1 : dateTime.month;
    return InvoicePeriod(dateTime.year, month);
  }

  /// 獲取下一期
  InvoicePeriod get next {
    final newStartMonth = startMonth + 2;
    return newStartMonth > 11
        ? InvoicePeriod(year + 1, 1)
        : InvoicePeriod(year, newStartMonth);
  }

  /// 獲取上一期
  InvoicePeriod get previous {
    final newStartMonth = startMonth - 2;
    return newStartMonth < 1
        ? InvoicePeriod(year - 1, 11)
        : InvoicePeriod(year, newStartMonth);
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is InvoicePeriod &&
      runtimeType == other.runtimeType &&
      year == other.year &&
      startMonth == other.startMonth;

  @override
  int get hashCode => year.hashCode ^ startMonth.hashCode;
}