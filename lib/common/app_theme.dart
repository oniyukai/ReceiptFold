import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/common/prefs.dart';

enum ThemeOption {
  sys,
  light(.light),
  dark(.dark);

  final Brightness? brightness;

  const ThemeOption([this.brightness]);

  static Map<ThemeOption, String> get optionMap => <ThemeOption, String>{
    sys: DictKey.settingOptionThemeSystem.s,
    light: DictKey.settingOptionThemeLight.s,
    dark: DictKey.settingOptionThemeDark.s,
  };
}

enum ColorOption {
  sys,
  blue(Colors.blue),
  violet(Color(0xFF6750A4)),
  purple(Colors.purple),
  pink(Colors.pink),
  deepOrange(Colors.deepOrange),
  orange(Colors.orange),
  yellow(Colors.yellow),
  green(Colors.green),
  teal(Colors.teal);

  final Color? color;

  const ColorOption([this.color]);

  static Map<ColorOption, String> get optionMap => <ColorOption, String>{
    sys: DictKey.settingOptionColorMaterialYou.s,
    blue: DictKey.settingOptionColorBlue.s,
    violet: DictKey.settingOptionColorViolet.s,
    purple: DictKey.settingOptionColorPurple.s,
    pink: DictKey.settingOptionColorPink.s,
    deepOrange: DictKey.settingOptionColorDeepOrange.s,
    orange: DictKey.settingOptionColorOrange.s,
    yellow: DictKey.settingOptionColorYellow.s,
    green: DictKey.settingOptionColorGreen.s,
    teal: DictKey.settingOptionColorTeal.s,
  };
}

abstract final class MyAppTheme {
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
