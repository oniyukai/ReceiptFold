import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:intl/intl.dart';
import 'package:receipt_fold/entity/drift/drift_database.dart';
import 'package:receipt_fold/entity/drift/receipt.dart';
import 'package:receipt_fold/entity/invoice_carrier.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/pages/menu_settings/page_logs_view.dart';

class InvoicePlatformApi {
  InAppWebViewController? _controller;
  String? _auth;

  set controller(InAppWebViewController value) => _controller = value;
  set auth(String? value) => _auth = value ?? _auth;

  bool get isInitialized => _controller != null && _auth != null;

  void _log(String msg) => LogService(msg, instance: this).d();

  Future<dynamic> _fetch(String url, Map<String, String?> headers, dynamic body) {
    if (_controller == null) throw Exception('InAppWebViewController 尚未被附值');
    return _controller!.callAsyncJavaScript(
      functionBody: '''
        const response = await fetch(url, {
          method: 'POST', 
          headers: headers, 
          body: JSON.stringify(body)
        }); 
        return await response.text();
      ''',
      arguments: {'url': url, 'headers': headers, 'body': body},
    ).then((value) => value?.value);
  }

  Future<String> _fetchInvoiceResData(String cdsMc, String token) async {
    return (await _fetch(
      'https://service-mc.einvoice.nat.gov.tw/btc/cloud/api/common/getCarrierInvoiceData',
      {'Authorization': _auth, 'x-cds-btc': cdsMc, 'Content-Type': 'application/json'},
      token,
    )).toString();
  }

  Future<String> _fetchInvoiceResDetail(String cdsMc, String token) async {
    return (await _fetch(
      'https://service-mc.einvoice.nat.gov.tw/btc/cloud/api/common/getCarrierInvoiceDetail?page=0&size=100',
      {'Authorization': _auth, 'x-cds-btc': cdsMc, 'Content-Type': 'application/json'},
      token,
    )).toString();
  }

  Receipt _parseInvoiceResData(String resData, Receipt receipt) {
    final jsonData = jsonDecode(resData);
    final extStatus = jsonData['extStatus'];
    OriginStatus? originStatus;
    if (extStatus == '0') {
      originStatus = .platformUnconfirmed;
    } else if (extStatus == '1') {
      originStatus = .platformInvalidated;
    } else if (extStatus == '2' && jsonData['donateMark'] == '1') {
      originStatus = .platformDonated;
    } else if (extStatus == '2') {
      originStatus = jsonData['invoiceStrStatus'] == null ? .platformConfirmed : .platformConfirmedNotDonated;
    }
    return receipt.copyWith(
      originStatus: originStatus,
      issuedAt: DateTime.tryParse(jsonData['invoiceInstantDate'] ?? ''),
      totalAmount: double.tryParse(jsonData['totalAmount'] ?? ''),
      randomNumber: Value.absentIfNull(jsonData['randomNumber']),
      carrierId2: Value.absentIfNull(jsonData['carrierId2']),
      sellerName: Value.absentIfNull(jsonData['sellerName']),
      sellerTaxId: Value.absentIfNull(jsonData['sellerId']),
      sellerAddress: Value.absentIfNull(jsonData['sellerAddress']),
      sellerRemark: Value.absentIfNull(jsonData['mainRemark']),
    );
  }

  MapEntry<Receipt, List<ReceiptProduct>> _parseInvoiceResDetail(String resDetail, Receipt receipt) {
    final jsonDetails = jsonDecode(resDetail)['content'];
    final products = <ReceiptProduct>[];
    double totalAmount = 0.0;
    for (final jsonDetail in jsonDetails) {
      final double unitPrice = double.tryParse(jsonDetail['unitPrice'] ?? '') ?? 0.0;
      final double quantity = double.tryParse(jsonDetail['quantity'] ?? '') ?? 0.0;
      totalAmount += unitPrice * quantity;
      products.add(ReceiptProduct(
        modified: .now(),
        uuid: UuidMixin.v7.generate(),
        receiptUuid: receipt.uuid,
        sequence: int.tryParse(jsonDetail['sequenceNumber'] ?? '') ?? 0,
        description: jsonDetail['item'] ?? StaticString.nullString,
        unitPrice: unitPrice,
        quantity: quantity,
        amount: unitPrice * quantity,
      ));
    }
    return MapEntry(receipt.copyWith(totalAmount: totalAmount), products);
  }

  Future<void> fillLoginForm(String? phone, String? password) async {
    await _controller?.evaluateJavascript(source: '''
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
  Future<List<InvoiceCarrier>> fetchCarrierConsolidation(String cdsM) async {
    LogService('fetchCarrierList...', instance: this).d();
    final json = jsonDecode((await _fetch(
      'https://service-m.einvoice.nat.gov.tw/btc/portal/api/btc504w/queryCarrierConsolidationInformation?page=0&size=100',
      {'Authorization': _auth, 'x-cds-btc': cdsM, 'Content-Type': 'application/json'},
      {},
    )).toString());
    return [
      for (final content in json['content'])
        InvoiceCarrier(
          carrierId2: content['carrierId2'],
          name: content['carrierName'],
          status: .platform,
          carrierType: content['cardCode'],
          carrierTypeName: content['codeName'],
          consolidationJson: jsonEncode(content),
        ),
    ];
  }

  /// 中獎查詢
  Future<Map<Receipt, List<ReceiptProduct>>> fetchAwardList(String cdsMc) async {
    LogService('fetchAwardList...', instance: this).d();
    final List jsonPeriod = jsonDecode((await _fetch(
      'https://service-mc.einvoice.nat.gov.tw/btc/cloud/api/common/getInvPeriodList',
      {'Authorization': _auth, 'x-cds-btc': cdsMc, 'Content-Type': 'application/json'},
      {},
    )).toString());
    final periodNames = jsonPeriod.take(3).map((e) => e['awardInvoicePeriod']);
    LogService('getAwardPeriod = $periodNames', instance: this).d();
    final jsonsAwards = await Future.wait(
      periodNames.map((periodName) => _fetch(
        'https://service-mc.einvoice.nat.gov.tw/btc/cloud/api/btc503w/btc503wGetSearchCarrierInvoiceListJWT',
        {'Authorization': _auth, 'x-cds-btc': cdsMc, 'Content-Type': 'application/json'},
        {'awardDate': periodName.toString(), 'isSearchAll': 'true'},
      ).then((periodJwt) => _fetch(
        'https://service-mc.einvoice.nat.gov.tw/btc/cloud/api/btc503w/getCarrierAwardInvoiceList?page=0&size=100',
        {'Authorization': _auth, 'x-cds-btc': cdsMc, 'Content-Type': 'application/json'},
        periodJwt.toString().trim().replaceAll('"', ''),
      ).then((awardsRes) => jsonDecode(
        awardsRes.toString(),
      )))),
    );

    final result = <Receipt, List<ReceiptProduct>>{};
    for (final jsonAwards in jsonsAwards) {
      final awards = jsonAwards['content'];
      if (awards == null) continue;
      for (final award in awards) {
        final fResData = _fetchInvoiceResData(cdsMc, award['token']);
        final fResDetail = _fetchInvoiceResDetail(cdsMc, award['token']);
        final MapEntry<Receipt, List<ReceiptProduct>> entry = _parseInvoiceResDetail(
          await fResDetail,
          _parseInvoiceResData(
            await fResData,
            Receipt(
              modified: .now(),
              uuid: UuidMixin.v7.generate(),
              originStatus: .platformConfirmedNotDonated,
              issuedAt: .now(),
              totalAmount: double.tryParse(award['totalAmount'] ?? '') ?? 0.0,
              invoiceNumber: award['invNum'],
              carrierName: award['carrierName'],
              carrierType: award['cardCode'],
              carrierId2: award['carrierId2'],
              prizeName: award['prizeName'],
              prizeAmount: double.tryParse(award['prizeAmt'] ?? ''),
              invoiceJsonData: await fResData,
              invoiceJsonDetail: await fResDetail,
              invoiceJsonAward: jsonEncode(award),
            ),
          ),
        );
        result[entry.key] = entry.value;
      }
    }
    return result;

    // for (final jsonPeriod in jsonPeriod.take(3)) {
    //   final String periodName = jsonPeriod['awardInvoicePeriod'];
    //   _log('  🔎 查詢期別: $periodName');
    //   final jwtResponse = await _fetch(
    //     'https://service-mc.einvoice.nat.gov.tw/btc/cloud/api/btc503w/btc503wGetSearchCarrierInvoiceListJWT',
    //     {'Authorization': _auth, 'x-cds-btc': cdsMc, 'Content-Type': 'application/json'},
    //     {'awardDate': periodName, 'isSearchAll': 'true'},
    //   );
    //   final String token = jwtResponse.toString().trim().replaceAll('"', '');
    //   final awardRes = await _fetch( // json string
    //     'https://service-mc.einvoice.nat.gov.tw/btc/cloud/api/btc503w/getCarrierAwardInvoiceList?page=0&size=100',
    //     {'Authorization': _auth, 'x-cds-btc': cdsMc, 'Content-Type': 'application/json'},
    //     token,
    //   );
    //   _log('✅ $periodName 下載成功 $awardRes');
    //   for (final content in jsonDecode(awardRes.toString())['content']) {
    //     print(await _fetchInvoiceJsonData(cdsMc, content['token']));
    //     print(await _fetchInvoiceJsonDetail(cdsMc, content['token']));
    //   }
    // }
  }

  /// 備份發票
  Future<void> fetchInvoiceList(String cdsMc) async {
    LogService('fetchInvoiceList...', instance: this).d();
    DateTime now = DateTime.now();
    final utcFormat = DateFormat("yyyy-MM-dd'T'HH:mm:ss.SSS'Z'");

    for (int i = 0; i < 8; i++) {
      DateTime firstDayOfMonth = DateTime(now.year, now.month - i, 1);
      String monthLabel = DateFormat('yyyy-MM').format(firstDayOfMonth);

      DateTime startDt = firstDayOfMonth.subtract(const Duration(hours: 8));
      DateTime lastDayOfMonth = DateTime(firstDayOfMonth.year, firstDayOfMonth.month + 1, 1).subtract(const Duration(milliseconds: 1));
      if (lastDayOfMonth.isAfter(now)) lastDayOfMonth = now;
      DateTime endDt = lastDayOfMonth.subtract(const Duration(hours: 8));

      String startStr = utcFormat.format(startDt);
      String endStr = utcFormat.format(endDt);

      _log('[$monthLabel] 正在查詢...');

      try {
        // 1. 獲取 JWT
        final resJwtRaw = await _fetch(
          'https://service-mc.einvoice.nat.gov.tw/btc/cloud/api/btc502w/getSearchCarrierInvoiceListJWT',
          {'Authorization': _auth, 'x-cds-btc': cdsMc, 'Content-Type': 'application/json'},
          {
            'searchStartDate': startStr,
            'searchEndDate': endStr,
            'invoiceStatus': 'all',
            'isSearchAll': 'true'
          },
        );

        if (resJwtRaw == null || resJwtRaw.toString().startsWith('ERROR')) {
          _log('   ⚠️ 權限獲取失敗: $resJwtRaw');
          continue;
        }

        // 處理 Token (去除可能的多餘引號)
        String searchToken = resJwtRaw.toString().trim().replaceAll('"', '');

        // 2. 獲取列表
        final resListRaw = await _fetch(
          'https://service-mc.einvoice.nat.gov.tw/btc/cloud/api/btc502w/searchCarrierInvoice?page=0&size=100',
          {
            'Authorization': _auth,
            'x-cds-btc': cdsMc,
            'Content-Type': 'application/json'
          },
          {'token': searchToken},
        );

        // --- 核心修正點：智能解析回傳值 ---
        Map<String, dynamic> data;
        if (resListRaw is Map) {
          // 如果已經是 Map 就直接用
          data = Map<String, dynamic>.from(resListRaw);
        } else if (resListRaw is String) {
          // 如果是字串再解碼
          data = jsonDecode(resListRaw);
        } else {
          _log('   ❌ 未知回傳格式: ${resListRaw.runtimeType}');
          continue;
        }

        List invoices = data['content'] ?? [];
        if (invoices.isEmpty) {
          _log('   ☁️ 此月份無發票資料');
        } else {
          _log('   ✅ 發現 ${invoices.length} 筆發票');
          for (final inv in invoices) {
            _log('      √ ${inv['invoiceDate']} | ${inv['sellerName'].toString().padRight(10)} | \$${inv['totalAmount']}');
          }
        }

      } catch (e) {
        _log('   ❌ $monthLabel 執行異常: $e');
      }

      // 每個月分間隔一下，避免被封鎖
      await Future.delayed(const Duration(seconds: 1));
    }
  }

  // Future<void> fetchCarrierList(String auth, String cdsMc) async {
  //   final res = await _fetch(
  //       'https://service-mc.einvoice.nat.gov.tw/btc/cloud/api/btc503w/getCarrierList',
  //       {'Authorization': auth, 'x-cds-btc': cdsMc, 'Content-Type': 'application/json'},
  //       {}
  //   );
  // }
}
