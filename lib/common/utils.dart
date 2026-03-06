import 'dart:math';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:vibration/vibration.dart';
import 'package:collection/collection.dart';
import 'dart:core';

extension EnumFromName<T extends Enum> on Iterable<T> {
  T? fromName(String? n) => firstWhereOrNull((value) => value.name == n);
}

final class UnitUtils {
  const UnitUtils._();

  static int get nowUnixTime => DateTime.now().millisecondsSinceEpoch;

  /// 顯示當地單月表示, 如 "7月"
  static String singleMonthText(DateTime dateTime) =>
      DateFormat.MMM(DictKey.languageTag).format(dateTime);

  /// 顯示當地完整時間, 如 "2025年7月3日星期四 16:04"
  static String fullTimeText(DateTime dateTime) =>
      DateFormat.yMMMMEEEEd(DictKey.languageTag).add_jm().format(dateTime);

  static String shortBytesText(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return "0B";
    const List<String> suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    final int i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }
}

final class Utils {
  const Utils._();

  /// true:為直屏狀態 false:為橫屏狀態
  static bool isPortrait(BuildContext context) =>
      MediaQuery.of(context).orientation == .portrait;

  /// 震動一下
  static Future<void> deviceVibrate() async {
    if (await Vibration.hasVibrator()) {
      if (await Vibration.hasCustomVibrationsSupport()) {
        await Vibration.vibrate(duration: 250);
      } else {
        await Vibration.vibrate();
      }
    }
  }

  /// 一個簡易的Toast訊息提示
  static Future<bool?> showToast(String msg, [bool longTime = false]) => Fluttertoast.showToast(
    msg: msg,
    toastLength: longTime ? .LENGTH_LONG : .LENGTH_SHORT,
    timeInSecForIosWeb: longTime ? 4 : 2,
  );

  /// 在預設瀏覽器開啟網站
  static Future<void> openUrlInBrowser(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: .externalApplication)) {
      await showToast('Could not launch $url');
    }
  }

  /// 鎖定螢幕轉向
  static Future<void> lockCurrentOrientation(BuildContext context) {
    if (isPortrait(context)) {
      return SystemChrome.setPreferredOrientations(const [
        .portraitUp,
        .portraitDown,
      ]);
    } else {
      return SystemChrome.setPreferredOrientations(const [
        .landscapeLeft,
        .landscapeRight,
      ]);
    }
  }

  /// 恢復允許螢幕所有旋轉方向
  static Future<void> unlockCurrentOrientation() =>
      SystemChrome.setPreferredOrientations(const [
        .portraitUp,
        .portraitDown,
        .landscapeLeft,
        .landscapeRight,
      ]);

  static String multilingualFiller(String string, List<(String, String)> targets) {
    for (final (String, String) target in targets) {
      string = string.replaceAll(target.$1, target.$2);
    }
    return string;
  }

  /// 將數字修飾, 如果有小數會才顯示小數後，正數每3位數一個","隔開
  static String amountToDescription(num amount) => NumberFormat.decimalPattern().format(amount);
}
