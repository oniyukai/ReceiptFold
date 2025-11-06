import 'package:dynamic_color/dynamic_color.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipt_fold/common/app_theme.dart';
import 'package:receipt_fold/common/router.dart';
import 'package:receipt_fold/modules/database_services.dart';
import 'package:receipt_fold/modules/prefs.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/locale/app_localizations.dart';
import 'package:receipt_fold/pages/menu_nav_bar.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
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

class _MyAppState extends State<MyApp> with WidgetsBindingObserver {

  @override
  void dispose() {
    DatabaseServices.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return DynamicColorBuilder(
      builder: (ColorScheme? lightDynamic, ColorScheme? darkDynamic) {
        return Consumer<PrefsProvider>(
          builder: (context, prefs, child) {
            return MaterialApp(

              title: StaticString.appName,
              theme: appTheme(context, lightDynamic, darkDynamic),
              debugShowCheckedModeBanner: false,

              locale: prefs.get<LocaleOption>(PrefsEnum.selectedLanguage).locale,
              localizationsDelegates: LocaleOption.localizationsDelegates,
              supportedLocales: LocaleOption.supportedLocales,

              routes: MyRouter.$ROUTES,
              navigatorKey: MyRouter.navigatorKey,
              onGenerateRoute: MyRouter.onGenerateRoute,

            );
          }
        );
      },
    );
  }
}

// todo: iOS載具與會員桌面小工具
// todo: 完善多國語言