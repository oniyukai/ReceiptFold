import 'package:dio/dio.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/entity/invoice_prize.dart';
import 'package:receipt_fold/entity/period.dart';
import 'package:receipt_fold/modules/drift_services.dart';
import 'package:receipt_fold/modules/log_service.dart';

class InvoicePrizeSearcher {
  static List<InvoicePrizeAward>? _awardListCache;

  static int _instanceCounter = 0;

  late final Dio _dio = Dio();

  InvoicePrizeSearcher() {
    _instanceCounter += 1;
  }

  void close() {
    if (_instanceCounter > 0) _instanceCounter -= 1;
    if (_instanceCounter <= 0) _awardListCache = null;
    _dio.close();
  }

  Future<InvoicePrizeAward?> getByDistance(int distance) async {
    assert(distance >= 0);
    Period nowPeriod = Period(DateTime.now()).invPrevious;
    InvoicePrizeAward? lastPrizeAward;
    for (int i = 0; i < 2; i += 1) {
      lastPrizeAward = await getPrizeAward(nowPeriod);
      if (lastPrizeAward != null) break;
      nowPeriod = nowPeriod.invPrevious;
    }
    if (lastPrizeAward == null) return null;
    for (int i = 0; i < distance; i += 1) {
      nowPeriod = nowPeriod.invPrevious;
    }
    return await getPrizeAward(nowPeriod);
  }

  Future<InvoicePrizeAward?> getPrizeAward(Period period) async {
    final String invQuery = period.invQuery;
    final List<InvoicePrizeAward> awardList =
        _awardListCache ??
        await DriftServices.appDb.keyValueStoreDao.getExistDefault(
          .invoicePrizeAwardList,
        );
    _awardListCache = awardList;
    final int historyWhere = awardList.indexWhere(
      (item) => item.invQuery == invQuery,
    );
    if (historyWhere >= 0) {
      final InvoicePrizeAward result = awardList[historyWhere];
      if (result.prizes.isNotEmpty) return result;
      // 如果上次查詢未冷卻完畢不再查詢網頁
      if (!_matchSpecifiedTimeInterval(result.lastWebQueryTime)) return null;
    }

    final prizes = <InvoicePrize>[];
    try {
      prizes.addAll(await _requestPrizeAward(invQuery));
    } on DioException catch (e) {
      LogService(
        '_requestPrizeAward DioException.',
        errorObject: e,
        instance: this,
      ).d();
    } catch (e) {
      LogService(
        '_requestPrizeAward exception.',
        errorObject: e,
        instance: this,
      ).w();
    }

    // 獎金高的放前面，同金額維持插入順序
    prizes.sort((a, b) => b.amount.compareTo(a.amount));

    final InvoicePrizeAward invoicePrizeAward = InvoicePrizeAward(
      invQuery: invQuery,
      lastWebQueryTime: UnitUtils.nowUnixTime,
      prizes: prizes,
    );
    if (historyWhere >= 0) {
      awardList[historyWhere] = invoicePrizeAward;
    } else {
      awardList.add(invoicePrizeAward);
    }
    await DriftServices.appDb.keyValueStoreDao.upsert(
      .invoicePrizeAwardList,
      awardList,
    );
    return invoicePrizeAward.prizes.isNotEmpty ? invoicePrizeAward : null;
  }

  bool _matchSpecifiedTimeInterval(int unixMillisec) {
    final int currentUnixMillisec = UnitUtils.nowUnixTime;
    final int differenceInMillisec = (unixMillisec - currentUnixMillisec).abs();
    const int targetDifferenceInSec = 1000;
    const int targetDifferenceInMillisec = targetDifferenceInSec * 1000;
    return differenceInMillisec >= targetDifferenceInMillisec;
  }

  Future<List<InvoicePrize>> _requestPrizeAward(String invQuery) async {
    final prizes = <InvoicePrize>[];
    final String fullUrl =
        'https://www.etax.nat.gov.tw/etw-main/ETW183W2_$invQuery/';
    LogService('_requestPrizeAward...: $fullUrl', instance: this).d();
    final Response response = await _dio
        .get(fullUrl)
        .timeout(const Duration(seconds: 4));
    if (response.statusCode != 200) {
      LogService('response.statusCode != 200.', instance: this).d();
      return prizes;
    }
    final Document document = parse(response.data);
    final Element? table = document.querySelector('table#tenMillionsTable');
    if (table == null) {
      LogService(
        'Element "table#tenMillionsTable" does not exists.',
        instance: this,
      ).w();
      return prizes;
    }
    final Element? tbody = table.querySelector('tbody');
    if (tbody == null) {
      LogService('Element "tbody" does not exists.', instance: this).w();
      return prizes;
    }
    final List<Element> rows = tbody.querySelectorAll('tr');

    for (int i = 0; i < rows.length; i += 1) {
      final Element row = rows[i];
      final Element? th = row.querySelector('th[scope="row"]');
      final Element? td = row.querySelector('td');
      if (th == null || td == null) continue;

      final String headerText = th.text.trim();
      final int? amount = switch (headerText) {
        '特別獎' => 10000000,
        '特獎' => 2000000,
        '頭獎' => 200000,
        '增開六獎' => 200,
        _ => null,
      };
      if (amount == null) continue;

      final List<String> numbers = td
          .querySelectorAll('div.col-12')
          .map((div) => div.text.trim())
          .toList();
      if (i + 1 >= rows.length) continue; // 說明在下一行的 td 中，有 td 才表示這行確實有獎號資料

      final Element nextRow = rows[i + 1];
      final Element? nextTd = nextRow.querySelector('td');
      if (nextTd == null) continue;

      for (final number in numbers) {
        prizes.add(InvoicePrize(amount, headerText, number));
        if (headerText == '頭獎') {
          // 頭獎號碼可衍生出二獎～六獎（依末幾碼比對）
          prizes.addAll([
            if (number.length >= 7)
              InvoicePrize(40000, '二獎', number.substring(number.length - 7)),
            if (number.length >= 6)
              InvoicePrize(10000, '三獎', number.substring(number.length - 6)),
            if (number.length >= 5)
              InvoicePrize(4000, '四獎', number.substring(number.length - 5)),
            if (number.length >= 4)
              InvoicePrize(1000, '五獎', number.substring(number.length - 4)),
            if (number.length >= 3)
              InvoicePrize(200, '六獎', number.substring(number.length - 3)),
          ]);
        }
      }
      i += 1; // 跳過下一行（說明行），因為已經處理
    }
    return prizes;
  }
}
