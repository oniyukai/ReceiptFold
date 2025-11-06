import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:receipt_fold/common/router.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/entity/invoice_period.dart';
import 'package:receipt_fold/entity/objectbox/objectbox.g.dart';
import 'package:receipt_fold/entity/objectbox/receipt.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/modules/database_services.dart';
import 'package:receipt_fold/pages/menu_recorder/page_receipt_view.dart';
import 'package:receipt_fold/pages/widget/my_menu_button.dart';

class MainRecorderView extends StatefulWidget {
  static const int _initialPageIndex = 1024;

  const MainRecorderView({super.key});

  @override
  State<MainRecorderView> createState() => _MainRecorderViewState();
}


class PeriodData {
  final InvoicePeriod period;
  final List<ReceiptHeader> headers = [];
  final List<ReceiptHeader> oddMonthHeaders = [];
  final List<ReceiptHeader> evenMonthHeaders = [];
  double oddMonthTotalAmount = 0;
  double evenMonthTotalAmount = 0;
  bool isLoading = true;
  StreamSubscription<Query<ReceiptHeader>>? _headerSubscription;

  double get totalAmount => oddMonthTotalAmount + evenMonthTotalAmount;

  PeriodData(this.period);

  void dispose() {
    _headerSubscription?.cancel();
  }
}


class MainRecorderViewModel extends ChangeNotifier {
  /// 快取半徑，表示當前頁面左右各快取多少頁
  static const int _cacheRadius = 2;

  final InvoicePeriod _todayPeriod;
  final Map<int, PeriodData> _periodDataCache = {};
  int _currentPageIndex = MainRecorderView._initialPageIndex;

  int get currentPageIndex => _currentPageIndex;

  MainRecorderViewModel() : _todayPeriod = InvoicePeriod.fromUnixTime(UnitUtils.nowUnixTime);

  PeriodData getPeriodData(int index) => _periodDataCache[index] ?? _loadReceiptsByIndex(index);

  /// 當 PageView 頁面改變時呼叫，更新目前頁面索引
  void switchPeriodByIndex(int index) {
    if (_currentPageIndex == index) return;
    _currentPageIndex = index;
    _cleanUpCache();

    // 這個是可以讓左右滑動前就比itemBuilder更先載入好, 不必定需要
    _loadReceiptsByIndex(_currentPageIndex + 1);
    _loadReceiptsByIndex(_currentPageIndex - 1);

    notifyListeners();
  }

  /// 清理快取中超出範圍的 PeriodData
  void _cleanUpCache() {
    final int minIndex = _currentPageIndex - _cacheRadius;
    final int maxIndex = _currentPageIndex + _cacheRadius;

    final List<int> keysToRemove = [];
    _periodDataCache.forEach((index, periodData) {
      if (index < minIndex || index > maxIndex) {
        keysToRemove.add(index);
      }
    });

    for (final key in keysToRemove) {
      _periodDataCache[key]?.dispose();
      _periodDataCache.remove(key);
    }
  }

  PeriodData _loadReceiptsByIndex(int index) {
    final cachePeriodData = _periodDataCache[index];
    if (cachePeriodData != null) return cachePeriodData;

    final period = _getInvoicePeriodByIndex(index);
    final periodData = PeriodData(period);
    _periodDataCache[index] = periodData;
    final query = DatabaseServices.receiptDao
        .headerTimeFilter(
          period.startDateTime.millisecondsSinceEpoch,
          period.endDateTime.millisecondsSinceEpoch
        )
        .order(ReceiptHeader_.invoiceInstantDate, flags: Order.descending);
    periodData._headerSubscription = query.watch(triggerImmediately: true).listen((newReceiptsQuery) {
      if (!_periodDataCache.containsKey(index)) {
        periodData.dispose();
        return;
      }
      periodData.headers.clear();
      periodData.headers.addAll(newReceiptsQuery.find());
      periodData.oddMonthHeaders.clear();
      periodData.evenMonthHeaders.clear();
      periodData.oddMonthTotalAmount = 0;
      periodData.evenMonthTotalAmount = 0;
      for (final header in periodData.headers) {
        if (header.invoiceDateTime.month % 2 != 0) {
          periodData.oddMonthHeaders.add(header);
          periodData.oddMonthTotalAmount += header.totalAmount;
        } else {
          periodData.evenMonthHeaders.add(header);
          periodData.evenMonthTotalAmount += header.totalAmount;
        }
      }
      periodData.isLoading = false;
      if (index == _currentPageIndex) notifyListeners();
    });
    return periodData;
  }

  /// 根據 PageView 的索引計算對應的 InvoicePeriod
  InvoicePeriod _getInvoicePeriodByIndex(int index) {
    InvoicePeriod targetPeriod = _todayPeriod;
    final relativeIndex = index - MainRecorderView._initialPageIndex;
    if (relativeIndex > 0) {
      for (int i = 0; i < relativeIndex; i++) {
        targetPeriod = targetPeriod.next;
      }
    } else if (relativeIndex < 0) {
      for (int i = 0; i > relativeIndex; i--) {
        targetPeriod = targetPeriod.previous;
      }
    }
    return targetPeriod;
  }

  @override
  void dispose() {
    for (final value in _periodDataCache.values) {
      value.dispose();
    }
    _periodDataCache.clear();
    super.dispose();
  }
}


class _MainRecorderViewState extends State<MainRecorderView> {
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController(initialPage: MainRecorderView._initialPageIndex);

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    AppLocale.load(context);
    return ChangeNotifierProvider(
      create: (context) => MainRecorderViewModel(),
      child: Consumer<MainRecorderViewModel>(
        builder: (context, model, child) {
          final currentPeriodData = model.getPeriodData(model.currentPageIndex);
          return Scaffold(
            appBar: AppBar(
              title: Text(currentPeriodData.period.toString()),
              actions: [
                IconButton(
                  onPressed: () => context.routeOf<PageReceiptView>().arguments(PageReceiptViewArgs(
                    period: currentPeriodData.period,
                  )).to(),
                  icon: const Icon(Icons.add),
                ),
                MyMenuButton(
                  items: [
                    MyMenuItem(
                      text: AppLocale.recorderMenuSyncPlatformLabel.s,
                      iconData: Icons.sync,
                      onTap: (){}, // todo: 同步政府平台功能
                    ),
                    MyMenuItem(
                      text: AppLocale.recorderMenuLabelPrizeVerification.s,
                      iconData: Icons.flip,
                      onTap: (){} // todo: 即時對獎功能
                    ),
                    MyMenuItem(
                      text: AppLocale.recorderMenuStatisticalAnalysisLabel.s,
                      iconData: Icons.bar_chart,
                      onTap: (){} // todo: 統計分析功能
                    ),
                    MyMenuItem(
                      text: AppLocale.recorderMenuSearchLabel.s,
                      iconData: Icons.search,
                      onTap: (){} // todo: 查詢功能
                    ),
                    MyMenuItem(
                      text: AppLocale.recorderMenuReturnTodayLabel.s,
                      iconData: Icons.arrow_back,
                      onTap: () => _pageController.jumpToPage(MainRecorderView._initialPageIndex),
                    ),
                  ],
                ),
              ],
            ),
            body: SafeArea(
              child: PageView.builder(
                controller: _pageController,
                onPageChanged: model.switchPeriodByIndex,
                itemBuilder: (context, index) {
                  final periodData = model.getPeriodData(index);
                  if (periodData.isLoading) return const Center(child: CircularProgressIndicator());
                  return Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            padding: const EdgeInsets.all(0),
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.arrow_left),
                            onPressed: () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            },
                          ),
                          Text(Utils.multilingualFiller(
                            AppLocale.recorderPeriodTransactionsAndAmount.s,
                            [
                              (StaticString.fillObjectNumber, '${periodData.headers.length}'),
                              (StaticString.fillObjectAmount, Utils.amountToDescription(periodData.totalAmount))
                            ]
                          )),
                          IconButton(
                            padding: const EdgeInsets.all(0),
                            visualDensity: VisualDensity.compact,
                            icon: const Icon(Icons.arrow_right),
                            onPressed: () {
                              _pageController.nextPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            },
                          ),
                        ],
                      ),
                      Expanded(
                        child: Scrollbar(
                          controller: _scrollController,
                          child: ListView(
                            addAutomaticKeepAlives: false,
                            addRepaintBoundaries: false,
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            controller: _scrollController,
                            children: [
                              Card(
                                child: Column(
                                  children: [
                                    ListTile(
                                      minTileHeight: 0,
                                      subtitle: Center(
                                        child: Text(Utils.multilingualFiller(
                                          AppLocale.recorderMonthTransactionsAndAmount.s,
                                          [
                                            (StaticString.fillObjectMonth, UnitUtils.singleMonthText(periodData.period.endDateTime)),
                                            (StaticString.fillObjectNumber, '${periodData.evenMonthHeaders.length}'),
                                            (StaticString.fillObjectAmount, Utils.amountToDescription(periodData.evenMonthTotalAmount))
                                          ]
                                        )),
                                      ),
                                    ),
                                    ...periodData.evenMonthHeaders.map((value) => ReceiptItemTile(header: value)),
                                  ],
                                ),
                              ),
                              Card(
                                child: Column(
                                  children: [
                                    ListTile(
                                      minTileHeight: 0,
                                      subtitle: Center(
                                        child: Text(Utils.multilingualFiller(
                                          AppLocale.recorderMonthTransactionsAndAmount.s,
                                          [
                                            (StaticString.fillObjectMonth, UnitUtils.singleMonthText(periodData.period.startDateTime)),
                                            (StaticString.fillObjectNumber, '${periodData.oddMonthHeaders.length}'),
                                            (StaticString.fillObjectAmount, Utils.amountToDescription(periodData.oddMonthTotalAmount))
                                          ]
                                        )),
                                      ),
                                    ),
                                    ...periodData.oddMonthHeaders.map((value) => ReceiptItemTile(header: value)),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }
}


class ReceiptItemTile extends StatelessWidget {
  final ReceiptHeader header;

  const ReceiptItemTile({
    super.key,
    required this.header,
  });

  @override
  Widget build(BuildContext context) {
    final DateTime dateTime = header.invoiceDateTime;
    final String shortWeekday = DateFormat.E(AppLocale.languageTag).format(dateTime);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      visualDensity: VisualDensity.compact,
      onTap: () => context.routeOf<PageReceiptView>().arguments(PageReceiptViewArgs(
        header: header,
      )).to(),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12.0)),
      leading: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            dateTime.day.toString(),
            style: textTheme.titleMedium,
          ),
          Text(
            shortWeekday,
            style: textTheme.bodySmall,
          )
        ],
      ),
      title: Text(
        header.sellerName ?? header.sellerAddress ?? '',
        overflow: TextOverflow.ellipsis,
      ),
      subtitle: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Card(
            color: colorScheme.surfaceContainerHigh,
            elevation: 0,
            margin: const EdgeInsets.all(0),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              child: Text(
                header.receiptOrigin.locale,
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontSize: textTheme.bodySmall?.fontSize,
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              header.invoiceNumber ?? '',
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: textTheme.bodyMedium?.fontSize,
              ),
            )
          ),
        ],
      ),
      trailing: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.end,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            '\$${Utils.amountToDescription(header.totalAmount)}',
            style: textTheme.bodyLarge,
          ),
          if (header.prizeInformation != null) Text(
            '${header.prizeInformation}',
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}