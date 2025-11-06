import 'package:dio/dio.dart';
import 'package:html/parser.dart' show parse;
import 'package:html/dom.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/entity/invoice_period.dart';
import 'package:receipt_fold/entity/invoice_prize.dart';
import 'package:receipt_fold/modules/database_services.dart';
import 'package:flutter/material.dart' as material;
import 'package:receipt_fold/modules/prefs.dart';

class InvoicePrizeSearcher {
  final Dio _dio = Dio();

  void dispose() {
    _dio.close();
  }

  void debugPrint(String? message) {
    if (PrefsEnum.isAppDeveloperMode.defaultValue()) material.debugPrint(message);
  }

  bool _matcheSpecifiedTimeInterval(int unixMilliseconds) {
    final int currentUnixMilliseconds = UnitUtils.nowUnixTime;
    final int differenceInMilliseconds = (unixMilliseconds - currentUnixMilliseconds).abs();
    const int targetDifferenceInSeconds = 1000;
    const int targetDifferenceInMilliseconds = targetDifferenceInSeconds * 1000;
    return differenceInMilliseconds >= targetDifferenceInMilliseconds;
  }

  Future<InvoiceWinningNumber?> findInvoiceWinningNumber(InvoicePeriod invoicePeriod) async {
    final period = invoicePeriod.getROCPeriod;
    final history = DatabaseServices.invoiceWinningNumberList;
    final historyWhere = history.indexWhere((item) => item.period == period);
    if (historyWhere >= 0) {
      final result = history[historyWhere];
      if (result.prizes != null && result.prizes!.isNotEmpty) return result;
      // 如果上次查詢未冷卻完畢不再查詢網頁
      if (!_matcheSpecifiedTimeInterval(result.lastWebQueryTime)) return null;
    }

    final Map<InvoiceEntityPrize, List<String>> prizes = {};
    final fullUrl = 'https://www.etax.nat.gov.tw/etw-main/ETW183W2_$period/';
    try {
      debugPrint('正在請求 URL: $fullUrl');
      final response = await _dio.get(fullUrl);
      if (response.statusCode == 200) {
        final document = parse(response.data);
        final table = document.querySelector('table#tenMillionsTable');
        if (table != null) {
          final tbody = table.querySelector('tbody');
          if (tbody != null) {
            List<Element> rows = tbody.querySelectorAll('tr');

            for (int i = 0; i < rows.length; i++) {
              final row = rows[i];
              final th = row.querySelector('th[scope="row"]');
              final td = row.querySelector('td');

              if (th != null && td != null) {
                final headerText = th.text.trim();

                final InvoiceEntityPrize? prizeType = switch (headerText) {
                  '特別獎' => InvoiceEntityPrize.special,
                  '特獎' => InvoiceEntityPrize.grand,
                  '頭獎' => InvoiceEntityPrize.first,
                  '增開六獎' => InvoiceEntityPrize.additionalSixth,
                  _ => null,
                };

                if (prizeType != null) {
                  final List<String> numbers = [];
                  // 號碼在當前行的 td 內部的 div.col-12 中
                  final numberDivs = td.querySelectorAll('div.col-12');
                  for (var div in numberDivs) {
                    numbers.add(div.text.trim());
                  }

                  // 說明在下一行的 td 中
                  if (i + 1 < rows.length) {
                    final nextRow = rows[i + 1];
                    final nextTd = nextRow.querySelector('td');
                    if (nextTd != null) {
                      prizes[prizeType] = numbers;
                      i++; // 跳過下一行，因為已經處理
                    }
                  }
                }
              }
            }
          } else {
            debugPrint('錯誤: 無法找到tbody 於 $fullUrl。');
          }
        } else {
          debugPrint('錯誤: 無法找到中獎號碼表格 (ID: tenMillionsTable) 於 $fullUrl。');
        }
      } else {
        debugPrint('請求 $fullUrl 失敗，狀態碼: ${response.statusCode}');
      }
    } on DioException catch (e) {
      debugPrint('Dio 錯誤 (取$period): $e');
      if (e.response?.statusCode == 404) debugPrint('錯誤: 找不到該期發票中獎號碼頁面 ($fullUrl)。');
      if (e.response != null) debugPrint('回應資料: ${e.response?.data}');
    } catch (e) {
      debugPrint('發生未知錯誤 (取$period): $e');
    }

    final invoiceWinningNumber = InvoiceWinningNumber(
      period: period,
      lastWebQueryTime: UnitUtils.nowUnixTime,
      prizes: prizes.isNotEmpty ? prizes : null,
    );
    if (historyWhere >= 0) {
      history[historyWhere] = invoiceWinningNumber;
    } else {
      history.add(invoiceWinningNumber);
    }
    DatabaseServices.updateInvoiceWinningNumberList(history);
    return invoiceWinningNumber.prizes!=null ? invoiceWinningNumber : null;
  }

  static InvoiceEntityPrize? checkInvoice(InvoiceWinningNumber invoiceWinningNumber, String invoiceNumber) {
    final prizes = invoiceWinningNumber.prizes;
    if (invoiceNumber.length < 3 || prizes == null || prizes.isEmpty) return null;

    // 優先檢查大獎 (特別獎、特獎、頭獎)，因為這些是完整號碼比對
    final needCompleteComparison = const {InvoiceEntityPrize.special, InvoiceEntityPrize.grand, InvoiceEntityPrize.first};
    for (final value in needCompleteComparison) {
      final nums = prizes[value];
      if (nums == null) continue;
      for (final winningNum in nums) {
        if (invoiceNumber.endsWith(winningNum)) return value;
      }
    }

    // 檢查二獎到六獎 (比對頭獎末幾碼)
    // 由於一個號碼只能中一個獎，我們從大獎開始檢查，一旦中獎就返回
    final firstPrizeNums = prizes[InvoiceEntityPrize.first];
    if (firstPrizeNums != null) {
      for (var winningNum in firstPrizeNums) {
        final Map<InvoiceEntityPrize, String> table = {
          if (winningNum.length >= 7) InvoiceEntityPrize.second: winningNum.substring(winningNum.length - 7),
          if (winningNum.length >= 6) InvoiceEntityPrize.third: winningNum.substring(winningNum.length - 6),
          if (winningNum.length >= 5) InvoiceEntityPrize.fourth: winningNum.substring(winningNum.length - 5),
          if (winningNum.length >= 4) InvoiceEntityPrize.fifth: winningNum.substring(winningNum.length - 4),
          if (winningNum.length >= 3) InvoiceEntityPrize.sixth: winningNum.substring(winningNum.length - 3),
        };
        for (final entry in table.entries) {
          if (invoiceNumber.endsWith(entry.value)) return entry.key;
        }
      }
    }

    // 檢查增開六獎 (末3碼)
    final additionalSixthPrizeNums = prizes[InvoiceEntityPrize.additionalSixth];
    if (additionalSixthPrizeNums != null) {
      for (final winningNum in additionalSixthPrizeNums) {
        if (invoiceNumber.endsWith(winningNum)) return InvoiceEntityPrize.additionalSixth;
      }
    }

    return null;
  }
}