import 'dart:async';

import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:receipt_fold/common/router.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/entity/drift/drift_database.dart';
import 'package:receipt_fold/entity/period.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/modules/drift_services.dart';
import 'package:receipt_fold/modules/invoice_prize_searcher.dart';
import 'package:receipt_fold/pages/menu_recorder/page_receipt_view.dart';
import 'package:receipt_fold/pages/menu_recorder/page_search_form.dart';
import 'package:receipt_fold/pages/menu_recorder/page_search_view.dart';
import 'package:receipt_fold/pages/widget/my_menu_button.dart';
import 'package:receipt_fold/pages/widget/overlay_show.dart';

/// 快取半徑，表示當前頁面左右各快取多少頁
const int _cacheRadius = 1;
const int _initialPageIndex = 1024;

class MainRecorderView extends StatefulWidget {
  const MainRecorderView({super.key});

  @override
  State<MainRecorderView> createState() => _MainRecorderViewState();
}

class PeriodData {
  final Period period;
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
  final Period _todayPeriod;
  final _periodDataCache = <int, PeriodData>{};
  int _currentPageIndex = _initialPageIndex;

  int get currentPageIndex => _currentPageIndex;

  MainRecorderViewModel() : _todayPeriod = Period(DateTime.now());

  PeriodData getPeriodData(int index) =>
      _periodDataCache[index] ?? _loadReceiptsByIndex(index);

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

    final keysToRemove = <int>[];
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

  PeriodData _loadReceiptsByIndex(int index) => _periodDataCache.putIfAbsent(
    index,
    () {
      final periodData = PeriodData(_getInvoicePeriodByIndex(index));
      periodData._receiptSubscription = DriftServices.appDb.receiptDao
          .queryStream(
            issuedAtStart: periodData.period.start,
            issuedAtEnd: periodData.period.end,
          )
          .listen((receiptEntries) {
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
    },
  );

  /// 根據 PageView 的索引計算對應的 InvoicePeriod
  Period _getInvoicePeriodByIndex(int index) {
    Period targetPeriod = _todayPeriod;
    final relativeIndex = index - _initialPageIndex;
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
    super.dispose();
    for (final value in _periodDataCache.values) {
      value.dispose();
    }
    _periodDataCache.clear();
  }
}

class _MainRecorderViewState extends State<MainRecorderView> {
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController(
    initialPage: _initialPageIndex,
  );

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    _pageController.dispose();
  }

  Future<void> _pressPrizeCheck(Period period) async {
    period = Period.inv(
      '${(period.start.year - 1911).toString().padLeft(3, '0')}${period.start.month.toString().padLeft(2, '0')}',
    );
    final receiptMap = await DriftServices.appDb.receiptDao
        .queryStream(issuedAtStart: period.invStart, issuedAtEnd: period.invEnd)
        .first;
    if (receiptMap.isEmpty) {
      Utils.showToast(DictKey.recorderPrizeCheckNoReceipt.s);
      return;
    }
    final searcher = InvoicePrizeSearcher();
    final prizeAward = await searcher.getPrizeAward(period);
    searcher.close();
    if (prizeAward == null) Utils.showToast(DictKey.scannerManualNoData.s);
    final updateReceiptMap = <Receipt, List<ReceiptProduct>>{};
    int totReceipt = 0;
    double prizeTotalAmount = 0;
    for (final entry in receiptMap.entries) {
      Receipt receipt = entry.key;
      final prize = prizeAward?.checkAll(receipt.invoiceNumber);
      if (prize != null && prize.amount > (receipt.prizeAmount ?? 0.0)) {
        receipt = receipt.copyWith(
          prizeAmount: Value.absentIfNull(prize.amount.toDouble()),
          prizeName: Value.absentIfNull(Utils.noEmptyStr(prize.name)),
        );
        updateReceiptMap[receipt] = entry.value;
      }
      final prizeAmount = receipt.prizeAmount ?? 0.0;
      if (prizeAmount > 0.0) {
        totReceipt += 1;
        prizeTotalAmount += prizeAmount;
      }
    }
    await Future.wait(
      updateReceiptMap.entries.map(
        (e) => DriftServices.appDb.receiptDao.upsert(e.key, e.value),
      ),
    );
    await OverlayShow.dialog(
      context: context,
      title: DictKey.recorderPrizeCheckResult.s,
      noCancelButton: true,
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          ListTile(
            title: Text(period.invString),
            subtitle: Text(DictKey.receiptHeaderIssuedPeriod.s),
          ),
          ListTile(
            title: Text(UnitUtils.amountText(prizeTotalAmount)),
            subtitle: Text(DictKey.recorderPrizeCheckTotalAmount.s),
          ),
          ListTile(
            title: Text(UnitUtils.amountText(totReceipt)),
            subtitle: Text(DictKey.recorderPrizeCheckReceiptCount.s),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    DictKey.load(context);
    return ChangeNotifierProvider(
      create: (_) => MainRecorderViewModel(),
      child: Consumer<MainRecorderViewModel>(
        builder: (context, model, child) {
          final currentPeriodData = model.getPeriodData(model.currentPageIndex);
          return Scaffold(
            appBar: AppBar(
              title: Text(currentPeriodData.period.localString),
              actions: [
                IconButton(
                  onPressed: () => MyRouter.of<PageReceiptView>().toPass(
                    PageReceiptViewArgs(period: currentPeriodData.period),
                  ),
                  icon: const Icon(Icons.add),
                ),
                MyMenuButton(
                  items: [
                    MyMenuItem(
                      text: DictKey.recorderMenuSearch.s,
                      iconData: Icons.search,
                      onTap: () => MyRouter.routeTo(PageSearchForm),
                    ),
                    MyMenuItem(
                      text: DictKey.recorderMenuPrizeCheck.s,
                      iconData: Icons.flip,
                      onTap: () => _pressPrizeCheck(currentPeriodData.period),
                    ),
                    MyMenuItem(
                      text: DictKey.recorderMenuReturnToday.s,
                      iconData: Icons.arrow_back,
                      onTap: () =>
                          _pageController.jumpToPage(_initialPageIndex),
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
                  if (periodData.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  return Column(
                    children: [
                      Row(
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
                          Expanded(
                            child: Text(
                              Utils.multilingualFiller(
                                DictKey.recorderPeriodTransactionsAndAmount.s,
                                [
                                  (
                                    StaticString.fillObjectNumber,
                                    '${periodData.oddMonthReceiptMap.length + periodData.evenMonthReceiptMap.length}',
                                  ),
                                  (
                                    StaticString.fillObjectAmount,
                                    UnitUtils.amountText(
                                      periodData.totalAmount,
                                    ),
                                  ),
                                ],
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),
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
                            controller: _scrollController,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8.0,
                            ),
                            children: [
                              ReceiptListCard(
                                text: Utils.multilingualFiller(
                                  DictKey.recorderMonthTransactionsAndAmount.s,
                                  [
                                    (
                                      StaticString.fillObjectMonth,
                                      UnitUtils.singleMonthText(
                                        periodData.period.end,
                                      ),
                                    ),
                                    (
                                      StaticString.fillObjectNumber,
                                      '${periodData.evenMonthReceiptMap.length}',
                                    ),
                                    (
                                      StaticString.fillObjectAmount,
                                      UnitUtils.amountText(
                                        periodData.evenMonthTotalAmount,
                                      ),
                                    ),
                                  ],
                                ),
                                receiptMap: periodData.evenMonthReceiptMap,
                              ),
                              ReceiptListCard(
                                text: Utils.multilingualFiller(
                                  DictKey.recorderMonthTransactionsAndAmount.s,
                                  [
                                    (
                                      StaticString.fillObjectMonth,
                                      UnitUtils.singleMonthText(
                                        periodData.period.start,
                                      ),
                                    ),
                                    (
                                      StaticString.fillObjectNumber,
                                      '${periodData.oddMonthReceiptMap.length}',
                                    ),
                                    (
                                      StaticString.fillObjectAmount,
                                      UnitUtils.amountText(
                                        periodData.oddMonthTotalAmount,
                                      ),
                                    ),
                                  ],
                                ),
                                receiptMap: periodData.oddMonthReceiptMap,
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
