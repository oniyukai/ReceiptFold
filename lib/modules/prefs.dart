import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipt_fold/common/app_theme.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/locale/app_localizations.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrefDef<RUN extends Object, STO extends Object> {
  final ValueGetter<RUN> _defaultValue;
  late final STO Function(RUN fromRUN) _toSTO;
  late final RUN Function(STO fromSTO) _toRUN;

  RUN get defaultValue => _defaultValue();

  STO toSTO(RUN fromRUN) => _toSTO(fromRUN);
  RUN toRUN(STO fromSTO) => _toRUN(fromSTO);
  bool isRUN(dynamic run) => run is RUN;
  bool isSTO(dynamic sto) => sto is STO;

  PrefDef._(
    ValueGetter<RUN> defaultValue, [
      STO Function(RUN fromRUN)? toSTO,
      RUN? Function(STO fromSTO)? toRUN,])
    : _defaultValue = defaultValue {
    assert(const [bool, int, double, String, List<String>].contains(STO), 'STO<${STO.runtimeType}> unsupported.');
    assert(RUN == STO || toSTO != null && toRUN != null, 'When <$RUN>!=<$STO>: toSTO_ & toRUN_ are required.');
    _toSTO = toSTO ?? (fromRUN) => fromRUN as STO;
    _toRUN = toRUN != null
        ? (fromSTO) => toRUN(fromSTO) ?? defaultValue()
        : (fromSTO) => fromSTO as RUN;
  }

  static PrefDef<T, T> _same<T extends Object>(T defaultValue) => PrefDef<T, T>._(() => defaultValue);
}

enum PrefsEnum {
  isAgreedAllTerms,
  isAppDeveloperMode,

  selectedColor,
  selectedTheme,
  selectedLanguage,
  isAutoBrightness,
  isScanScreenRotation,
  isShowScreenRotation,
  isAutoWebDAVSync,

  invoiceQueryMonths,
  ;

  static final _prefDefCache = <PrefsEnum, PrefDef>{};

  PrefDef get _getPrefDef => _prefDefCache.putIfAbsent(this, () {
    final prefDef = switch (this) {
      isAgreedAllTerms => PrefDef._same(false),
      isAppDeveloperMode => PrefDef._same(kDebugMode),
      selectedColor => PrefDef<ColorOption, String>._(
          () => .sys,
          (fromRUN) => fromRUN.name,
          ColorOption.values.fromName,
      ),
      selectedTheme => PrefDef<ThemeOption, String>._(
          () => .sys,
          (fromRUN) => fromRUN.name,
          ThemeOption.values.fromName,
      ),
      selectedLanguage => PrefDef<LocaleOption, String>._(
          () => .sys,
          (fromRUN) => fromRUN.name,
          LocaleOption.values.fromName,
      ),
      isAutoBrightness => PrefDef._same(false),
      isScanScreenRotation => PrefDef._same(false),
      isShowScreenRotation => PrefDef._same(false),
      isAutoWebDAVSync => PrefDef._same(false),
      invoiceQueryMonths => PrefDef._same(2),
    };
    return prefDef;
  });

  T defaultValue<T>() => _getPrefDef.defaultValue as T;

  /// 不依賴BuildContext, 不即時請謹慎使用
  T get<T>() {
    final prefDef = _getPrefDef;
    final fromSTO = PrefsProvider._instance.get(name);
    if (prefDef.isSTO(fromSTO) && fromSTO != null) return prefDef.toRUN(fromSTO) as T;
    return prefDef.defaultValue as T;
  }
}

class OneNotifier<T> extends ChangeNotifier implements ValueListenable<T> {
  T _value;

  OneNotifier(this._value);

  @override
  T get value => _value;

  void _update(T newValue, bool notify) {
    _value = newValue;
    if (notify) notifyListeners();
  }
}

class PrefsProvider extends ChangeNotifier {
  static late final SharedPreferencesWithCache _instance;

  static Future<void> init() async {
    _instance = await SharedPreferencesWithCache.create(
      cacheOptions: SharedPreferencesWithCacheOptions(allowList: PrefsEnum.values.map((e) => e.name).toSet()),
    );
  }

  final _prefsNotifierMap = <PrefsEnum, OneNotifier<Object>>{};

  PrefsProvider() {
    for (final key in PrefsEnum.values) {
      final prefDef = key._getPrefDef;
      final fromSTO = _instance.get(key.name);
      _prefsNotifierMap[key] = prefDef.isSTO(fromSTO) && fromSTO != null
          ? OneNotifier(prefDef.toRUN(fromSTO))
          : OneNotifier(prefDef.defaultValue);
    }
  }

  Listenable listens(Iterable<PrefsEnum> keys) => Listenable.merge(keys.map((e) => _prefsNotifierMap[e]));

  OneNotifier<T> oneNotifier<T>(PrefsEnum key) => _prefsNotifierMap[key] as OneNotifier<T>;

  /// 依賴BuildContext
  T get<T>(PrefsEnum key) {
    final value = _prefsNotifierMap[key]!.value;
    assert(key._getPrefDef.isRUN(value));
    return value as T;
  }

  Future<void> update(PrefsEnum key, Object value, [bool notify = true]) async {
    final fromSTO = key._getPrefDef.toSTO(value);
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
