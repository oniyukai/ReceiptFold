import 'dart:async';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:receipt_fold/common/router.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/entity/drift/drift_database.dart';
import 'package:receipt_fold/entity/invoice_period.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/modules/drift_services.dart';
import 'package:receipt_fold/pages/menu_recorder/page_platform_view.dart';
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
  final oddMonthReceiptMap = <Receipt, List<ReceiptProduct>>{};
  final evenMonthReceiptMap = <Receipt, List<ReceiptProduct>>{};
  double oddMonthTotalAmount = 0;
  double evenMonthTotalAmount = 0;
  bool isLoading = true;
  StreamSubscription<Map<Receipt, List<ReceiptProduct>>>? _receiptSubscription;

  double get totalAmount => oddMonthTotalAmount + evenMonthTotalAmount;

  PeriodData(this.period);

  void dispose() {
    _receiptSubscription?.cancel();
  }
}


class MainRecorderViewModel extends ChangeNotifier {
  /// 快取半徑，表示當前頁面左右各快取多少頁
  static const int _cacheRadius = 1;

  final InvoicePeriod _todayPeriod;
  final Map<int, PeriodData> _periodDataCache = {};
  int _currentPageIndex = MainRecorderView._initialPageIndex;

  int get currentPageIndex => _currentPageIndex;

  MainRecorderViewModel() : _todayPeriod = InvoicePeriod(.now());

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

  PeriodData _loadReceiptsByIndex(int index) => _periodDataCache.putIfAbsent(index, () {
    final periodData = PeriodData(_getInvoicePeriodByIndex(index));
    periodData._receiptSubscription = DriftServices.appDb.receiptDao.queryStream(
      issuedStart: periodData.period.start,
      issuedEnd: periodData.period.end,
      order: .desc,
    ).listen((receiptEntries) {
      if (!_periodDataCache.containsKey(index)) {
        periodData.dispose();
        return;
      }
      periodData.oddMonthReceiptMap.clear();
      periodData.evenMonthReceiptMap.clear();
      periodData.oddMonthTotalAmount = 0;
      periodData.evenMonthTotalAmount = 0;
      for (final entry in receiptEntries.entries) {
        if (entry.key.issuedAt.month % 2 != 0) {
          periodData.oddMonthReceiptMap[entry.key] = entry.value;
          periodData.oddMonthTotalAmount += entry.key.totalAmount;
        } else {
          periodData.evenMonthReceiptMap[entry.key] = entry.value;
          periodData.evenMonthTotalAmount += entry.key.totalAmount;
        }
      }
      periodData.isLoading = false;
      if (index == _currentPageIndex) notifyListeners();
    });
    return periodData;
  });

  /// 根據 PageView 的索引計算對應的 InvoicePeriod
  InvoicePeriod _getInvoicePeriodByIndex(int index) {
    InvoicePeriod targetPeriod = _todayPeriod;
    final relativeIndex = index - MainRecorderView._initialPageIndex;
    if (relativeIndex > 0) {
      for (int i = 0; i < relativeIndex; i += 1) {
        targetPeriod = targetPeriod.next;
      }
    } else if (relativeIndex < 0) {
      for (int i = 0; i > relativeIndex; i -= 1) {
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
  Widget build(context) {
    DictKey.load(context);
    return ChangeNotifierProvider(
      create: (context) => MainRecorderViewModel(),
      child: Consumer<MainRecorderViewModel>(
        builder: (context, model, child) {
          final currentPeriodData = model.getPeriodData(model.currentPageIndex);
          return Scaffold(
            appBar: AppBar(
              title: Text(currentPeriodData.period.stringLocal),
              actions: [
                IconButton(
                  onPressed: () => MyRouter.of<PageReceiptView>().toPass(PageReceiptViewArgs(
                    period: currentPeriodData.period,
                  )),
                  icon: const Icon(Icons.add),
                ),
                MyMenuButton(
                  items: [
                    MyMenuItem(
                      text: DictKey.recorderMenuSyncPlatformLabel.s,
                      iconData: Icons.sync,
                      onTap: () => MyRouter.routeTo(PagePlatformView),
                    ),
                    MyMenuItem(
                      text: DictKey.recorderMenuLabelPrizeVerification.s,
                      iconData: Icons.flip,
                      onTap: (){} // todo: 即時對獎功能
                    ),
                    MyMenuItem(
                      text: DictKey.recorderMenuStatisticalAnalysisLabel.s,
                      iconData: Icons.bar_chart,
                      onTap: (){} // todo: 統計分析功能
                    ),
                    MyMenuItem(
                      text: DictKey.recorderMenuSearchLabel.s,
                      iconData: Icons.search,
                      onTap: (){} // todo: 查詢功能
                    ),
                    MyMenuItem(
                      text: DictKey.recorderMenuReturnTodayLabel.s,
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
                            DictKey.recorderPeriodTransactionsAndAmount.s,
                            [
                              (StaticString.fillObjectNumber, '${periodData.oddMonthReceiptMap.length + periodData.evenMonthReceiptMap.length}'),
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
                                          DictKey.recorderMonthTransactionsAndAmount.s,
                                          [
                                            (StaticString.fillObjectMonth, UnitUtils.singleMonthText(periodData.period.end)),
                                            (StaticString.fillObjectNumber, '${periodData.evenMonthReceiptMap.length}'),
                                            (StaticString.fillObjectAmount, Utils.amountToDescription(periodData.evenMonthTotalAmount))
                                          ]
                                        )),
                                      ),
                                    ),
                                    ...periodData.evenMonthReceiptMap.entries.map((e) => ReceiptItemTile(receiptEntry: e)),
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
                                          DictKey.recorderMonthTransactionsAndAmount.s,
                                          [
                                            (StaticString.fillObjectMonth, UnitUtils.singleMonthText(periodData.period.start)),
                                            (StaticString.fillObjectNumber, '${periodData.oddMonthReceiptMap.length}'),
                                            (StaticString.fillObjectAmount, Utils.amountToDescription(periodData.oddMonthTotalAmount))
                                          ]
                                        )),
                                      ),
                                    ),
                                    ...periodData.oddMonthReceiptMap.entries.map((e) => ReceiptItemTile(receiptEntry: e)),
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
  final MapEntry<Receipt, List<ReceiptProduct>> receiptEntry;

  const ReceiptItemTile({
    super.key,
    required this.receiptEntry,
  });

  @override
  Widget build(context) {
    final DateTime dateTime = receiptEntry.key.issuedAt;
    final String shortWeekday = DateFormat.E(DictKey.languageTag).format(dateTime);
    final textTheme = Theme.of(context).textTheme;
    final colorScheme = Theme.of(context).colorScheme;
    return ListTile(
      visualDensity: VisualDensity.compact,
      onTap: () => MyRouter.of<PageReceiptView>().toPass(PageReceiptViewArgs(
        receiptEntry: receiptEntry,
      )),
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
        receiptEntry.key.sellerName ?? receiptEntry.key.sellerAddress ?? '',
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
                receiptEntry.key.originStatus.locale,
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
              receiptEntry.key.invoiceNumber ?? '',
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
            '\$${Utils.amountToDescription(receiptEntry.key.totalAmount)}',
            style: textTheme.bodyLarge,
          ),
          if (receiptEntry.key.prizeName != null) Text(
            '${receiptEntry.key.prizeName}',
            style: textTheme.bodyMedium,
          ),
        ],
      ),
    );
  }
}
