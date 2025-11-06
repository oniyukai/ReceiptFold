import 'package:flutter/material.dart';
import 'package:receipt_fold/entity/invoice_period.dart';
import 'package:receipt_fold/modules/invoice_prize_searcher.dart';

class TabCarrierView extends StatefulWidget {
  const TabCarrierView({super.key});

  @override
  State<TabCarrierView> createState() => _TabCarrierViewState();
}

class _TabCarrierViewState extends State<TabCarrierView> {

  void testInvoicePrizeSearch() async {
    final scraper = InvoicePrizeSearcher();

    debugPrint('\n--- 測試對獎功能 ---');

    final allTextTime = {
      DateTime(2025, 5, 15).millisecondsSinceEpoch,
      DateTime(2017, 9, 9).millisecondsSinceEpoch,
      DateTime(2020, 11, 15).millisecondsSinceEpoch,
      DateTime(2010, 1, 1).millisecondsSinceEpoch,
    };
    final allTextNumber = const {
      '47406327',
      '05579058',
      '49912232',
      '19912232',
      '12345004'
      '12345678',
      '123',
      '77815838',
      '12345011',
      '12345427',
      '12345678',
    };

    for (final time in allTextTime) {
      final winningNum = await scraper.findInvoiceWinningNumber(InvoicePeriod.fromUnixTime(time));
      scraper.dispose();
      if (winningNum == null) {
        debugPrint('查無獎金對照: $time');
      } else {
        for (final num in allTextNumber) {
          final result = InvoicePrizeSearcher.checkInvoice(winningNum, num);
          String text = '期號:${winningNum.period}, 時間:$time, 號碼: $num, ';
          text += result==null ? '未中獎' : '${result.locale}, 金額:${result.amount}';
          debugPrint(text);
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        // todo: 載具歸戶頁面
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          TextButton(
            onPressed: testInvoicePrizeSearch,
            child: Text('testInvoicePrizeSearch')
          ),
        ],
      )
    );
  }
}