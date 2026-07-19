import 'package:flutter/material.dart';
import 'package:receipt_fold/modules/invoice_prize_searcher.dart';
import 'package:receipt_fold/pages/menu_scanner/tab_manual_view.dart';
import 'package:receipt_fold/pages/menu_scanner/tab_number_view.dart';
import 'package:receipt_fold/pages/menu_scanner/tab_scanner_view.dart';

class MainScannerView extends StatefulWidget {
  const MainScannerView({super.key});

  @override
  State<MainScannerView> createState() => _MainScannerViewState();
}

class _MainScannerViewState extends State<MainScannerView>
    with SingleTickerProviderStateMixin {
  final InvoicePrizeSearcher _invoicePrizeSearcher = InvoicePrizeSearcher();
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    super.dispose();
    _tabController.dispose();
    _invoicePrizeSearcher.close();
  }

  @override
  Widget build(context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '手動對獎'),
            Tab(text: '開獎號碼'),
            Tab(text: '掃描發票'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: [
            TabManualView(searcher: _invoicePrizeSearcher),
            TabNumberView(searcher: _invoicePrizeSearcher),
            TabScannerView(searcher: _invoicePrizeSearcher),
          ],
        ),
      ),
    );
  }
}
