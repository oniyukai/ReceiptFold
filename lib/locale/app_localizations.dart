import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/locale/map_en.dart';
import 'package:receipt_fold/locale/map_ja.dart';
import 'package:receipt_fold/locale/map_zh_hans.dart';
import 'package:receipt_fold/locale/map_zh_hant.dart';

class AppLocalizationsDelegate extends LocalizationsDelegate<LocaleInstance> {
  const AppLocalizationsDelegate();

  @override
  bool isSupported(Locale locale) => const <String>{'en', 'ja', 'zh'}.contains(locale.languageCode);

  @override
  Future<LocaleInstance> load(Locale locale) async {
    final List<LocaleInstance> mapList = switch (locale.languageCode) {
      'en' => LocaleOption.en,
      'ja' => LocaleOption.ja,
      'zh' => locale.scriptCode == 'Hans' ? LocaleOption.zhHans : LocaleOption.zhHant,
      _ => LocaleOption.zhHant,
    }.mapList!;
    final LocaleInstance mergedMap = {};
    for (final enumValue in AppLocale.values) {
      for (final map in mapList) {
        final value = map[enumValue];
        if (value != null) {
          mergedMap[enumValue] = value;
          break;
        }
      }
    }
    return mergedMap;
  }

  @override
  bool shouldReload(covariant LocalizationsDelegate<LocaleInstance> old) => false;
}

enum LocaleOption {
  sys,
  en(Locale('en'), [mapEn, mapZhHant]),
  ja(Locale('ja'), [mapJa, mapZhHant]),
  zhHans(Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hans', countryCode: 'CN'), [mapZhHans, mapZhHant]),
  zhHant(Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant', countryCode: 'TW'), [mapZhHant]);

  final Locale? _locale;
  final List<LocaleInstance>? mapList;

  const LocaleOption([this._locale, this.mapList]);

  Locale get locale => _locale ?? WidgetsBinding.instance.platformDispatcher.locale;

  static Map<LocaleOption, String> get optionMap => <LocaleOption, String>{
    sys: AppLocale.preferencesDefault.s,
    en: StaticString.localeLanguageEn,
    ja: StaticString.localeLanguageJa,
    zhHans: StaticString.localeLanguageZhHans,
    zhHant: StaticString.localeLanguageZhHant,
  };

  static const Iterable<LocalizationsDelegate<dynamic>> localizationsDelegates = <LocalizationsDelegate<dynamic>>[
    AppLocalizationsDelegate(),
    ...GlobalMaterialLocalizations.delegates,
  ];

  static Iterable<Locale> supportedLocales = LocaleOption.values
      .where((option) => option._locale != null)
      .map((option) => option._locale!);
}