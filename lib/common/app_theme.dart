import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/modules/prefs.dart';

enum ThemeOption {
  sys,
  light(.light),
  dark(.dark);

  final Brightness? brightness;

  const ThemeOption([this.brightness]);

  static Map<ThemeOption, String> get optionMap => (<ThemeOption, String>{
    sys: DictKey.preferencesThemeSystem.s,
    light: DictKey.preferencesThemeLight.s,
    dark: DictKey.preferencesThemeDark.s,
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
    sys: DictKey.preferencesColorMaterialYou.s,
    blue: DictKey.preferencesColorBlue.s,
    orange: DictKey.preferencesColorOrange.s,
    green: DictKey.preferencesColorGreen.s,
    red: DictKey.preferencesColorRed.s,
    purple: DictKey.preferencesColorPurple.s,
  };
}

final class MyAppTheme {
  const MyAppTheme._();

  static late ColorScheme? dynamicColorScheme;

  static const systemOverlayStyle = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    systemNavigationBarColor: Colors.transparent,
    systemNavigationBarDividerColor: Colors.transparent,
    systemStatusBarContrastEnforced: false,
    systemNavigationBarContrastEnforced: false,
  );

  static ThemeData themeData(
      BuildContext context,
      ColorScheme? lightDynamic,
      ColorScheme? darkDynamic,)
  {
    dynamicColorScheme = lightDynamic ?? darkDynamic;
    final Color? seedColor = context.readPrefs.get<ColorOption>(.selectedColor).color;
    final Brightness brightness = context.readPrefs.get<ThemeOption>(.selectedTheme).brightness
        ?? MediaQuery.platformBrightnessOf(context);
    late final ColorScheme colorScheme;
    if (seedColor == null && brightness == .light && lightDynamic != null) {
      colorScheme = lightDynamic;
    } else if (seedColor == null && brightness == .dark && darkDynamic != null) {
      colorScheme = darkDynamic;
    } else {
      colorScheme = .fromSeed(
        seedColor: seedColor ?? Colors.blue, // <- sys顏色不支援時會用到
        brightness: brightness,
      );
    }

    return ThemeData(
      useMaterial3: true,
      colorScheme: colorScheme,
      appBarTheme: const AppBarTheme(
        systemOverlayStyle: systemOverlayStyle,
      ),
      scrollbarTheme: ScrollbarThemeData(
        thumbColor: .all(colorScheme.secondaryContainer),
        radius: const .circular(10.0),
      ),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
      cardTheme: const CardThemeData(
        clipBehavior: .antiAlias,
      ),
    );
  }
}
