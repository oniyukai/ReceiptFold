import 'package:flutter/material.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/entity/invoice_period.dart';
import 'package:receipt_fold/entity/invoice_prize.dart';
import 'package:receipt_fold/modules/invoice_prize_searcher.dart';
import 'package:receipt_fold/pages/menu_scanner/tab_manual_view.dart';
import 'package:receipt_fold/pages/menu_scanner/tab_number_view.dart';
import 'package:receipt_fold/pages/menu_scanner/tab_scanner_view.dart';

class MainScannerView extends StatefulWidget {
  const MainScannerView({super.key});

  @override
  State<MainScannerView> createState() => _MainScannerViewState();
}

class _MainScannerViewState extends State<MainScannerView> with SingleTickerProviderStateMixin {
  final InvoicePrizeSearcher _invoicePrizeSearcher = InvoicePrizeSearcher();
  late final TabController _tabController;
  late final InvoiceWinningNumber? _thisWinningNumber;
  late final InvoiceWinningNumber? _lastWinningNumber;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadPeriodNumber();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadPeriodNumber() async {
    late final InvoiceWinningNumber? thisWinningNumber;
    late final InvoiceWinningNumber? lastWinningNumber;
    final nowInvoicePeriod = InvoicePeriod.fromUnixTime(UnitUtils.nowUnixTime);
    final last1InvoicePeriod = nowInvoicePeriod.previous;
    final last2InvoicePeriod = last1InvoicePeriod.previous;
    final last3InvoicePeriod = last2InvoicePeriod.previous;
    final nowWinningNumber = await _invoicePrizeSearcher.findInvoiceWinningNumber(nowInvoicePeriod);
    final last1WinningNumber = await _invoicePrizeSearcher.findInvoiceWinningNumber(last1InvoicePeriod);
    if (nowWinningNumber != null) {
      thisWinningNumber = nowWinningNumber;
      lastWinningNumber = last1WinningNumber;
    } else if (last1WinningNumber != null) {
      thisWinningNumber = last1WinningNumber;
      lastWinningNumber = await _invoicePrizeSearcher.findInvoiceWinningNumber(last2InvoicePeriod);
    } else {
      thisWinningNumber = await _invoicePrizeSearcher.findInvoiceWinningNumber(last2InvoicePeriod);
      lastWinningNumber = await _invoicePrizeSearcher.findInvoiceWinningNumber(last3InvoicePeriod);
    }
    setState(() {
      _thisWinningNumber = thisWinningNumber;
      _lastWinningNumber = lastWinningNumber;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 0,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: '掃描對獎'),
            Tab(text: '手動對獎'),
            Tab(text: '中獎號碼'),
          ],
        ),
      ),
      body: SafeArea(
        child: TabBarView(
          controller: _tabController,
          children: const [
            TabScannerView(),
            TabManualView(),
            TabNumberView(),
          ],
        ),
      )
    );
  }
}