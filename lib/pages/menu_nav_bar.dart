import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/common/prefs.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/pages/menu_manager/main_manager_view.dart';
import 'package:receipt_fold/pages/menu_recorder/main_recorder_view.dart';
import 'package:receipt_fold/pages/menu_scanner/main_scanner_view.dart';
import 'package:receipt_fold/pages/menu_settings/main_settings_view.dart';
import 'package:receipt_fold/pages/menu_settings/page_terms_view.dart';

class MenuNavBar extends StatefulWidget {
  const MenuNavBar({super.key});

  @override
  State<MenuNavBar> createState() => _MenuNavBarState();
}

class MenuNavBarProvider extends ChangeNotifier {
  int _currentIndex = 0;
  int get currentIndex => _currentIndex;
  bool get onScanner => _currentIndex == 1;
  bool get onManager => _currentIndex == 2;

  void updateIndex(int index) {
    if (_currentIndex != index) {
      _currentIndex = index;
      notifyListeners();
    }
  }
}

class _MenuNavBarState extends State<MenuNavBar> {
  final _pages = const <Widget>[
    MainRecorderView(),
    MainScannerView(),
    MainManagerView(),
    MainSettingsView(),
  ];

  @override
  Widget build(context) {
    DictKey.load(context);
    final bool isPortrait = Utils.isPortrait(context);
    return ValueListenableBuilder(
      valueListenable: context.readPrefs.oneNotifier(.isAgreedAllTerms),
      builder: (context, value, child) => value
          ? Consumer<MenuNavBarProvider>(
        builder: (context, state, child) => Scaffold(
          bottomNavigationBar: isPortrait ? _buildBottomNavigationBar(state) : null,
          body: Row(
            children: [
              if (!isPortrait) _buildSideNavigationBar(state),
              Expanded(child: IndexedStack(index: state.currentIndex, children: _pages)),
            ],
          ),
        ),
      ) : const PageTermsView(),
    );
  }

  Widget _buildBottomNavigationBar(MenuNavBarProvider state) {
    return NavigationBar(
      selectedIndex: state.currentIndex,
      onDestinationSelected: state.updateIndex,
      destinations: [
        NavigationDestination(
          selectedIcon: const Icon(Icons.article),
          icon: const Icon(Icons.article_outlined),
          label: DictKey.navTitleRecorder.s,
        ),
        NavigationDestination(
          selectedIcon: const Icon(Icons.flip),
          icon: const Icon(Icons.fullscreen),
          label: DictKey.navTitleScanner.s,
        ),
        NavigationDestination(
          selectedIcon: const Icon(Icons.inbox),
          icon: const Icon(Icons.inbox_outlined),
          label: DictKey.navTitleManager.s,
        ),
        NavigationDestination(
          selectedIcon: const Icon(Icons.settings),
          icon: const Icon(Icons.settings_outlined),
          label: DictKey.navTitleSettings.s,
        ),
      ],
    );
  }

  Widget _buildSideNavigationBar(MenuNavBarProvider state) {
    return NavigationRail(
      selectedIndex: state.currentIndex,
      onDestinationSelected: state.updateIndex,
      labelType: .all,
      groupAlignment: 0.0,
      destinations: [
        NavigationRailDestination(
          selectedIcon: const Icon(Icons.article),
          icon: const Icon(Icons.article_outlined),
          label: Text(DictKey.navTitleRecorder.s),
        ),
        NavigationRailDestination(
          selectedIcon: const Icon(Icons.flip),
          icon: const Icon(Icons.fullscreen),
          label: Text(DictKey.navTitleScanner.s)
        ),
        NavigationRailDestination(
          selectedIcon: const Icon(Icons.inbox),
          icon: const Icon(Icons.inbox_outlined),
          label: Text(DictKey.navTitleManager.s),
        ),
        NavigationRailDestination(
          selectedIcon: const Icon(Icons.settings),
          icon: const Icon(Icons.settings_outlined),
          label: Text(DictKey.navTitleSettings.s),
        ),
      ],
    );
  }
}
