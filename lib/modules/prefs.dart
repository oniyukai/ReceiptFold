import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipt_fold/common/app_theme.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/locale/app_localizations.dart';
import 'package:receipt_fold/pages/menu_settings/page_platform_form.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefDef<RUN extends Object, STO extends Object> {
  final RUN defaultValue;
  late final STO Function(Object fromRUN) toSTO;
  late final RUN Function(Object fromSTO) toRUN;

  Type get typeRUN => RUN;
  Type get typeSTO => STO;

  PrefDef._(
    this.defaultValue, [
    STO Function(RUN fromRUN)? toSTO_,
    RUN? Function(STO fromSTO)? toRUN_,])
  {
    assert(const [bool, int, double, String, List<String>].contains(STO), 'STO<${STO.runtimeType}> unsupported.');
    if (RUN == STO) {
      toSTO = toSTO_ != null
          ? (fromRUN) => toSTO_(fromRUN as RUN)
          : (fromRUN) => fromRUN as STO;
      toRUN = toRUN_ != null
          ? (fromSTO) => toRUN_(fromSTO as STO) ?? defaultValue
          : (fromSTO) => fromSTO as RUN;
    } else {
      assert(toSTO_ != null && toRUN_ != null, 'When <$RUN>!=<$STO>: toSTO_ & toRUN_ are required.');
      toSTO = (fromRUN) => toSTO_!(fromRUN as RUN);
      toRUN = (fromSTO) => toRUN_!(fromSTO as STO) ?? defaultValue;
    }
  }

  static PrefDef<T, T> _same<T extends Object>(T defaultValue) => PrefDef<T, T>._(defaultValue);
}

enum PrefsEnum {
  isAgreedAllTerms,
  invoicePlatformLoginState,
  isAppDeveloperMode,

  selectedColor,
  selectedTheme,
  selectedLanguage,
  isAutoBrightness,
  isScanScreenRotation,
  isShowScreenRotation,
  ;

  static final Map<PrefsEnum, PrefDef> _prefDefCache = {};

  PrefDef get _getPrefDef => _prefDefCache.putIfAbsent(this, () {
    final prefDef = switch (this) {
      isAgreedAllTerms => PrefDef._same(false),
      invoicePlatformLoginState => PrefDef<PlatformLoginState, String>._(
          .notSet,
          (fromRUN) => fromRUN.name,
          (fromSTO) => PlatformLoginState.values.fromName(fromSTO)
      ),
      isAppDeveloperMode => PrefDef._same(false),
      selectedColor => PrefDef<ColorOption, String>._(
          .sys,
          (fromRUN) => fromRUN.name,
          (fromSTO) => ColorOption.values.fromName(fromSTO)
      ),
      selectedTheme => PrefDef<ThemeOption, String>._(
          .sys,
          (fromRUN) => fromRUN.name,
          (fromSTO) => ThemeOption.values.fromName(fromSTO)
      ),
      selectedLanguage => PrefDef<LocaleOption, String>._(
          .sys,
          (fromRUN) => fromRUN.name,
          (fromSTO) => LocaleOption.values.fromName(fromSTO)
      ),
      isAutoBrightness => PrefDef._same(false),
      isScanScreenRotation => PrefDef._same(false),
      isShowScreenRotation => PrefDef._same(false),
    };
    return prefDef;
  });

  T defaultValue<T>() => _getPrefDef.defaultValue as T;

  // /// 不依賴BuildContext, 不即時請謹慎使用
  // T get<T>() {
  //   final PrefDef<Object, Object> prefDef = _getPrefDef;
  //   final Object? fromSTO = PrefsProvider._instance.get(name);
  //   if (fromSTO.runtimeType == prefDef.typeSTO && fromSTO != null) return prefDef.toRUN(fromSTO) as T;
  //   return prefDef.defaultValue as T;
  // }
}

class PrefsProvider extends ChangeNotifier {
  static late final SharedPreferences _instance;

  static Future<void> init() async {
    _instance = await SharedPreferences.getInstance();
  }

  final Map<PrefsEnum, Object> _prefsRunsMap = {};

  PrefsProvider() {
    for (final PrefsEnum key in PrefsEnum.values) {
      final PrefDef<Object, Object> prefDef = key._getPrefDef;
      final Object? fromSTO = _instance.get(key.name);
      if (fromSTO.runtimeType == prefDef.typeSTO && fromSTO != null) _prefsRunsMap[key] = prefDef.toRUN(fromSTO);
    }
  }

  /// 依賴BuildContext
  T get<T>(PrefsEnum key) {
    final PrefDef<Object, Object> prefDef = key._getPrefDef;
    final Object value = _prefsRunsMap[key] ?? prefDef.defaultValue;
    assert(value.runtimeType == prefDef.typeRUN);
    return value as T;
  }

  Future<void> update(PrefsEnum key, Object value, [bool notify = true]) async {
    final PrefDef<Object, Object> prefDef = key._getPrefDef;
    if (value.runtimeType != prefDef.typeRUN) {
      throw ArgumentError('Error type: value<${value.runtimeType}> != $key<${prefDef.typeRUN}>');
    }
    final Object fromSTO = prefDef.toSTO(value);
    if (fromSTO is bool) {
      await _instance.setBool(key.name, fromSTO);
    } else if (fromSTO is int) {
      await _instance.setInt(key.name, fromSTO);
    } else if (fromSTO is double) {
      await _instance.setDouble(key.name, fromSTO);
    } else if (fromSTO is String) {
      await _instance.setString(key.name, fromSTO);
    } else if (fromSTO is List<String>) {
      await _instance.setStringList(key.name, fromSTO);
    } else {
      throw ArgumentError('Unsupported type $key: ${fromSTO.runtimeType}');
    }
    _prefsRunsMap[key] = value;
    if (notify) notifyListeners();
  }

  @override
  String toString() =>
      jsonEncode(_prefsRunsMap.map((key, value) => MapEntry(key.name, key._getPrefDef.toSTO(value))));

  Future<void> updateFromDatabase(String jsonString) async {
    try {
      final Map jsonList = jsonDecode(jsonString);
      for (final json in jsonList.entries) {
        final key = PrefsEnum.values.fromName(json.key as String);
        final fromSTO = json.value;
        if (key == null || fromSTO == null) continue;
        try {
          final value = key._getPrefDef.toRUN(fromSTO);
          await update(key, value, false);
        } catch (e) {
          debugPrint(e.toString());
        }
      }
      notifyListeners();
    } catch (e) {
      debugPrint(e.toString());
    }
  }
}

extension Context on BuildContext {
  PrefsProvider get readPrefs => Provider.of<PrefsProvider>(this, listen: false); //same mean: read<PrefsProvider>();
  PrefsProvider get watchPrefs => Provider.of<PrefsProvider>(this, listen: true); //same mean: watch<PrefsProvider>();
}
