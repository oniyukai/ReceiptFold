import 'package:dio/dio.dart';
import 'package:html/dom.dart';
import 'package:html/parser.dart' show parse;
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/entity/invoice_prize.dart';
import 'package:receipt_fold/entity/period.dart';
import 'package:receipt_fold/services/drift_service.dart';
import 'package:receipt_fold/services/log_service.dart';
import 'package:xml/xml.dart';

const String _websiteLink = 'https://www.etax.nat.gov.tw/etw-main/ETW183W2_';
final RegExp _rLink = RegExp(
  r'^'
  '$_websiteLink'
  r'(\d{5})$',
);

class InvoicePrizeSearcher {
  static Map<String, InvoicePrizeAward>? _awardMapCache;
  static final _pendingRequests = <String, Future<List<InvoicePrize>>>{};
  static int _instanceCounter = 0;

  late final Dio _dio = Dio();

  InvoicePrizeSearcher() {
    _instanceCounter += 1;
  }

  void close() {
    if (_instanceCounter > 0) _instanceCounter -= 1;
    if (_instanceCounter <= 0) _awardMapCache = null;
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
    final awardMap =
        _awardMapCache ??
        <String, InvoicePrizeAward>{
          for (final award
              in await DriftService.appDb.keyValueStoreDao
                  .getExistDefault<List<InvoicePrizeAward>>(
                    .invoicePrizeAwardList,
                  ))
            award.invQuery: award,
        };
    _awardMapCache = awardMap;
    final String invQuery = period.invQuery;
    final InvoicePrizeAward? award = awardMap[invQuery];
    if (award != null) {
      if (award.prizes.isNotEmpty) return award;
      if (!_matchSpecifiedTimeInterval(award.lastWebQueryTime)) return null;
    }
    final prizes = <InvoicePrize>[];
    try {
      prizes.addAll(
        await _pendingRequests.putIfAbsent(
          invQuery,
          () => _requestPrizeAward(invQuery),
        ),
      );
    } catch (e) {
      LogService(
        '_requestPrizeAward($invQuery)',
        errorObject: e,
        instance: this,
      ).w();
    } finally {
      _pendingRequests.remove(invQuery);
    }
    if (awardMap[invQuery]?.prizes.isNotEmpty != true) {
      prizes.sort((a, b) => b.amount.compareTo(a.amount)); // 獎金高的放前面，同金額維持插入順序
      final invoicePrizeAward = awardMap[invQuery] = InvoicePrizeAward(
        invQuery: invQuery,
        lastWebQueryTime: UnitUtils.nowUnixTime,
        prizes: prizes,
      );
      await DriftService.appDb.keyValueStoreDao.upsert(
        .invoicePrizeAwardList,
        awardMap.values.toList(),
      );
      return invoicePrizeAward.prizes.isNotEmpty ? invoicePrizeAward : null;
    } else {
      return awardMap[invQuery];
    }
  }

  bool _matchSpecifiedTimeInterval(int unixMilliSec) {
    final int currentUnixMilliSec = UnitUtils.nowUnixTime;
    final int differenceInMilliSec = (unixMilliSec - currentUnixMilliSec).abs();
    const int targetDifferenceInSec = 1000;
    const int targetDifferenceInMilliSec = targetDifferenceInSec * 1000;
    return differenceInMilliSec >= targetDifferenceInMilliSec;
  }

  Future<List<InvoicePrize>> _requestPrizeAward(String invQuery) async {
    final errors = [];
    for (final (fnName, fnCall) in [
      ('_requestWebsite', _requestWebsite),
      ('_requestRSS', _requestRSS),
    ]) {
      try {
        final prizes = await fnCall(invQuery);
        if (prizes.isNotEmpty) return prizes;
      } catch (e) {
        LogService('$fnName($invQuery)', errorObject: e, instance: this).d();
        errors.add(e);
      }
    }
    throw Exception(errors);
  }

  Future<List<InvoicePrize>> _requestWebsite(String invQuery) async {
    final prizes = <InvoicePrize>[];
    final String fullUrl = '$_websiteLink$invQuery/';
    LogService('_requestWebsite...: $fullUrl', instance: this).d();
    final Response response = await _dio
        .get(fullUrl)
        .timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) {
      throw Exception('response.statusCode = ${response.statusCode}');
    }
    final Document document = parse(response.data);
    final Element? table = document.querySelector('table#tenMillionsTable');
    if (table == null) {
      throw Exception('Element "table#tenMillionsTable" does not exists.');
    }
    final Element? tbody = table.querySelector('tbody');
    if (tbody == null) {
      throw Exception('Element "tbody" does not exists.');
    }
    final List<Element> rows = tbody.querySelectorAll('tr');

    for (int i = 0; i < rows.length; i += 1) {
      if (i + 1 >= rows.length) continue; // 說明在下一行的 td 中，有 td 才表示這行確實有獎號資料
      final Element row = rows[i];
      final Element? th = row.querySelector('th[scope="row"]');
      final Element? td = row.querySelector('td');
      final Element nextRow = rows[i + 1];
      final Element? nextTd = nextRow.querySelector('td');
      if (th == null || td == null || nextTd == null) continue;
      prizes.addAll(
        _analyzePrize(
          th.text.trim(),
          td
              .querySelectorAll('div.col-12')
              .map((div) => div.text.trim())
              .toList(),
        ),
      );
    }
    return prizes;
  }

  Future<List<InvoicePrize>> _requestRSS(String invQuery) async {
    const String fullUrl = 'https://invoice.etax.nat.gov.tw/invoice.xml';
    LogService('_requestRSS...: $fullUrl', instance: this).d();
    final Response response = await _dio
        .get(fullUrl)
        .timeout(const Duration(seconds: 6));
    if (response.statusCode != 200) {
      throw Exception('response.statusCode = ${response.statusCode}');
    }
    final XmlDocument document = XmlDocument.parse(response.data.toString());
    final awardMap = <String, InvoicePrizeAward>{};

    for (final XmlElement eItem in document.findAllElements('item')) {
      final String description =
          eItem.findElements('description').firstOrNull?.innerText.trim() ?? '';
      final String link =
          eItem.findElements('link').firstOrNull?.innerText.trim() ?? '';
      final RegExpMatch? mLink = _rLink.firstMatch(link);
      if (mLink == null || description.isEmpty) continue;
      final Document dDescription = parse(description);
      final prizes = <InvoicePrize>[];

      for (final Element eP in dDescription.querySelectorAll('p')) {
        final List<String> textSplit = eP.text.split('：');
        if (textSplit.length != 2) continue;
        prizes.addAll(
          _analyzePrize(textSplit.first, textSplit.last.split('、')),
        );
      }

      awardMap[mLink.group(1)!] = InvoicePrizeAward(
        invQuery: mLink.group(1)!,
        lastWebQueryTime: UnitUtils.nowUnixTime,
        prizes: prizes,
      );
    }

    return awardMap[invQuery]?.prizes ?? const [];
  }

  List<InvoicePrize> _analyzePrize(String name, List<String> numbers) {
    name = name.trim();
    final prizes = <InvoicePrize>[];
    final int? amount = switch (name) {
      '特別獎' => 10000000,
      '特獎' => 2000000,
      '頭獎' => 200000,
      '增開六獎' => 200,
      _ => null,
    };
    if (amount == null) return prizes;
    for (final String number in numbers) {
      final String num = number.trim();
      if (num.isEmpty) continue;
      prizes.addAll([
        InvoicePrize(amount, name, num),
        if (name == '頭獎' && num.length >= 7) ...[
          InvoicePrize(40000, '二獎', num.substring(num.length - 7)),
          InvoicePrize(10000, '三獎', num.substring(num.length - 6)),
          InvoicePrize(4000, '四獎', num.substring(num.length - 5)),
          InvoicePrize(1000, '五獎', num.substring(num.length - 4)),
          InvoicePrize(200, '六獎', num.substring(num.length - 3)),
        ],
      ]);
    }
    return prizes;
  }
}
