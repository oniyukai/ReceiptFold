import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:receipt_fold/common/app_theme.dart';
import 'package:receipt_fold/common/router.dart';
import 'package:receipt_fold/modules/database_services.dart';
import 'package:receipt_fold/modules/prefs.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/locale/app_localizations.dart';
import 'package:receipt_fold/pages/menu_nav_bar.dart';
import 'package:watashi_locale/watashi_locale.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(MyAppTheme.systemOverlayStyle);
  await PrefsProvider.init();
  await DatabaseServices.init();
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (context) => MenuNavBarProvider()),
        ChangeNotifierProvider(create: (context) => PrefsProvider()),
      ],
      child: const MyApp(),
    ),
  );
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  @override
  void initState() {
    super.initState();
    WatashiLocale.register([LocaleOption.dictDelegate]);
  }

  @override
  Widget build(context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return Consumer<PrefsProvider>(
          builder: (context, prefs, child) {
            return MaterialApp.router(
              title: StaticString.appName,
              theme: MyAppTheme.themeData(context, lightDynamic, darkDynamic),
              debugShowCheckedModeBanner: false,

              locale: prefs.get<LocaleOption>(.selectedLanguage).locale,
              localizationsDelegates: WatashiLocale.localizationsDelegates,
              supportedLocales: WatashiLocale.supportedLocales,

              routerDelegate: MyRouter.delegate,
              routeInformationParser: MyRouter.parser,
            );
          },
        );
      },
    );
  }
}

// todo: iOS載具與會員桌面小工具
// todo: 完善多國語言
