import 'package:flutter/material.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:provider/provider.dart';
import 'package:receipt_fold/common/app_theme.dart';
import 'package:receipt_fold/common/prefs.dart';
import 'package:receipt_fold/common/router.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/locale/app_localizations.dart';
import 'package:receipt_fold/pages/menu_settings/main_settings_widgets.dart';
import 'package:receipt_fold/pages/menu_settings/page_about_view.dart';
import 'package:receipt_fold/pages/menu_settings/page_backup_view.dart';
import 'package:receipt_fold/pages/menu_settings/page_platform_view.dart';

class MainSettingsView extends StatefulWidget {
  const MainSettingsView({super.key});

  @override
  State<MainSettingsView> createState() => _MainSettingsPageState();
}

class _MainSettingsPageState extends State<MainSettingsView> {
  final ScrollController _scrollController = ScrollController();

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  Future<void> _clearImageCache() async {
    try {
      final cache = DefaultCacheManager();
      final oldSize = await cache.store.getCacheSize();
      await cache.emptyCache();
      final newSize = await cache.store.getCacheSize();
      Utils.showToast(
        Utils.multilingualFiller(DictKey.settingCacheClearedMsg.s, [
          (StaticString.fillObjectOldBytes, UnitUtils.shortBytesText(oldSize)),
          (StaticString.fillObjectNewBytes, UnitUtils.shortBytesText(newSize)),
        ]),
      );
    } catch (e) {
      Utils.showToast('${DictKey.commonUiFailure.s}: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    DictKey.load(context);
    return SafeArea(
      child: Scrollbar(
        controller: _scrollController,
        child: Consumer<PrefsProvider>(
          builder: (context, prefs, child) => ListView(
            controller: _scrollController,
            children: [
              ListTileText(
                text: DictKey.settingGroupAppearance.s,
                isSection: true,
              ),
              ListTilePicker<ColorOption>(
                text: DictKey.settingOptionColor.s,
                selectedOption: prefs.get(.selectedColor),
                optionMap: ColorOption.optionMap,
                leadingBuilder: (radio, selected) =>
                    ColorfulRadio(radio, selected),
                onChanged: (value) => prefs.update(.selectedColor, value),
              ),
              ListTilePicker<ThemeOption>(
                text: DictKey.settingOptionTheme.s,
                selectedOption: prefs.get(.selectedTheme),
                optionMap: ThemeOption.optionMap,
                onChanged: (value) => prefs.update(.selectedTheme, value),
              ),
              ListTilePicker<LocaleOption>(
                text: DictKey.settingGroupLanguages.s,
                selectedOption: prefs.get(.selectedLanguage),
                optionMap: LocaleOption.optionMap,
                onChanged: (value) => prefs.update(.selectedLanguage, value),
              ),

              ListTileText(
                text: DictKey.settingGroupDataAutomation.s,
                isSection: true,
              ),
              ListTileText(
                text: DictKey.settingDataPlatform.s,
                trailing: const Icon(Icons.chevron_right),
                iconData: Icons.account_balance,
                onTap: () => MyRouter.routeTo(PagePlatformView),
              ),
              ListTileText(
                text: DictKey.settingDataBackup.s,
                trailing: const Icon(Icons.chevron_right),
                iconData: Icons.cloud,
                onTap: () => MyRouter.routeTo(PageBackupView),
              ),

              ListTileText(
                text: DictKey.settingGroupPreferences.s,
                isSection: true,
              ),
              ListTileSwitch(
                text: DictKey.settingSwitchShowBrighten.s,
                iconData: Icons.brightness_6_outlined,
                initialValue: prefs.get(.isShowBrighten),
                onToggle: (value) => prefs.update(.isShowBrighten, value),
              ),
              ListTileSwitch(
                text: DictKey.settingSwitchShowLockOrient.s,
                iconData: Icons.screen_rotation,
                initialValue: prefs.get(.isShowLockOrient),
                onToggle: (value) => prefs.update(.isShowLockOrient, value),
              ),
              ListTileSwitch(
                text: DictKey.settingSwitchScanLockOrient.s,
                iconData: Icons.screen_rotation,
                initialValue: prefs.get(.isScanLockOrient),
                onToggle: (value) => prefs.update(.isScanLockOrient, value),
              ),
              ListTileSwitch(
                text: DictKey.settingSwitchScanAutoAdd.s,
                iconData: Icons.flip,
                initialValue: prefs.get(.isScanAutoAdd),
                onToggle: (value) => prefs.update(.isScanAutoAdd, value),
              ),
              ListTileText(
                text: DictKey.settingActionClearCache.s,
                iconData: Icons.image_outlined,
                onTap: _clearImageCache,
              ),

              ListTileText(text: DictKey.settingGroupAbout.s, isSection: true),
              ListTileText(
                text: StaticString.appName,
                trailing: const Icon(Icons.chevron_right),
                onTap: () => MyRouter.routeTo(PageAboutView),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
