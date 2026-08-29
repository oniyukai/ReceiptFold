import 'dart:async';

import 'package:flutter/services.dart';
import 'package:material_ui/material_ui.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/entity/invoice_prize.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/services/invoice_prize_searcher.dart';

const int _groupSize = 3;

class TabManualView extends StatefulWidget {
  final InvoicePrizeSearcher searcher;

  const TabManualView({super.key, required this.searcher});

  @override
  State<TabManualView> createState() => _TabManualViewState();
}

class _TabManualViewState extends State<TabManualView> {
  final ScrollController _scrollController = ScrollController();
  final TextEditingController _fieldController = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  List<InvoicePrizeAward>? _prizeAwardList;
  String _endNumber = StaticString.nullString;

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    _fieldController.dispose();
    _focusNode.dispose();
  }

  Future<void> _onCompleted(String value) async {
    assert(value.length == 3);
    _prizeAwardList ??= [
      ?await widget.searcher.getByDistance(0),
      ?await widget.searcher.getByDistance(1),
    ];
    setState(() => _endNumber = value);
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    return Scrollbar(
      controller: _scrollController,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(8.0),
        children: [
          Visibility(
            visible: false,
            maintainState: true,
            maintainFocusability: true,
            child: TextField(
              // 鍵盤不應可以移動輸入游標, 不過算了不處理
              controller: _fieldController,
              focusNode: _focusNode,
              keyboardType: TextInputType.number,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly],
              decoration: const InputDecoration(border: InputBorder.none),
              onChanged: (value) {
                if (value.isNotEmpty && value.length % _groupSize == 0) {
                  unawaited(
                    _onCompleted(value.substring(value.length - _groupSize)),
                  );
                }
                setState(() {});
              },
            ),
          ),
          GestureDetector(
            onTap: _focusNode.requestFocus,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              spacing: 8,
              children: List.generate(_groupSize, (index) {
                final String text = _fieldController.text;
                final int charAt = ((text.length - 1) ~/ 3) * 3 + index;
                return Container(
                  width: 64,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: colorScheme.primary,
                      width: text.length % _groupSize == index ? 3.0 : 1.0,
                    ),
                  ),
                  child: Text(
                    text.length > charAt && charAt >= 0 ? text[charAt] : '',
                    style: textTheme.displaySmall,
                    textAlign: TextAlign.center,
                  ),
                );
              }),
            ),
          ),
          if (_prizeAwardList == null)
            Text(DictKey.scannerManualHint.s, textAlign: TextAlign.center),
          if (_prizeAwardList?.isEmpty == true)
            Text(DictKey.scannerManualNoData.s, textAlign: TextAlign.center),
          if (_prizeAwardList?.isNotEmpty == true)
            for (final prizeAward in _prizeAwardList!)
              DataTable(
                columns: [
                  DataColumn(label: Text(prizeAward.period.invString)),
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
                  for (final prizes in prizeAward.checkEnd(_endNumber))
                    DataRow(
                      cells: [
                        DataCell(Text(prizes.name)),
                        DataCell(Text(UnitUtils.amountText(prizes.amount))),
                        DataCell(Text(prizes.number)),
                      ],
                    ),
                ],
              ),
        ],
      ),
    );
  }
}
