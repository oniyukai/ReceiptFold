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
        DictKey.preferencesClearedImageCache.s,
        [
          (StaticString.fillObjectOldBytes, UnitUtils.shortBytesText(oldSize)),
          (StaticString.fillObjectNewBytes, UnitUtils.shortBytesText(newSize)),
        ]
      ));
    } catch (e) {
      Utils.showToast('${DictKey.preferencesFailure.s}: $e');
    }
  }

  @override
  Widget build(context) {
    DictKey.load(context);
    return SafeArea(
      child: Scrollbar(
        controller: _scrollController,
        child: Consumer<PrefsProvider>(
          builder: (context, prefs, child) => ListView(
            controller: _scrollController,
            children: [
              ListTileText(text: DictKey.preferencesAppearanceTitle.s, isSection: true),
              ListTilePicker<ColorOption>(
                text: DictKey.preferencesColorLabel.s,
                selectedOption: prefs.get(PrefsEnum.selectedColor),
                optionMap: ColorOption.optionMap,
                onChanged: (value) => prefs.update(PrefsEnum.selectedColor, value),
              ),
              ListTilePicker<ThemeOption>(
                text: DictKey.preferencesThemeLabel.s,
                selectedOption: prefs.get(PrefsEnum.selectedTheme),
                optionMap: ThemeOption.optionMap,
                onChanged: (value) => prefs.update(PrefsEnum.selectedTheme, value),
              ),
              ListTilePicker<LocaleOption>(
                text: DictKey.preferencesLanguageLabel.s,
                selectedOption: prefs.get(PrefsEnum.selectedLanguage),
                optionMap: LocaleOption.optionMap,
                onChanged: (value) => prefs.update(PrefsEnum.selectedLanguage, value),
              ),

              ListTileText(text: DictKey.preferencesPreferenceTitle.s, isSection: true),
              ListTileSwitch(
                text: DictKey.preferencesSwitchAutoBrightnessLabel.s,
                iconData: Icons.brightness_6_outlined,
                initialValue: prefs.get(PrefsEnum.isAutoBrightness),
                onToggle: (value) => prefs.update(PrefsEnum.isAutoBrightness, value),
              ),
              ListTileSwitch(
                text: DictKey.preferencesSwitchScanScreenRotationLabel.s,
                iconData: Icons.screen_rotation,
                initialValue: prefs.get(PrefsEnum.isScanScreenRotation),
                onToggle: (value) => prefs.update(PrefsEnum.isScanScreenRotation, value),
              ),
              ListTileSwitch(
                text: DictKey.preferencesSwitchShowScreenRotationLabel.s,
                iconData: Icons.screen_rotation,
                initialValue: prefs.get(PrefsEnum.isShowScreenRotation),
                onToggle: (value) => prefs.update(PrefsEnum.isShowScreenRotation, value),
              ),
              ListTileText(
                text: DictKey.preferencesClearImageCacheLabel.s,
                iconData: Icons.image_outlined,
                onTap: _clearImageCache,
              ),

              ListTileText(text: DictKey.preferencesInvoicePlatformTitle.s, isSection: true),
              ListTileText(
                text: DictKey.preferencesAccountPasswordLabel.s,
                trailing: const Icon(Icons.chevron_right),
                iconData: Icons.manage_accounts,
                onTap: () => pagePlatformForm(context),
              ),

              ListTileText(text: DictKey.preferencesBackupTitle.s, isSection: true),
              // todo: 雲端同步功能

              ListTileText(text: DictKey.preferencesAboutTitle.s, isSection: true),
              ListTileText(
                text: StaticString.appName,
                trailing: const Icon(Icons.chevron_right),
                onTap:() => MyRouter.routeTo(PageAboutView)
              ),
            ],
          ),
        ),
      ),
    );
  }
}