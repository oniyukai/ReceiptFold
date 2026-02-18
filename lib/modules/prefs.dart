import 'package:flutter/foundation.dart';
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
          PlatformLoginState.values.fromName,
      ),
      isAppDeveloperMode => PrefDef._same(false),
      selectedColor => PrefDef<ColorOption, String>._(
          .sys,
          (fromRUN) => fromRUN.name,
          ColorOption.values.fromName,
      ),
      selectedTheme => PrefDef<ThemeOption, String>._(
          .sys,
          (fromRUN) => fromRUN.name,
          ThemeOption.values.fromName,
      ),
      selectedLanguage => PrefDef<LocaleOption, String>._(
          .sys,
          (fromRUN) => fromRUN.name,
          LocaleOption.values.fromName,
      ),
      isAutoBrightness => PrefDef._same(false),
      isScanScreenRotation => PrefDef._same(false),
      isShowScreenRotation => PrefDef._same(false),
    };
    return prefDef;
  });

  T defaultValue<T>() => _getPrefDef.defaultValue as T;

  /// 不依賴BuildContext, 不即時請謹慎使用
  T get<T>() {
    final PrefDef<Object, Object> prefDef = _getPrefDef;
    final Object? fromSTO = PrefsProvider._instance.get(name);
    if (fromSTO.runtimeType == prefDef.typeSTO && fromSTO != null) return prefDef.toRUN(fromSTO) as T;
    return prefDef.defaultValue as T;
  }
}

class OneNotifier<T> extends ChangeNotifier implements ValueListenable<T> {
  T _value;

  OneNotifier(this._value);

  @override
  T get value => _value;

  void _update(T newValue, [bool notify = true]) {
    if (_value == newValue) return;
    _value = newValue;
    if (notify) notifyListeners();
  }
}

class PrefsProvider extends ChangeNotifier {
  static late final SharedPreferencesWithCache _instance;

  static Future<void> init() async {
    _instance = await SharedPreferencesWithCache.create(
        cacheOptions: .new(allowList: PrefsEnum.values.map((e) => e.name).toSet())
    );
  }

  final Map<PrefsEnum, OneNotifier<Object>> _prefsNotifierMap = {};

  PrefsProvider() {
    for (final PrefsEnum key in PrefsEnum.values) {
      final PrefDef<Object, Object> prefDef = key._getPrefDef;
      final Object? fromSTO = _instance.get(key.name);
      _prefsNotifierMap[key] = fromSTO.runtimeType == prefDef.typeSTO && fromSTO != null
          ? OneNotifier(prefDef.toRUN(fromSTO))
          : OneNotifier(prefDef.defaultValue);
    }
  }

  Listenable listens(Iterable<PrefsEnum> keys) => Listenable.merge(keys.map((e) => _prefsNotifierMap[e]));

  OneNotifier<T> oneNotifier<T extends Object>(PrefsEnum key) => _prefsNotifierMap[key] as OneNotifier<T>;

  /// 依賴BuildContext
  T get<T>(PrefsEnum key) {
    final Object value = _prefsNotifierMap[key]!.value;
    assert(value.runtimeType == key._getPrefDef.typeRUN);
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
    _prefsNotifierMap[key]!._update(value, notify);
    if (notify) notifyListeners();
  }
}

extension Context on BuildContext {
  PrefsProvider get readPrefs => Provider.of<PrefsProvider>(this, listen: false);
  PrefsProvider get watchPrefs => Provider.of<PrefsProvider>(this, listen: true);
}
