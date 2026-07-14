import 'package:flutter/material.dart';
import 'package:receipt_fold/modules/invoice_prize_searcher.dart';

class TabScannerView extends StatefulWidget {
  final InvoicePrizeSearcher searcher;

  const TabScannerView({super.key, required this.searcher});

  @override
  State<TabScannerView> createState() => _TabScannerViewState();
}

class _TabScannerViewState extends State<TabScannerView> {
  @override
  Widget build(context) {
    // todo: 相機掃描器頁面
    return Text('施工中... 也許會做出來。');
  }
}
