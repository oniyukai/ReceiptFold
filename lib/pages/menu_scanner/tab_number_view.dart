import 'dart:async';

import 'package:flutter/material.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/entity/drift/key_value_store.dart';
import 'package:receipt_fold/entity/invoice_prize.dart';
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
  List<InvoicePrizeAward> _prizeAwardList = const [];
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
  Widget build(context) {
    return Scrollbar(
      controller: _scrollController,
      child: Builder(
        builder: (context) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (_errorMessage != null) {
            return Center(child: Text(_errorMessage!));
          }
          return ListView(
            padding: const EdgeInsets.all(8.0),
            children: [
              ListTilePicker<int>(
                text: '瀏覽期別',
                iconData: Icons.calendar_month,
                selectedOption: _viewIndex,
                optionMap: Map.fromEntries(
                  List.generate(
                    _prizeAwardList.length,
                    (index) => MapEntry(
                      index,
                      _prizeAwardList[index].period.invString,
                    ),
                  ),
                ),
                onChanged: (value) {
                  setState(() => _viewIndex = value);
                },
              ),

              if (_prizeAwardList.isNotEmpty)
                DataTable(
                  columns: [
                    DataColumn(label: Text('獎項')),
                    DataColumn(label: Text('獎金'), numeric: true),
                    DataColumn(label: Text('號碼'), numeric: true),
                  ],
                  rows: [
                    for (final prizes in _prizeAwardList[_viewIndex].prizes)
                      DataRow(
                        cells: [
                          DataCell(Text(prizes.name)),
                          DataCell(
                            Text(Utils.amountToDescription(prizes.amount)),
                          ),
                          DataCell(Text(prizes.number)),
                        ],
                      ),
                  ],
                ),

              Text('發票號碼尾數與開獎號碼全數一致的發票，得符合之獎項獎金最大者。', textAlign: .center),
            ],
          );
        },
      ),
    );
  }
}
