import 'dart:async';
import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:receipt_fold/common/app_theme.dart';
import 'package:receipt_fold/common/router.dart';
import 'package:receipt_fold/entity/drift/drift_database.dart';
import 'package:receipt_fold/common/prefs.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/locale/app_localizations.dart';
import 'package:receipt_fold/pages/menu_nav_bar.dart';
import 'package:receipt_fold/pages/menu_settings/page_backup_view.dart';
import 'package:watashi_locale/watashi_locale.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setEnabledSystemUIMode(.edgeToEdge);
  SystemChrome.setSystemUIOverlayStyle(MyAppTheme.systemOverlayStyle);
  await Future.wait([PrefsProvider.init()]);
  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => MenuNavBarProvider()),
        ChangeNotifierProvider(create: (_) => PrefsProvider()),
        Provider(create: (_) => MyDriftDatabase(), lazy: false, dispose: (_, db) => db.close()),
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
    Timer(const Duration(seconds: 1), DriftDispatcher.connectWebDAV);
  }

  @override
  Widget build(context) {
    return DynamicColorBuilder(
      builder: (lightDynamic, darkDynamic) {
        return ListenableBuilder(
          listenable: context.readPrefs.listens(const [.selectedColor, .selectedTheme, .selectedLanguage]),
          builder: (context, child) {
            return MaterialApp.router(
              title: StaticString.appName,
              theme: MyAppTheme.themeData(context, lightDynamic, darkDynamic),
              debugShowCheckedModeBanner: false,

              locale: context.readPrefs.get<LocaleOption>(.selectedLanguage).locale,
              localizationsDelegates: WatashiLocale.getDelegates(),
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
