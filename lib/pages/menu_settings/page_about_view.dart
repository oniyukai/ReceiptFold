import 'package:flutter/material.dart';
import 'package:receipt_fold/common/prefs.dart';
import 'package:receipt_fold/common/router.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/pages/menu_settings/page_logs_view.dart';
import 'package:receipt_fold/pages/menu_settings/page_terms_view.dart';
import 'package:path/path.dart' as p;

class PageAboutView extends StatefulWidget {
  const PageAboutView({super.key});

  @override
  State<PageAboutView> createState() => _PageAboutViewState();
}

class _PageAboutViewState extends State<PageAboutView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DictKey.settingGroupAbout.s),
      ),
      body: SafeArea(
        child: Scrollbar(
          controller: _scrollController,
          child: ListView(
            controller: _scrollController,
            children: [
              SizedBox.square(
                dimension: 64,
                child: Image.asset(p.join('assets/', 'appicon.png')),
              ),
              const SizedBox(height: 16),
              Text(
                StaticString.appName,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              ListTile(
                title: Text(DictKey.settingOptionVersion.s),
                subtitle: Text(StaticString.appVersion),
                onLongPress: () async {
                  final bool newMode = !context.readPrefs.get(.isAppDeveloperMode);
                  await context.readPrefs.update(.isAppDeveloperMode, newMode, false);
                  Utils.showToast('set ${PrefsEnum.isAppDeveloperMode.name} $newMode, '
                      'default: ${PrefsEnum.isAppDeveloperMode.defaultValue()}');
                },
              ),
              ListTile(
                title: Text(DictKey.settingOptionVersionTag.s),
                subtitle: Text(StaticString.appVersionTag),
              ),
              ListTile(
                title: Text(DictKey.settingOptionDebugLog.s),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => MyRouter.routeTo(PageLogsView),
              ),
              ListTile(
                title: Text(DictKey.settingOptionLicenses.s),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: DictKey.settingOptionLicenses.s,
                ),
              ),
              ListTile(
                title: Text(DictKey.settingTermsTitle.s),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => MyRouter.routeTo(PageTermsView),
              ),
              ListTile(
                title: Text(DictKey.settingOptionSourceCode.s),
                subtitle: Text(StaticString.sourceCodeLink),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => Utils.openUrlInBrowser(StaticString.sourceCodeLink),
              ),
            ],
          )
        )
      )
    );
  }
}
