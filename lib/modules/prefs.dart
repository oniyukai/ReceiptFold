import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipt_fold/common/app_theme.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/locale/app_localizations.dart';
import 'package:receipt_fold/pages/menu_settings/page_platform_form.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _PrefDef<RUN extends Object, STO extends Object> {
  final RUN defaultValue;
  late final STO Function(Object fromRUN) toSTO;
  late final RUN Function(Object fromSTO) toRUN;

  Type get typeRUN => RUN;
  Type get typeSTO => STO;

  _PrefDef(
    this.defaultValue, [
    STO Function(RUN fromRUN)? toSTO_,
    RUN? Function(STO fromSTO)? toRUN_,])
  {
    assert(const {bool, int, double, String, List<String>}.contains(STO), 'STO<${STO.runtimeType}> unsupported.');
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

  static _PrefDef<T, T> same<T extends Object>(T defaultValue) => _PrefDef<T, T>(defaultValue);
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

  static final Map<PrefsEnum, _PrefDef> _prefDefCache = {};

  _PrefDef get _getPrefDef {
    final cache = _prefDefCache[this];
    if (cache != null) return cache;
    final prefDef = switch (this) {
      isAgreedAllTerms => _PrefDef.same(false),
      invoicePlatformLoginState => _PrefDef<PlatformLoginState, String>(
          PlatformLoginState.notSet,
          (fromRUN) => fromRUN.name,
          (fromSTO) => PlatformLoginState.values.fromName(fromSTO)
      ),
      isAppDeveloperMode => _PrefDef.same(false),
      selectedColor => _PrefDef<ColorOption, String>(
          ColorOption.sys,
          (fromRUN) => fromRUN.name,
          (fromSTO) => ColorOption.values.fromName(fromSTO)
      ),
      selectedTheme => _PrefDef<ThemeOption, String>(
          ThemeOption.sys,
          (fromRUN) => fromRUN.name,
          (fromSTO) => ThemeOption.values.fromName(fromSTO)
      ),
      selectedLanguage => _PrefDef<LocaleOption, String>(
          LocaleOption.sys,
          (fromRUN) => fromRUN.name,
          (fromSTO) => LocaleOption.values.fromName(fromSTO)
      ),
      isAutoBrightness => _PrefDef.same(false),
      isScanScreenRotation => _PrefDef.same(false),
      isShowScreenRotation => _PrefDef.same(false),
    };
    _prefDefCache[this] = prefDef;
    return prefDef;
  }

  T defaultValue<T>() => _getPrefDef.defaultValue as T;

  // /// 不依賴BuildContext, 不建議使用
  // T get<T>() {
  //   final prefDef = _getPrefDef;
  //   final fromSTO = PrefsProvider.instance.get(name);
  //   if (fromSTO.runtimeType == prefDef.typeSTO && fromSTO != null) return prefDef.toRUN(fromSTO) as T;
  //   return prefDef.defaultValue as T;
  // }
}

class PrefsProvider extends ChangeNotifier {
  static late SharedPreferences instance;

  static Future<void> init() async {
    instance = await SharedPreferences.getInstance();
  }

  final Map<PrefsEnum, Object> _prefsMap = {};

  PrefsProvider() {
    for (final PrefsEnum key in PrefsEnum.values) {
      final prefDef = key._getPrefDef;
      final fromSTO = instance.get(key.name);
      if (fromSTO.runtimeType == prefDef.typeSTO && fromSTO != null) _prefsMap[key] = prefDef.toRUN(fromSTO);
    }
  }

  /// 依賴BuildContext
  T get<T>(PrefsEnum key) {
    final prefDef = key._getPrefDef;
    final value = _prefsMap[key] ?? prefDef.defaultValue;
    assert(value.runtimeType == prefDef.typeRUN);
    return value as T;
  }

  Future<void> update(PrefsEnum key, Object value, [bool notify = true]) async {
    final prefDef = key._getPrefDef;
    if (value.runtimeType != prefDef.typeRUN) {
      throw ArgumentError('Error type: value<${value.runtimeType}> != $key<${prefDef.typeRUN}>');
    }
    final fromSTO = prefDef.toSTO(value);
    if (fromSTO is bool) {
      await instance.setBool(key.name, fromSTO);
    } else if (fromSTO is int) {
      await instance.setInt(key.name, fromSTO);
    } else if (fromSTO is double) {
      await instance.setDouble(key.name, fromSTO);
    } else if (fromSTO is String) {
      await instance.setString(key.name, fromSTO);
    } else if (fromSTO is List<String>) {
      await instance.setStringList(key.name, fromSTO);
    } else {
      throw ArgumentError('Unsupported type $key: ${fromSTO.runtimeType}');
    }
    _prefsMap[key] = value;
    if (notify) notifyListeners();
  }

  @override
  String toString() =>
      jsonEncode(_prefsMap.map((key, value) => MapEntry(key.name, key._getPrefDef.toSTO(value))));

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