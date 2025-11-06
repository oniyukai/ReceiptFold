import 'dart:math';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:vibration/vibration.dart';
import 'dart:core';

extension EnumFromName<T extends Enum> on Iterable<T> {
  T? fromName(String? n) => asNameMap()[n];
}

final class UnitUtils {

  static int get nowUnixTime => DateTime.now().millisecondsSinceEpoch;

  /// 顯示當地單月表示, 如 "7月"
  static String singleMonthText(DateTime dateTime) =>
      DateFormat.MMM(AppLocale.languageTag).format(dateTime);

  /// 顯示當地完整時間, 如 "2025年7月3日星期四 16:04"
  static String fullTimeText(DateTime dateTime) =>
      DateFormat.yMMMMEEEEd(AppLocale.languageTag).add_jm().format(dateTime);

  static String shortBytesText(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return "0B";
    const suffixes = ["B", "KB", "MB", "GB", "TB", "PB", "EB", "ZB", "YB"];
    var i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)}${suffixes[i]}';
  }
}

final class Utils {

  /// true:為直屏狀態 false:為橫屏狀態
  static bool isPortrait(BuildContext context) {
    final orientation = MediaQuery.of(context).orientation;
    return orientation == Orientation.portrait;
  }

  /// 震動一下
  static Future<void> deviceVibrate() async {
    if ( await Vibration.hasVibrator() ) {
      if (await Vibration.hasCustomVibrationsSupport()) {
        Vibration.vibrate(duration: 250);
      } else {
        Vibration.vibrate();
      }
    }
  }

  // /// 嗶的一聲
  // static Future<void> audioPlayBeep(AudioPlayer audioPlayer) async {
  //   try {
  //     audioPlayer.play(AssetSource('short_beep_tone.mp3'));
  //   } catch (e) {
  //     showToast(e.toString());
  //   }
  // }

  ///  一個簡易的Toast訊息提示
  static void showToast(String msg, [bool longTime = false]) {
    Fluttertoast.showToast(
      msg: msg,
      toastLength: longTime ? Toast.LENGTH_LONG : Toast.LENGTH_SHORT,
      timeInSecForIosWeb: longTime ? 4 : 2,
    );
  }

  /// 在預設瀏覽器開啟網站
  static Future<void> openUrlInBrowser(String urlstr) async {
    final Uri url = Uri.parse(urlstr);
    if (!await launchUrl(url, mode: LaunchMode.externalApplication)) {
      showToast('Could not launch $urlstr');
    }
  }
  static void searchInBrowser(String searchUrl, String keyWord) {
    openUrlInBrowser(searchUrl.replaceAll('{code}', Uri.encodeComponent(keyWord)));
  }

  /// 把'Type'名轉成String
  static String typeName(Type type) => type.toString();
  static Map<String, T> typeNameMap<T>(Map<Type, T> map) {
    final Map<String, T> target = <String, T>{};
    map.forEach((key, value) => target[key.toString()] = value);
    return target;
  }

  /// 鎖定螢幕轉向
  static Future<void> lockCurrentOrientation(BuildContext context) async {
    if (isPortrait(context)) {
      await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
      ]);
    } else {
      await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);
    }
  }

  /// 恢復允許螢幕所有旋轉方向
  static Future<void> unlockCurrentOrientation() async {
    await SystemChrome.setPreferredOrientations(const <DeviceOrientation>[
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown, // 考量平板向下也可以
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
  }

  static String multilingualFiller(String string, List<(String, String)> targets) {
    for (final target in targets) {
      string = string.replaceAll(target.$1, target.$2);
    }
    return string;
  }

  /// 將數字修飾, 如果有小數會才顯示小數後，正數每3位數一個","隔開
  static String amountToDescription(num amount) => NumberFormat.decimalPattern().format(amount);
}