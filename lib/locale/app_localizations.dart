import 'package:flutter/material.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/locale/map_en.dart';
import 'package:receipt_fold/locale/map_ja.dart';
import 'package:receipt_fold/locale/map_zh_hant.dart';
import 'package:watashi_locale/dictionary_delegate.dart';

enum LocaleOption {
  sys(null, []),
  en(Locale('en'), [mapEn, mapZhHant]),
  ja(Locale('ja'), [mapJa, mapZhHant]),
  zhHant(Locale.fromSubtags(languageCode: 'zh', scriptCode: 'Hant', countryCode: 'TW'), [mapZhHant]);

  final Locale? _locale;
  final List<LocaleInstance> maps;

  const LocaleOption(this._locale, this.maps);

  Locale get locale => _locale ?? WidgetsBinding.instance.platformDispatcher.locale;

  static Map<LocaleOption, String> get optionMap => <LocaleOption, String>{
    sys: DictKey.preferencesDefault.s,
    en: StaticString.localeLanguageEn,
    ja: StaticString.localeLanguageJa,
    zhHant: StaticString.localeLanguageZhHant,
  };

  static final dictDelegate = WatashiDictDelegate(
    defaultCandidate: DictLocaleCandidate(LocaleOption.en, LocaleOption.en._locale, LocaleOption.en.maps),
    localeCandidates: LocaleOption.values.map((e) => DictLocaleCandidate(e, e._locale, e.maps)),
    dictKeys: DictKey.values.toSet(),
    dictWrap: (e) => e,
  );
}
