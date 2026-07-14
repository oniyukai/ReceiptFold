import 'package:flutter/material.dart';
import 'package:receipt_fold/modules/invoice_prize_searcher.dart';

class TabManualView extends StatefulWidget {
  final InvoicePrizeSearcher searcher;

  const TabManualView({super.key, required this.searcher});

  @override
  State<TabManualView> createState() => _TabManualViewState();
}

class _TabManualViewState extends State<TabManualView> {
  @override
  Widget build(context) {
    // todo: 手動對獎頁面 + 即時對獎功能
    return SizedBox.shrink();
  }
}
