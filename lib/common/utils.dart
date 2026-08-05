import 'dart:core';
import 'dart:io';
import 'dart:math';

import 'package:audioplayers/audioplayers.dart';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:intl/intl.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/pages/widget/overlay_show.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:vibration/vibration.dart';

extension EnumFromName<T extends Enum> on Iterable<T> {
  T? fromName(String? n) => firstWhereOrNull((value) => value.name == n);
}

abstract final class UnitUtils {
  static int get nowUnixTime => DateTime.now().millisecondsSinceEpoch;

  static String get unixRadix36 => nowUnixTime.toRadixString(36);

  /// 顯示當地單月表示, 如 "7月"
  static String singleMonthText(DateTime dateTime) =>
      DateFormat.MMM(DictKey.languageTag).format(dateTime);

  /// 顯示當地完整時間, 如 "2025年7月3日星期四 16:04"
  static String fullTimeText(DateTime dateTime) =>
      DateFormat.yMMMMEEEEd(DictKey.languageTag).add_jm().format(dateTime);

  static String singleTimeText(DateTime dateTime) =>
      DateFormat('yyyy-MM-dd HH:mm:ss').format(dateTime.toLocal());

  static String shortBytesText(int bytes, {int decimals = 2}) {
    if (bytes <= 0) return '0B';
    const suffixes = <String>[
      'B',
      'KB',
      'MB',
      'GB',
      'TB',
      'PB',
      'EB',
      'ZB',
      'YB',
    ];
    final int i = (log(bytes) / log(1024)).floor();
    return '${(bytes / pow(1024, i)).toStringAsFixed(decimals)} ${suffixes[i]}';
  }

  /// 將數字修飾, 如果有小數會才顯示小數後，正數每3位數一個","隔開
  static String amountText(num amount) =>
      NumberFormat.decimalPattern().format(amount);
}

abstract final class Utils {
  /// true:為直屏狀態 false:為橫屏狀態
  static bool isPortrait(BuildContext context) =>
      MediaQuery.of(context).orientation == Orientation.portrait;

  /// 一個簡易的Toast訊息提示
  static Future<void> showToast(String msg, [bool longTime = false]) =>
      Platform.isAndroid || Platform.isIOS
      ? Fluttertoast.showToast(
          msg: msg,
          toastLength: longTime ? Toast.LENGTH_LONG : Toast.LENGTH_SHORT,
          timeInSecForIosWeb: longTime ? 4 : 2,
        )
      : OverlayShow.toast(Text(msg), seconds: longTime ? 4 : 2);

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

  /// 嗶的一聲
  static Future<void> audioPlayBeep(AudioPlayer audioPlayer) async {
    try {
      await audioPlayer.play(AssetSource('short_beep_tone.mp3'));
    } catch (e) {
      await showToast(e.toString());
    }
  }

  /// 在預設瀏覽器開啟網站
  static Future<void> openUrlInBrowser(String url) async {
    final Uri uri = Uri.parse(url);
    if (!await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      showToast('${DictKey.toastCouldNotLaunch.s}: $url');
    }
  }

  /// 鎖定螢幕轉向
  static Future<void> lockOrientation({
    DeviceOrientation? orientation,
    BuildContext? context,
  }) async {
    if (orientation != null) {
      await SystemChrome.setPreferredOrientations([orientation]);
    } else if (context != null) {
      if (isPortrait(context)) {
        await SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);
      } else {
        await SystemChrome.setPreferredOrientations(const [
          DeviceOrientation.landscapeLeft,
          DeviceOrientation.landscapeRight,
        ]);
      }
    }
  }

  /// 恢復允許螢幕所有旋轉方向
  static Future<void> unlockOrientation() =>
      SystemChrome.setPreferredOrientations(const [
        DeviceOrientation.portraitUp,
        DeviceOrientation.portraitDown,
        DeviceOrientation.landscapeLeft,
        DeviceOrientation.landscapeRight,
      ]);

  /// 方便多重目標替換字串
  static String multilingualFiller(
    String string,
    List<(String, String)> targets,
  ) {
    for (final target in targets) {
      string = string.replaceAll(target.$1, target.$2);
    }
    return string;
  }

  /// 統一個給 [String] 用的複製
  static Future<void> copyText(String? text) async {
    if (text == null || text.isEmpty) {
      showToast(DictKey.toastNoContentCopy.s);
    } else {
      await Clipboard.setData(ClipboardData(text: text));
      showToast('${DictKey.toastCopied.s}\n${text.replaceAll('\n', ' ')}');
    }
  }

  /// 如果 [String.isNotEmpty] 回傳 null
  static String? noEmptyStr(String? s) =>
      s?.trim().isNotEmpty == true ? s : null;
}
