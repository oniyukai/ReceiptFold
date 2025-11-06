import 'package:flutter/material.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/modules/prefs.dart';

enum ThemeOption {
  sys,
  light(Brightness.light),
  dark(Brightness.dark);

  final Brightness? brightness;

  const ThemeOption([this.brightness]);

  static Map<ThemeOption, String> get optionMap => (<ThemeOption, String>{
    sys: AppLocale.preferencesThemeSystem.s,
    light: AppLocale.preferencesThemeLight.s,
    dark: AppLocale.preferencesThemeDark.s,
  });
}

enum ColorOption {
  sys,
  blue(Colors.blue),
  orange(Colors.orange),
  green(Colors.green),
  red(Colors.red),
  purple(Colors.purple);

  final MaterialColor? color;

  const ColorOption([this.color]);

  static Map<ColorOption, String> get optionMap => <ColorOption, String>{
    sys: AppLocale.preferencesColorMaterialYou.s,
    blue: AppLocale.preferencesColorBlue.s,
    orange: AppLocale.preferencesColorOrange.s,
    green: AppLocale.preferencesColorGreen.s,
    red: AppLocale.preferencesColorRed.s,
    purple: AppLocale.preferencesColorPurple.s,
  };
}

ThemeData appTheme (
  BuildContext context,
  ColorScheme? lightDynamic,
  ColorScheme? darkDynamic,)
{
  final ThemeOption selectedTheme = context.readPrefs.get(PrefsEnum.selectedTheme);
  final ColorOption selectedColor = context.readPrefs.get(PrefsEnum.selectedColor);
  final Brightness brightness = selectedTheme.brightness ?? View.of(context).platformDispatcher.platformBrightness;
  final MaterialColor seedColor = selectedColor.color ?? Colors.blue; // <--sys顏色不支援時會用到
  late final ColorScheme colorScheme;

  if (selectedColor==ColorOption.sys && lightDynamic!=null && brightness==Brightness.light) {
    colorScheme = ColorScheme.fromSeed(
      seedColor: lightDynamic.primary,
      brightness: lightDynamic.brightness,
    );
  } else if (selectedColor==ColorOption.sys && darkDynamic!=null && brightness==Brightness.dark) {
    colorScheme = ColorScheme.fromSeed(
      seedColor: darkDynamic.primary,
      brightness: darkDynamic.brightness,
    );
  } else {
    colorScheme = ColorScheme.fromSeed(
      seedColor: seedColor,
      brightness: brightness,
    );
  }

  return ThemeData(
    useMaterial3: true,
    colorScheme: colorScheme,
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(colorScheme.primary.withValues(alpha:0.5)),
      radius: Radius.circular(10.0),
    ),
    inputDecorationTheme: const InputDecorationTheme(
      border: OutlineInputBorder(),
    ),
    cardTheme: const CardThemeData(
      clipBehavior: Clip.antiAlias,
    ),
  );
}