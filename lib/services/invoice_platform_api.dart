import 'dart:convert';
import 'dart:math';
import 'dart:ui';

import 'package:csv/csv.dart';
import 'package:drift/drift.dart';
import 'package:intl/intl.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/entity/drift/drift_database.dart';
import 'package:receipt_fold/entity/drift/receipt.dart';
import 'package:receipt_fold/entity/invoice_carrier.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/services/log_service.dart';
import 'package:webview_all/webview_all.dart';

const String _einvoiceLoginUrl =
    'https://www.einvoice.nat.gov.tw/accounts/login/mw';
const String _authCaptureChannelName = 'AuthCapture';

/// 替代 flutter_inappwebview 的 shouldInterceptRequest
const String _authCaptureUserScriptSource =
    '''
(function () {
  var CHANNEL = '$_authCaptureChannelName';
  function notifyAuth(auth) {
    if (!auth || typeof auth !== 'string' || auth.length === 0) return;
    try {
      globalThis.__einvoiceAuth = auth;
    } catch (e) {}
    try {
      if (globalThis[CHANNEL] && typeof globalThis[CHANNEL].postMessage === 'function') {
        globalThis[CHANNEL].postMessage(auth);
      }
    } catch (e) {}
  }
  function authFromHeaders(headers) {
    if (!headers) return null;
    try {
      if (typeof Headers !== 'undefined' && headers instanceof Headers && headers.get) {
        var h = headers.get('Authorization');
        if (h) return h;
      }
    } catch (e) {}
    if (typeof headers !== 'object') return null;
    if (Array.isArray(headers)) {
      for (var i = 0; i < headers.length; i++) {
        var pair = headers[i];
        if (pair && pair.length >= 2 && String(pair[0]).toLowerCase() === 'authorization') {
          return pair[1];
        }
      }
    } else {
      for (var key in headers) {
        if (Object.prototype.hasOwnProperty.call(headers, key) && String(key).toLowerCase() === 'authorization') {
          return headers[key];
        }
      }
    }
    return null;
  }
  function patchFetch() {
    if (window.__einvoiceFetchPatched || typeof window.fetch !== 'function') return;
    var originalFetch = window.fetch;
    window.fetch = function (input, init) {
      var auth = authFromHeaders(init && init.headers);
      if (!auth && input && input.headers) auth = authFromHeaders(input.headers);
      notifyAuth(auth);
      return originalFetch.apply(this, arguments);
    };
    window.__einvoiceFetchPatched = true;
  }
  function patchXhr() {
    if (window.__einvoiceXhrPatched || typeof window.XMLHttpRequest === 'undefined') return;
    var originalSet = XMLHttpRequest.prototype.setRequestHeader;
    XMLHttpRequest.prototype.setRequestHeader = function (name, value) {
      if (String(name).toLowerCase() === 'authorization') notifyAuth(value);
      return originalSet.apply(this, arguments);
    };
    window.__einvoiceXhrPatched = true;
  }
  patchFetch();
  patchXhr();
})();
''';

double? _tryDouble(String text) =>
    NumberFormat.decimalPattern('en').tryParse(text)?.toDouble();

class InvoicePlatformApi {
  static const int maxQueryMonths = 8;

  late final WebViewController controller;
  String? _auth;

  bool get isInitialized => _auth != null;

  Future<void> init({
    required VoidCallback onAuthCaptured,
    required VoidCallback onPageFinished,
  }) async {
    controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted);
    if (await controller.isUserScriptInjectionSupported(
      WebViewUserScriptInjectionTime.documentStart,
    )) {
      await controller.addUserScript(
        const WebViewUserScript(source: _authCaptureUserScriptSource),
      );
    }
    await controller.addJavaScriptChannel(
      _authCaptureChannelName,
      onMessageReceived: (message) {
        _auth = message.message;
        onAuthCaptured();
      },
    );
    await controller.setNavigationDelegate(
      NavigationDelegate(onPageFinished: (_) => onPageFinished()),
    );
    await controller.loadRequest(Uri.parse(_einvoiceLoginUrl));
  }

  void close() {
    _auth = null;
  }

  OriginStatus? _analyzeOriginStatus(
    String? extStatus,
    String? donateMark,
    String? invoiceStrStatus,
  ) {
    if (extStatus == '0') {
      return OriginStatus.platformUnverified;
    } else if (extStatus == '1') {
      return OriginStatus.platformInvalidated;
    } else if (extStatus == '2' && donateMark == '1') {
      return OriginStatus.platformDonated;
    } else if (extStatus == '2') {
      return invoiceStrStatus == null
          ? OriginStatus.platformValidated
          : OriginStatus.platformConfirmed;
    }
    return null;
  }

  Future<String> _fetch({
    required String url,
    Map<String, String?> headers = const {},
    dynamic body,
  }) {
    return controller
        .callAsyncJavaScript(
          '''
        const response = await fetch(url, {
          method: 'POST',
          headers: headers,
          body: JSON.stringify(body)
        });
        return await response.text();
      ''',
          arguments: {'url': url, 'headers': headers, 'body': body},
        )
        .timeout(const Duration(seconds: 16))
        .then((value) => value.toString());
  }

  Future<String> _fetchInvoiceResData(String token) {
    return _fetch(
      url: 'https://service-mc.einvoice.nat.gov.tw/btc/cloud/api/common/getCarrierInvoiceData',
      body: token,
    );
  }

  Future<String> _fetchInvoiceResDetail(String token) {
    return _fetch(
      url: 'https://service-mc.einvoice.nat.gov.tw/btc/cloud/api/common/getCarrierInvoiceDetail?page=0&size=100',
      body: token,
    );
  }

  Receipt _parseInvoiceResData(String resData, Receipt receipt) {
    final jsonData = jsonDecode(resData);
    return receipt.copyWith(
      originStatus: _analyzeOriginStatus(
        jsonData['extStatus'],
        jsonData['donateMark'],
        jsonData['invoiceStrStatus'],
      ),
      issuedAt: DateTime.tryParse(jsonData['invoiceInstantDate'] ?? ''),
      totalAmount: _tryDouble(jsonData['totalAmount'] ?? ''),
      randomNumber: Value.absentIfNull(
        Utils.noEmptyStr(jsonData['randomNumber']),
      ),
      carrierId2: Value.absentIfNull(Utils.noEmptyStr(jsonData['carrierId2'])),
      sellerName: Value.absentIfNull(Utils.noEmptyStr(jsonData['sellerName'])),
      sellerTaxId: Value.absentIfNull(Utils.noEmptyStr(jsonData['sellerId'])),
      sellerAddress: Value.absentIfNull(
        Utils.noEmptyStr(jsonData['sellerAddress']),
      ),
      sellerRemark: Value.absentIfNull(
        Utils.noEmptyStr(jsonData['mainRemark']),
      ),
    );
  }

  ReceiptRecord _parseInvoiceResDetail(String resDetail, Receipt receipt) {
    final jsonDetails = jsonDecode(resDetail)['content'];
    final products = <ReceiptProduct>[];
    double totalAmount = 0.0;
    for (final jsonDetail in jsonDetails) {
      final double amount = _tryDouble(jsonDetail['amount'] ?? '') ?? 0.0;
      totalAmount += amount;
      products.add(
        ReceiptProduct(
          modified: DateTime.now(),
          uuid: UuidMixin.v7.generate(),
          receiptUuid: receipt.uuid,
          sequence: int.tryParse(jsonDetail['sequenceNumber'] ?? '') ?? 0,
          description: jsonDetail['item'] ?? StaticString.nullString,
          unitPrice: _tryDouble(jsonDetail['unitPrice'] ?? '') ?? 0.0,
          quantity: _tryDouble(jsonDetail['quantity'] ?? '') ?? 0.0,
          amount: amount,
        ),
      );
    }
    return (receipt.copyWith(totalAmount: totalAmount), products);
  }

  Future<void> fillLoginForm(String? phone, String? password) async {
    final url = await controller.currentUrl() ?? '';
    if (!url.startsWith(_einvoiceLoginUrl)) return;
    await controller.runJavaScript('''
      (function() {
        function setElementValue(id, value) {
          const el = document.getElementById(id);
          if (el) {
            el.value = value;
            el.dispatchEvent(new Event('input', { bubbles: true })); // 觸發 input 事件，讓網頁框架（如 Angular/Vue）知道值變了
            el.dispatchEvent(new Event('change', { bubbles: true })); // 觸發 change 事件
            el.dispatchEvent(new Event('blur', { bubbles: true })); // 觸發打字完成後的 blur 事件
          }
        }

        setElementValue('mobile_phone', '${phone ?? ''}');
        setElementValue('password', '${password ?? ''}');
      })();
    ''');
  }

  /// 載具清單, 只打算取最多 100 個
  Future<List<InvoiceCarrier>> fetchCarrierList() async {
    LogService('fetchCarrierList...', instance: this).d();
    final fListRes = _fetch(
      url: 'https://service-mc.einvoice.nat.gov.tw/btc/cloud/api/btc503w/getCarrierList',
      headers: {'Authorization': _auth},
    );
    final fConRes = _fetch(
      url: 'https://service-m.einvoice.nat.gov.tw/btc/portal/api/btc504w/queryCarrierConsolidationInformation?page=0&size=100',
      headers: {'Authorization': _auth},
    );
    final carrierMap = <String, InvoiceCarrier>{};
    final contents = [
      ...jsonDecode(await fListRes),
      if ((await fConRes).trim().isNotEmpty)
        ...jsonDecode(await fConRes)['content'],
    ];
    for (final content in contents) {
      final old = carrierMap.remove(content['carrierId2']);
      carrierMap[content['carrierId2']] = InvoiceCarrier(
        carrierId2: content['carrierId2'] ?? old?.carrierId2,
        name: content['carrierName'] ?? old?.name,
        status: CarrierStatus.platform,
        carrierType: Utils.noEmptyStr(content['cardCode']) ?? old?.carrierType,
        carrierTypeName:
            Utils.noEmptyStr(content['codeName']) ?? old?.carrierTypeName,
        fetchJson: jsonEncode(content),
      );
    }
    return carrierMap.values.toList();
  }

  /// 中獎查詢
  Future<Map<Receipt, List<ReceiptProduct>>> fetchAwardList() async {
    LogService('fetchAwardList...', instance: this).d();
    final List jsonPeriod = jsonDecode(
      await _fetch(
        url: 'https://service-mc.einvoice.nat.gov.tw/btc/cloud/api/common/getInvPeriodList',
      ),
    );
    final periodNames = jsonPeriod.take(3).map((e) => e['awardInvoicePeriod']);
    LogService('periodNames = $periodNames', instance: this).d();
    final responses = await Future.wait(
      periodNames.map(
        (periodName) =>
            _fetch(
              url: 'https://service-mc.einvoice.nat.gov.tw/btc/cloud/api/btc503w/btc503wGetSearchCarrierInvoiceListJWT',
              headers: {
                'Authorization': _auth,
                'Content-Type': 'application/json',
              },
              body: {'awardDate': periodName, 'isSearchAll': 'true'},
            ).then(
              (periodJwt) => _fetch(
                url: 'https://service-mc.einvoice.nat.gov.tw/btc/cloud/api/btc503w/getCarrierAwardInvoiceList?page=0&size=100',
                headers: {'Authorization': _auth},
                body: periodJwt.trim().replaceAll('"', ''),
              ),
            ),
      ),
    );

    final result = <Receipt, List<ReceiptProduct>>{};
    for (final awardsRes in responses) {
      if (awardsRes.trim().isEmpty) continue;
      final jsonAwards = jsonDecode(awardsRes)['content'];
      for (final jsonAward in jsonAwards) {
        final fResData = _fetchInvoiceResData(jsonAward['token']);
        final fResDetail = _fetchInvoiceResDetail(jsonAward['token']);
        final ReceiptRecord receiptRecord = _parseInvoiceResDetail(
          await fResDetail,
          _parseInvoiceResData(
            await fResData,
            Receipt(
              modified: DateTime.now(),
              uuid: UuidMixin.v7.generate(),
              originStatus: OriginStatus.platformConfirmed,
              issuedAt: DateTime.parse(jsonAward['invoiceDate']),
              totalAmount: _tryDouble(jsonAward['totalAmount'] ?? '') ?? 0.0,
              invoiceNumber: Utils.noEmptyStr(jsonAward['invNum']),
              carrierName: Utils.noEmptyStr(jsonAward['carrierName']),
              carrierType: Utils.noEmptyStr(jsonAward['cardCode']),
              carrierId2: Utils.noEmptyStr(jsonAward['carrierId2']),
              prizeName: Utils.noEmptyStr(jsonAward['prizeName']),
              prizeAmount: _tryDouble(jsonAward['prizeAmt'] ?? ''),
              invoiceJsonData: await fResData,
              invoiceJsonDetail: await fResDetail,
              invoiceJsonAward: jsonEncode(jsonAward),
            ),
          ),
        );
        result[receiptRecord.receipt] = receiptRecord.products;
      }
    }
    return result;
  }

  /// 備份發票
  Future<Map<Receipt, List<ReceiptProduct>>> fetchInvoiceList(
    int months,
  ) async {
    LogService('fetchInvoiceList...', instance: this).d();
    final DateTime nowUtc = DateTime.timestamp();
    final DateFormat utcFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");

    final jwtResponses = await Future.wait(
      List.generate(min(months, maxQueryMonths), (i) {
        final DateTime taipeiTime = nowUtc.add(const Duration(hours: 8));
        final DateTime start = DateTime.utc(
          taipeiTime.year,
          taipeiTime.month - i,
          1,
        ).subtract(const Duration(hours: 8));
        final DateTime end = DateTime.utc(
          taipeiTime.year,
          taipeiTime.month - i + 1,
          1,
        ).subtract(const Duration(hours: 8, seconds: 1));
        return (
          startStr: utcFormat.format(start),
          endStr: utcFormat.format(end.isAfter(nowUtc) ? nowUtc : end),
        );
      }).map(
        (value) => _fetch(
          url: 'https://service-mc.einvoice.nat.gov.tw/btc/cloud/api/btc502w/getSearchCarrierInvoiceListJWT',
          headers: {'Authorization': _auth, 'Content-Type': 'application/json'},
          body: {
            'searchStartDate': value.startStr,
            'searchEndDate': value.endStr,
            'invoiceStatus': 'all',
            'isSearchAll': 'true',
          },
        ).then((jwtRes) => jwtRes.trim().replaceAll('"', '')),
      ),
    );

    final jsonsInvoices = [];
    for (final jwtResponse in jwtResponses) {
      // 這裡就不特別採用並發了, 減輕 API 壓力
      for (int i = 0; i < 4; i += 1) {
        // 限制每月 400張 發票, 超過需求的人每月在每 400張 前自行觸發即可
        final invoicesRes = await _fetch(
          url:
              'https://service-mc.einvoice.nat.gov.tw/btc/cloud/api/btc502w/searchCarrierInvoice?page=$i&size=100',
          headers: {'Authorization': _auth, 'Content-Type': 'application/json'},
          body: {'token': jwtResponse},
        );
        if (invoicesRes.trim().isEmpty) break;
        final jsonRes = jsonDecode(invoicesRes);
        jsonsInvoices.add(jsonRes['content']);
        if (jsonRes['last'] != false) break;
      }
    }

    final result = <Receipt, List<ReceiptProduct>>{};
    for (final jsonInvoice in jsonsInvoices.expand(
      (jsonInvoices) => jsonInvoices,
    )) {
      final fResData = _fetchInvoiceResData(jsonInvoice['token']);
      final fResDetail = _fetchInvoiceResDetail(jsonInvoice['token']);
      final ReceiptRecord receiptRecord = _parseInvoiceResDetail(
        await fResDetail,
        _parseInvoiceResData(
          await fResData,
          Receipt(
            modified: DateTime.now(),
            uuid: UuidMixin.v7.generate(),
            originStatus:
                _analyzeOriginStatus(
                  jsonInvoice['extStatus'],
                  jsonInvoice['donateMark'],
                  jsonInvoice['invoiceStrStatus'],
                ) ??
                OriginStatus.platformUnverified,
            issuedAt: DateTime.parse(jsonInvoice['invoiceDate']),
            // API totalAmount 特別回傳的是 int
            totalAmount:
                _tryDouble(jsonInvoice['totalAmount'].toString()) ?? 0.0,
            invoiceNumber: Utils.noEmptyStr(jsonInvoice['invoiceNumber']),
            carrierName: Utils.noEmptyStr(jsonInvoice['carrierName']),
            carrierType: Utils.noEmptyStr(jsonInvoice['carrierType']),
            carrierId2: Utils.noEmptyStr(jsonInvoice['carrierId2']),
            sellerName: Utils.noEmptyStr(jsonInvoice['sellerName']),
            invoiceJsonData: await fResData,
            invoiceJsonDetail: await fResDetail,
            invoiceJsonSummary: jsonEncode(jsonInvoice),
          ),
        ),
      );
      result[receiptRecord.receipt] = receiptRecord.products;
    }
    return result;
  }

  Map<Receipt, List<ReceiptProduct>> decodeImportCSV(String csvString) {
    final invMap = <String, ReceiptRecord>{};
    for (final csvRow in Csv(fieldDelimiter: '|').decode(csvString)) {
      final List<String> stringList = csvRow.map((e) => e.toString()).toList();
      final String? rowType = stringList.firstOrNull;
      if (rowType == 'M') {
        final String invoiceNumber = stringList[6];
        final String dateString = stringList[3];
        invMap[invoiceNumber] = (
          Receipt(
            modified: DateTime.now(),
            uuid: UuidMixin.v7.generate(),
            originStatus: OriginStatus.deviceImport,
            issuedAt: DateTime.utc(
              int.parse(dateString.substring(0, 4)),
              int.parse(dateString.substring(4, 6)),
              int.parse(dateString.substring(6, 8)),
            ).subtract(const Duration(hours: 8)),
            totalAmount: _tryDouble(stringList[7]) ?? 0.0,
            carrierId2: Utils.noEmptyStr(stringList[2]),
            sellerTaxId: Utils.noEmptyStr(stringList[4]),
            sellerName: Utils.noEmptyStr(stringList[5]),
            invoiceNumber: Utils.noEmptyStr(invoiceNumber),
          ),
          [],
        );
      } else if (rowType == 'D') {
        final String invoiceNumber = stringList[1];
        final double amount = _tryDouble(stringList[2]) ?? 0.0;
        final entry = invMap[invoiceNumber];
        entry?.products.add(
          ReceiptProduct(
            modified: DateTime.now(),
            uuid: UuidMixin.v7.generate(),
            receiptUuid: entry.receipt.uuid,
            sequence: entry.products.length + 1,
            description: stringList[3],
            unitPrice: amount,
            quantity: 1.0,
            amount: amount,
          ),
        );
      }
    }
    return Map.fromEntries(invMap.values.map((e) => e.toEntry()));
  }
}
