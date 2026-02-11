import 'package:flutter/material.dart';
import 'package:receipt_fold/common/router.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/pages/menu_settings/page_logs_view.dart';
import 'package:receipt_fold/pages/menu_settings/page_terms_view.dart';

class PageAboutView extends StatefulWidget {
  const PageAboutView({super.key});

  @override
  State<PageAboutView> createState() => _PageAboutViewState();
}

class _PageAboutViewState extends State<PageAboutView> {
  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(DictKey.preferencesAboutTitle.s),
      ),
      body: SafeArea(
        child: Scrollbar(
          child: ListView(
            children: [
              const SizedBox(
                width: 64,
                height: 64,
                child: Image(
                  image: AssetImage('assets/appicon.png'),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                StaticString.appName,
                style: Theme.of(context).textTheme.headlineSmall,
                textAlign: TextAlign.center,
              ),
              ListTile(
                title: Text(DictKey.preferencesApplicationVersionLabel.s),
                subtitle: Text(StaticString.appVersion),
              ),
              ListTile(
                title: Text(DictKey.preferencesApplicationVersionTagLabel.s),
                subtitle: Text(StaticString.appVersionTag),
              ),
              ListTile(
                title: Text('除錯日誌'), // todo: 除錯日誌功能
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.routeTo(PageLogsView),
              ),
              ListTile(
                title: Text(DictKey.preferencesAboutOpenSourceLibrariesLabel.s),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: DictKey.preferencesAboutOpenSourceLibrariesLabel.s,
                ),
              ),
              ListTile(
                title: Text(DictKey.preferencesTermsTitle.s),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.routeTo(PageTermsView),
              ),
              ListTile(
                title: Text(DictKey.preferencesSourceCodeLabel.s),
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
