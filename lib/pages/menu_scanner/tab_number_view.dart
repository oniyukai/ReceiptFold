import 'dart:async';
import 'dart:math';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/entity/drift/key_value_store.dart';
import 'package:receipt_fold/entity/invoice_prize.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/modules/drift_services.dart';
import 'package:receipt_fold/modules/invoice_prize_searcher.dart';
import 'package:receipt_fold/pages/menu_settings/main_settings_widgets.dart';

class TabNumberView extends StatefulWidget {
  final InvoicePrizeSearcher searcher;

  const TabNumberView({super.key, required this.searcher});

  @override
  State<TabNumberView> createState() => _TabNumberViewState();
}

class _TabNumberViewState extends State<TabNumberView> {
  final ScrollController _scrollController = ScrollController();
  late final StreamSubscription<Map<KVStoreKey, dynamic>> _kVStoreSubscription;
  late List<InvoicePrizeAward> _prizeAwardList;
  bool _isLoading = true;
  String? _errorMessage;
  int _viewIndex = 0;

  @override
  void initState() {
    super.initState();
    unawaited(initPrizeAward());
    _kVStoreSubscription = DriftServices.appDb.keyValueStoreDao
        .stream(const [.invoicePrizeAwardList])
        .listen(
          (data) => setState(() {
            _prizeAwardList = data[KVStoreKey.invoicePrizeAwardList];
            _prizeAwardList.sort((a, b) => b.invQuery.compareTo(a.invQuery));
            _prizeAwardList = _prizeAwardList
                .where((e) => e.prizes.isNotEmpty)
                .toList();
            _viewIndex = min(
              _viewIndex,
              _prizeAwardList.isEmpty ? 0 : _prizeAwardList.length - 1,
            );
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
  void dispose() {
    super.dispose();
    _kVStoreSubscription.cancel();
    _scrollController.dispose();
  }

  Future<void> initPrizeAward() async {
    final InvoicePrizeAward? last = await widget.searcher.getByDistance(0);
    if (last != null) await widget.searcher.getByDistance(1);
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    return Scrollbar(
      controller: _scrollController,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(8.0),
        children: [
          ListTilePicker<int>(
            text: DictKey.scannerNumberBrowsePeriod.s,
            iconData: Icons.calendar_month,
            selectedOption: _viewIndex,
            optionMap: Map.fromEntries(
              _prizeAwardList.mapIndexed(
                (index, prizeAward) =>
                    MapEntry(index, prizeAward.period.invString),
              ),
            ),
            onChanged: (value) {
              setState(() => _viewIndex = value);
            },
          ),

          if (_prizeAwardList.isNotEmpty)
            DataTable(
              columns: [
                DataColumn(label: Text(DictKey.scannerNumberColumnPrize.s)),
                DataColumn(
                  label: Text(DictKey.scannerNumberColumnAmount.s),
                  numeric: true,
                ),
                DataColumn(
                  label: Text(DictKey.scannerNumberColumnNumber.s),
                  numeric: true,
                ),
              ],
              rows: [
                for (final prizes in _prizeAwardList[_viewIndex].prizes)
                  DataRow(
                    cells: [
                      DataCell(Text(prizes.name)),
                      DataCell(Text(UnitUtils.amountText(prizes.amount))),
                      DataCell(Text(prizes.number)),
                    ],
                  ),
              ],
            ),

          Text(DictKey.scannerNumberRule.s, textAlign: TextAlign.center),
        ],
      ),
    );
  }
}
