import 'package:flutter/material.dart';
import 'package:receipt_fold/common/router.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/pages/menu_settings/page_terms_view.dart';

class PageAboutView extends StatefulWidget {
  const PageAboutView({super.key});

  @override
  State<PageAboutView> createState() => _PageAboutViewState();
}

class _PageAboutViewState extends State<PageAboutView> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppLocale.preferencesAboutTitle.s),
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
                title: Text(AppLocale.preferencesApplicationVersionLabel.s),
                subtitle: Text(StaticString.appVersion),
              ),
              ListTile(
                title: Text(AppLocale.preferencesApplicationVersionTagLabel.s),
                subtitle: Text(StaticString.appVersionTag),
              ),
              ListTile(
                title: Text(AppLocale.preferencesAboutOpenSourceLibrariesLabel.s),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => showLicensePage(
                  context: context,
                  applicationName: AppLocale.preferencesAboutOpenSourceLibrariesLabel.s,
                ),
              ),
              ListTile(
                title: Text(AppLocale.preferencesTermsTitle.s),
                trailing: const Icon(Icons.chevron_right),
                onTap: () => context.routeTo(PageTermsView),
              ),
              ListTile(
                title: Text(AppLocale.preferencesSourceCodeLabel.s),
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