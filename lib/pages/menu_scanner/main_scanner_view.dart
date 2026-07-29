import 'package:flutter/material.dart';
import 'package:receipt_fold/locale/app_language.dart';
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
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: DictKey.scannerTabManual.s),
            Tab(text: DictKey.scannerTabNumber.s),
            Tab(text: DictKey.scannerTabScan.s),
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
