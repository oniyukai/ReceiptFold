import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipt_fold/common/app_theme.dart';
import 'package:receipt_fold/common/router.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/modules/prefs.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/locale/app_localizations.dart';
import 'package:receipt_fold/pages/menu_settings/main_settings_widgets.dart';
import 'package:receipt_fold/pages/menu_settings/page_about_view.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:receipt_fold/pages/menu_settings/page_platform_form.dart';

class MainSettingsView extends StatefulWidget {
  const MainSettingsView({super.key});

  @override
  State<MainSettingsView> createState() => _MainSettingsPageState();
}

class _MainSettingsPageState extends State<MainSettingsView> {
  final ScrollController _scrollController = ScrollController();

  Future<void> _clearImageCache() async {
    try {
      final cache = DefaultCacheManager();
      final oldSize = await cache.store.getCacheSize();
      await cache.emptyCache();
      final newSize = await cache.store.getCacheSize();
      Utils.showToast(Utils.multilingualFiller(
        AppLocale.preferencesClearedImageCache.s,
        [
          (StaticString.fillObjectOldBytes, UnitUtils.shortBytesText(oldSize)),
          (StaticString.fillObjectNewBytes, UnitUtils.shortBytesText(newSize)),
        ]
      ));
    } catch (e) {
      Utils.showToast('${AppLocale.preferencesFailure.s}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    AppLocale.load(context);
    return SafeArea(
      child: Scrollbar(
        controller: _scrollController,
        child: Consumer<PrefsProvider>(
          builder: (context, prefs, child) => ListView(
            controller: _scrollController,
            children: [
              ListTileText(text: AppLocale.preferencesAppearanceTitle.s, isSection: true),
              ListTilePicker<ColorOption>(
                text: AppLocale.preferencesColorLabel.s,
                selectedOption: prefs.get(PrefsEnum.selectedColor),
                optionMap: ColorOption.optionMap,
                onChanged: (value) => prefs.update(PrefsEnum.selectedColor, value),
              ),
              ListTilePicker<ThemeOption>(
                text: AppLocale.preferencesThemeLabel.s,
                selectedOption: prefs.get(PrefsEnum.selectedTheme),
                optionMap: ThemeOption.optionMap,
                onChanged: (value) => prefs.update(PrefsEnum.selectedTheme, value),
              ),
              ListTilePicker<LocaleOption>(
                text: AppLocale.preferencesLanguageLabel.s,
                selectedOption: prefs.get(PrefsEnum.selectedLanguage),
                optionMap: LocaleOption.optionMap,
                onChanged: (value) => prefs.update(PrefsEnum.selectedLanguage, value),
              ),

              ListTileText(text: AppLocale.preferencesPreferenceTitle.s, isSection: true),
              ListTileSwitch(
                text: AppLocale.preferencesSwitchAutoBrightnessLabel.s,
                initialValue: prefs.get(PrefsEnum.isAutoBrightness),
                iconData: Icons.brightness_6_outlined,
                onToggle: (value) => prefs.update(PrefsEnum.isAutoBrightness, value),
              ),
              ListTileSwitch(
                text: AppLocale.preferencesSwitchScanScreenRotationLabel.s,
                initialValue: prefs.get(PrefsEnum.isScanScreenRotation),
                iconData: Icons.screen_rotation,
                onToggle: (value) => prefs.update(PrefsEnum.isScanScreenRotation, value),
              ),
              ListTileSwitch(
                text: AppLocale.preferencesSwitchShowScreenRotationLabel.s,
                initialValue: prefs.get(PrefsEnum.isShowScreenRotation),
                iconData: Icons.screen_rotation,
                onToggle: (value) => prefs.update(PrefsEnum.isShowScreenRotation, value),
              ),
              ListTileText(
                text: AppLocale.preferencesClearImageCacheLabel.s,
                iconData: Icons.image_outlined,
                onTap: _clearImageCache,
              ),

              ListTileText(text: AppLocale.preferencesInvoicePlatformTitle.s, isSection: true),
              ListTileText(
                text: AppLocale.preferencesAccountPasswordLabel.s,
                trailing: const Icon(Icons.chevron_right),
                iconData: Icons.manage_accounts,
                onTap: () => pagePlatformForm(context),
              ),

              ListTileText(text: AppLocale.preferencesBackupTitle.s, isSection: true),
              // todo: 雲端同步功能

              ListTileText(text: AppLocale.preferencesAboutTitle.s, isSection: true),
              ListTileText(
                text: StaticString.appName,
                trailing: const Icon(Icons.chevron_right),
                onTap:() => context.routeTo(PageAboutView)
              ),
            ],
          ),
        ),
      ),
    );
  }
}