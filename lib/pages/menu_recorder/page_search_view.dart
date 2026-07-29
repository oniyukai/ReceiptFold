import 'dart:async';

import 'package:drift/drift.dart' show Expression;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:receipt_fold/common/router.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/entity/drift/drift_database.dart';
import 'package:receipt_fold/entity/period.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/modules/drift_services.dart';
import 'package:receipt_fold/pages/menu_recorder/page_receipt_view.dart';

const int _maxSearchLimit = 100;

class PageSearchView extends StatefulWidget
    with RouterBridge<List<Expression<bool>>> {
  const PageSearchView({super.key});

  @override
  State<PageSearchView> createState() => _PageSearchViewState();
}

class _PageSearchViewState extends State<PageSearchView> {
  final ScrollController _scrollController = ScrollController();
  final PageController _pageController = PageController();
  late final List<Expression<bool>> _conditionals = widget.getArgs(context)!;
  StreamSubscription<Map<Receipt, List<ReceiptProduct>>>? _subscription;
  late Map<Receipt, List<ReceiptProduct>> _receiptMap;
  late Map<DateTime, Map<Receipt, List<ReceiptProduct>>> _dateReceiptMap;
  int _itemCount = 1;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_subscription == null) _onPageChanged(0);
  }

  @override
  void dispose() {
    super.dispose();
    _subscription?.cancel();
    _scrollController.dispose();
    _pageController.dispose();
  }

  Future<void> _onPageChanged(int index) async {
    setState(() {
      _receiptMap = const {};
      _dateReceiptMap = const {};
      _isLoading = true;
      _errorMessage = null;
    });
    await _subscription?.cancel();
    _subscription = DriftServices.appDb.receiptDao
        .queryStream(
          conditionals: _conditionals,
          limit: _maxSearchLimit,
          offset: index * _maxSearchLimit,
        )
        .listen(
          (data) => setState(() {
            _receiptMap = data;
            _dateReceiptMap = {};
            for (final entry in _receiptMap.entries) {
              final DateTime issuedAt = entry.key.issuedAt;
              final period = Period(issuedAt);
              _dateReceiptMap.putIfAbsent(
                issuedAt.month % 2 != 0 ? period.start : period.end,
                () => {},
              )[entry.key] = entry.value;
            }
            _itemCount = data.length < _maxSearchLimit ? index + 1 : index + 2;
            _isLoading = false;
            _errorMessage = null;
          }),
          onError: (e) => setState(() {
            _isLoading = false;
            _errorMessage = e.toString();
          }),
        );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(DictKey.searchResultTitle.s)),
      body: SafeArea(
        child: PageView.builder(
          itemCount: _itemCount,
          controller: _pageController,
          onPageChanged: _onPageChanged,
          itemBuilder: (context, index) {
            if (_isLoading) {
              return const Center(child: CircularProgressIndicator());
            } else if (_errorMessage != null) {
              return Center(child: Text(_errorMessage!));
            }
            return Column(
              children: [
                Row(
                  children: [
                    IconButton(
                      padding: const EdgeInsets.all(0),
                      visualDensity: VisualDensity.compact,
                      icon: const Icon(Icons.arrow_left),
                      onPressed: index <= 0
                          ? null
                          : () {
                              _pageController.previousPage(
                                duration: const Duration(milliseconds: 300),
                                curve: Curves.easeOut,
                              );
                            },
                    ),
                    Expanded(
                      child: Text(
                        Utils.multilingualFiller(
                          DictKey.searchResultSummary.s,
                          [
                            (StaticString.fillObjectNumber, '${index + 1}'),
                            (
                              StaticString.fillObjectCount,
                              '${_receiptMap.length}',
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
                      onPressed: index >= _itemCount - 1
                          ? null
                          : () {
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
                      padding: const EdgeInsets.symmetric(horizontal: 8.0),
                      children: _dateReceiptMap.entries.map((dateEntry) {
                        final DateFormat yearFormatter = DateFormat.y(
                          DictKey.languageTag,
                        );
                        final String yearPart = yearFormatter.format(
                          dateEntry.key,
                        );
                        final String monthName = UnitUtils.singleMonthText(
                          dateEntry.key,
                        );
                        return ReceiptListCard(
                          text: '$yearPart $monthName',
                          receiptMap: dateEntry.value,
                        );
                      }).toList(),
                    ),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class ReceiptListCard extends StatelessWidget {
  final String text;
  final Map<Receipt, List<ReceiptProduct>> receiptMap;

  const ReceiptListCard({
    super.key,
    required this.text,
    required this.receiptMap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        children: [
          ListTile(
            minTileHeight: 0.0,
            subtitle: Text(text, textAlign: TextAlign.center),
          ),
          ...receiptMap.entries.map((receiptEntry) {
            final DateTime dateTime = receiptEntry.key.issuedAt;
            final String shortWeekday = DateFormat.E(
              DictKey.languageTag,
            ).format(dateTime);
            final textTheme = Theme.of(context).textTheme;
            final colorScheme = Theme.of(context).colorScheme;
            return ListTile(
              visualDensity: VisualDensity.compact,
              onTap: () => MyRouter.of<PageReceiptView>().toPass(
                PageReceiptViewArgs(receiptEntry: receiptEntry),
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12.0),
              ),
              leading: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(dateTime.day.toString(), style: textTheme.titleMedium),
                  Text(shortWeekday, style: textTheme.bodySmall),
                ],
              ),
              title: Text(
                receiptEntry.key.sellerName ??
                    receiptEntry.key.sellerAddress ??
                    '',
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
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
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
                    ),
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
                  if (receiptEntry.key.prizeName != null)
                    Text(
                      '${receiptEntry.key.prizeName}',
                      style: textTheme.bodyMedium,
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }
}
