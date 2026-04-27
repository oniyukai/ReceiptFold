import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:receipt_fold/pages/menu_manager/page_mobile_form.dart';
import 'package:receipt_fold/pages/menu_manager/page_member_form.dart';
import 'package:receipt_fold/pages/menu_nav_bar.dart';
import 'package:receipt_fold/pages/menu_recorder/page_receipt_view.dart';
import 'package:receipt_fold/pages/menu_settings/page_about_view.dart';
import 'package:receipt_fold/pages/menu_settings/page_backup_page.dart';
import 'package:receipt_fold/pages/menu_settings/page_logs_view.dart';
import 'package:receipt_fold/pages/menu_settings/page_terms_view.dart';
import 'package:collection/collection.dart';

typedef _InitialPage = MenuNavBar;
const bool _useIndexPrefix = true;
const String _initialRoute = '/';

class RouteEntry {
  final String route;
  final Widget widget;
  const RouteEntry(this.route, this.widget);
}

final Map<Type, RouteEntry> _routingTable = Map.fromEntries(const <Type, Widget>{
  _InitialPage: _InitialPage(),
  // menu_recorder
  PageReceiptView: PageReceiptView(),
  // menu_scanner
  // menu_manager
  PageMobileForm: PageMobileForm(),
  PageMemberForm: PageMemberForm(),
  // menu_settings
  PageAboutView: PageAboutView(),
  PageTermsView: PageTermsView(),
  PageLogsView: PageLogsView(),
  PageBackupPage: PageBackupPage(),
}.entries.mapIndexed((index, entry) => MapEntry(
    entry.key, RouteEntry(
    '/${_useIndexPrefix ? '$index-' : ''}${entry.key}',
    entry.value))));

final Map<String, RouteEntry> routeEntries = _routingTable.map((k, v) => MapEntry(v.route, v))
  ..[_initialRoute] = RouteEntry(_initialRoute, _routingTable[_InitialPage]!.widget);

class MyRouteConfig<A, R> {
  static int _idCounter = 0;

  final int id = _idCounter++;
  final String route;
  final A? pushArgs;
  final Completer<R?>? popReturn;

  MyRouteConfig(this.route, {
    this.pushArgs,
    this.popReturn,
  });

  static MyRouteConfig of(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<_RouteConfigScope>()!.config;
}

class MyRouteParser extends RouteInformationParser<MyRouteConfig> {
  @override
  Future<MyRouteConfig> parseRouteInformation(routeInformation) =>
      SynchronousFuture(MyRouteConfig(routeEntries[routeInformation.uri.path]?.route ?? _initialRoute));

  @override
  RouteInformation restoreRouteInformation(configuration) =>
      RouteInformation(uri: Uri.parse(configuration.route));
}

class MyRouterDelegate extends RouterDelegate<MyRouteConfig> with ChangeNotifier {
  final List<MyRouteConfig> _stack = [];

  final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  MyRouteConfig? get currentConfiguration => _stack.lastOrNull;

  @override
  Future<void> setNewRoutePath(configuration) async {
    if (_stack.lastOrNull?.route == configuration.route) return;
    _stack..clear()..add(configuration);
  }

  Future<R?> push<R>(Type pageType, [Object? pushArgs]) {
    final routeEntry = _routingTable[pageType];
    assert(routeEntry != null, '_routingTable not included Type<$pageType>, Please register $pageType Route.');
    final popReturn = Completer<R?>();
    _stack.add(MyRouteConfig(routeEntry!.route, pushArgs: pushArgs, popReturn: popReturn));
    notifyListeners();
    return popReturn.future;
  }

  void pop<R>([R? result]) {
    final config = _stack.removeLast();
    if (config.popReturn?.isCompleted == false) config.popReturn!.complete(result);
    notifyListeners();
  }

  @override
  Future<bool> popRoute() {
    if (_stack.length <= 1) return SynchronousFuture(false);
    pop();
    return SynchronousFuture(true);
  }

  void _onDidRemovePage(Page page) {
    final index = _stack.lastIndexWhere((config) => ValueKey(config.id) == page.key);
    if (index != -1) {
      final config = _stack.removeAt(index);
      if (config.popReturn?.isCompleted == false) config.popReturn!.complete(null);
    }
  }

  @override
  Widget build(context) {
    if (_stack.isEmpty) return const Center(child: Text('Navigator _stack.isEmpty'));
    return Navigator(
      key: navigatorKey,
      onDidRemovePage: _onDidRemovePage,
      pages: [
        for (final config in _stack)
          MaterialPage(
            key: ValueKey(config.id),
            name: config.route,
            child: _RouteConfigScope(
              config: config,
              child: routeEntries[config.route]!.widget,
            ),
          ),
      ],
    );
  }
}

class _RouteConfigScope extends InheritedWidget {
  final MyRouteConfig config;

  const _RouteConfigScope({
    required this.config,
    required super.child,
  });

  @override
  bool updateShouldNotify(oldWidget) => false;
}

abstract final class MyRouter {
  static final delegate = MyRouterDelegate();
  static final parser = MyRouteParser();

  static Future<R?> routeTo<R>(Type t) => delegate.push<R>(t);

  static Type? _pageType;

  static P of<P extends RouterBridge>() {
    assert(P != RouterBridge<dynamic>, 'You must specify the route type. ex: MyRouter.of<Page>()');
    _pageType = P;
    return _routingTable[P]!.widget as P;
  }

  static Future<R?> _to<R, A>(A args) {
    final pageType = _pageType!;
    _pageType = null;
    return delegate.push<R>(pageType, args);
  }
}

mixin RouterBridge<A> {
  Future<R?> toPass<R>(A args) => MyRouter._to<R, A>(args);

  A? getArgs(BuildContext context) {
    final args = MyRouteConfig.of(context).pushArgs;
    return args == null ? null : args as A;
  }
}
