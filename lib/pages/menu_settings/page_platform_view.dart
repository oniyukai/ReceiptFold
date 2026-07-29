import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:flutter_inappwebview/flutter_inappwebview.dart';
import 'package:logger/logger.dart';
import 'package:receipt_fold/common/prefs.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/entity/drift/receipt.dart';
import 'package:receipt_fold/entity/invoice_carrier.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/modules/drift_services.dart';
import 'package:receipt_fold/modules/invoice_platform_api.dart';
import 'package:receipt_fold/modules/log_service.dart';
import 'package:receipt_fold/modules/secure_prefs.dart';
import 'package:receipt_fold/pages/menu_settings/main_settings_widgets.dart';
import 'package:receipt_fold/pages/menu_settings/page_backup_view.dart';
import 'package:receipt_fold/pages/widget/expandable_card.dart';
import 'package:receipt_fold/pages/widget/my_text_field.dart';
import 'package:receipt_fold/pages/widget/overlay_show.dart';

class PagePlatformView extends StatefulWidget {
  const PagePlatformView({super.key});

  @override
  State<PagePlatformView> createState() => _PagePlatformViewState();
}

class _PagePlatformViewState extends State<PagePlatformView> {
  final ScrollController _scrollController = ScrollController();
  final ScrollController _logScrollController = ScrollController();
  final InvoicePlatformApi _api = InvoicePlatformApi();
  final InAppWebViewKeepAlive _inAppWebViewKeepAlive = InAppWebViewKeepAlive();
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  final ValueNotifier<bool> _singleActionLocked = ValueNotifier(false);
  final _logs = <String>[];
  late final StreamSubscription<LogService> _logSubscription;

  bool get _apiReady => _api.isInitialized;

  @override
  void initState() {
    super.initState();
    _logSubscription = LogService.stream
        .where((e) => e.level >= Level.debug)
        .listen((data) {
          setState(() => _logs.insert(0, data.logString));
        });
  }

  @override
  void dispose() {
    super.dispose();
    _logSubscription.cancel();
    _scrollController.dispose();
    _logScrollController.dispose();
    _api.close();
    unawaited(DriftDispatcher.connectWebDAV());
  }

  Future<({String? phone, String? password})> _readPlatformAccount() async {
    String? phone;
    String? password;
    final String? jsonString = await SecurePrefs.invoicePlatformAccount.read();
    try {
      if (jsonString != null) {
        final Map map = jsonDecode(jsonString);
        phone = map['phone'];
        password = map['password'];
      }
    } catch (e) {
      debugPrint('_readPlatformAccount: $e');
    }
    return (phone: phone, password: password);
  }

  Future<void> _pressSetAccount() async {
    final account = await _readPlatformAccount();
    await OverlayShow.bottomSheet(
      context: context,
      noCancelButton: true,
      title: ListTile(
        title: Text(DictKey.platformAccountSetting.s),
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        trailing: IconButton(
          onPressed: () async {
            if (_formKey.currentState?.saveAndValidate() != true) return;
            Navigator.pop(context);
            await SecurePrefs.invoicePlatformAccount.write(
              jsonEncode({
                'phone': _formKey.currentState!.value['phone'] ?? '',
                'password': _formKey.currentState!.value['password'] ?? '',
              }),
            );
            await _pressFillAccount();
          },
          icon: const Icon(Icons.check),
        ),
      ),
      content: FormBuilder(
        key: _formKey,
        child: Column(
          spacing: 16,
          children: [
            MyTextField(
              labelText: DictKey.platformPhoneLabel.s,
              name: 'phone',
              initialValue: account.phone,
              required: false,
            ),
            MyTextField(
              labelText: DictKey.platformPasswordLabel.s,
              name: 'password',
              initialValue: account.password,
              type: FieldType.password,
              required: false,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pressFillAccount() async {
    if (!mounted) return;
    final account = await _readPlatformAccount();
    try {
      await _api.fillLoginForm(account.phone, account.password);
    } catch (e) {
      LogService(
        'fillLoginForm $Exception.',
        errorObject: e,
        instance: _api,
      ).w();
    }
  }

  Future<void> _pressImportCSV() async {
    if (_singleActionLocked.value) {
      LogService('現在已有其他操作, 取消執行.', instance: this).d();
      return;
    }
    _singleActionLocked.value = true;
    try {
      final FilePickerResult? result = await FilePicker.pickFiles(
        type: FileType.custom,
        allowedExtensions: const ['csv'],
      );
      if (result == null) {
        Utils.showToast('取消');
        return;
      }
      final File file = File(result.files.single.path!);
      await DriftServices.appDb.receiptDao.upsertMany(
        pairMap: _api.decodeImportCSV(await file.readAsString()),
        scopeStart: OriginStatus.manualImport,
        scopeEnd: OriginStatus.manualImport,
      );
      LogService('🟢 _pressImportCSV finished.', instance: this).d();
      return;
    } catch (e) {
      LogService('_pressImportCSV failed.', errorObject: e, instance: this).e();
      return;
    } finally {
      _singleActionLocked.value = false;
    }
  }

  Future<bool> _pressFetchCarrierList() async {
    assert(_apiReady);
    if (_singleActionLocked.value) {
      LogService('現在已有其他雲端平台操作, 取消執行.', instance: this).d();
      return false;
    }
    _singleActionLocked.value = true;
    try {
      final List<InvoiceCarrier> carriers = await _api.fetchCarrierList();
      final carriersMap = <String, InvoiceCarrier>{
        for (final carrier in carriers) carrier.carrierId2: carrier,
      };
      final List<InvoiceCarrier> oldCarriers = await DriftServices
          .appDb
          .keyValueStoreDao
          .getExistDefault(.invoiceCarrierList);
      for (final oldCarrier in oldCarriers) {
        final InvoiceCarrier? carrier = carriersMap[oldCarrier.carrierId2];
        if (carrier != null) {
          oldCarrier
            ..name = carrier.name
            ..status = carrier.status
            ..carrierType = carrier.carrierType ?? oldCarrier.carrierType
            ..carrierTypeName =
                carrier.carrierTypeName ?? oldCarrier.carrierTypeName
            ..fetchJson = carrier.fetchJson ?? oldCarrier.fetchJson;
          carriersMap.remove(oldCarrier.carrierId2);
        } else if (oldCarrier.status == CarrierStatus.platform) {
          oldCarrier.status = CarrierStatus.platformExpired;
        }
      }
      await DriftServices.appDb.keyValueStoreDao.upsert(.invoiceCarrierList, [
        ...carriersMap.values,
        ...oldCarriers,
      ]);
      LogService('🟢 _pressFetchCarrierList finished.', instance: this).d();
      return true;
    } catch (e) {
      LogService(
        '_pressFetchCarrierList failed.',
        errorObject: e,
        instance: this,
      ).e();
      return false;
    } finally {
      _singleActionLocked.value = false;
    }
  }

  Future<bool> _pressFetchAwardList() async {
    assert(_apiReady);
    if (_singleActionLocked.value) {
      LogService('現在已有其他雲端平台操作, 取消執行.', instance: this).d();
      return false;
    }
    _singleActionLocked.value = true;
    try {
      await DriftServices.appDb.receiptDao.upsertMany(
        pairMap: await _api.fetchAwardList(),
        scopeStart: OriginStatus.platformUnconfirmed,
        scopeEnd: OriginStatus.platformExpired,
      );
      LogService('🟢 _pressFetchAwardList finished.', instance: this).d();
      return true;
    } catch (e) {
      LogService(
        '_pressFetchAwardList failed.',
        errorObject: e,
        instance: this,
      ).e();
      return false;
    } finally {
      _singleActionLocked.value = false;
    }
  }

  Future<bool> _pressFetchInvoiceList() async {
    assert(_apiReady);
    if (_singleActionLocked.value) {
      LogService('現在已有其他雲端平台操作, 取消執行.', instance: this).d();
      return false;
    }
    _singleActionLocked.value = true;
    try {
      await DriftServices.appDb.receiptDao.upsertMany(
        pairMap: await _api.fetchInvoiceList(
          context.readPrefs.get(.invoiceQueryMonths),
        ),
        scopeStart: OriginStatus.platformUnconfirmed,
        scopeEnd: OriginStatus.platformExpired,
      );
      LogService('🟢 _pressFetchInvoiceList finished.', instance: this).d();
      return true;
    } catch (e) {
      LogService(
        '_pressFetchInvoiceList failed.',
        errorObject: e,
        instance: this,
      ).e();
      return false;
    } finally {
      _singleActionLocked.value = false;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(DictKey.platformTitle.s)),
      body: SafeArea(
        child: Scrollbar(
          controller: _scrollController,
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.fromLTRB(16.0, 0.0, 16.0, 16.0),
            children: [
              ValueListenableBuilder(
                valueListenable: _singleActionLocked,
                builder: (context, value, child) => value
                    ? const LinearProgressIndicator()
                    : const SizedBox.shrink(),
              ),
              ExpandableCard(
                iconData: Icons.play_circle_outline,
                text: DictKey.platformFunctionAction.s,
                initialExpanded: true,
                expandedChild: Column(
                  children: [
                    ListTile(
                      leading: const Icon(Icons.manage_accounts),
                      title: Text(DictKey.platformAccountSetting.s),
                      onTap: _pressSetAccount,
                    ),
                    ListTile(
                      leading: const Icon(Icons.input),
                      title: Text(DictKey.platformFillAccount.s),
                      onTap: _pressFillAccount,
                    ),
                    ListTilePicker<int>(
                      iconData: Icons.calendar_month,
                      text: DictKey.platformQueryMonths.s,
                      selectedOption: context.readPrefs.get(
                        .invoiceQueryMonths,
                      ),
                      optionMap: Map.fromEntries(
                        List.generate(
                          InvoicePlatformApi.maxQueryMonths,
                          (i) => MapEntry(
                            i + 1,
                            Utils.multilingualFiller(
                              DictKey.platformQueryMonthsOption.s,
                              [(StaticString.fillObjectMonths, '${i + 1}')],
                            ),
                          ),
                        ),
                      ),
                      onChanged: (value) async {
                        await context.readPrefs.update(
                          .invoiceQueryMonths,
                          value,
                          false,
                        );
                        setState(() {});
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.manage_accounts),
                      title: Text(DictKey.platformImportCsv.s),
                      onTap: _pressImportCSV,
                    ),
                    ListTile(
                      leading: const Icon(Icons.play_circle),
                      title: Text(DictKey.platformExecuteAll.s),
                      enabled: _apiReady,
                      onTap: () async {
                        await _pressFetchCarrierList() &&
                            await _pressFetchAwardList() &&
                            await _pressFetchInvoiceList();
                      },
                    ),
                    ListTile(
                      leading: const Icon(Icons.payment),
                      title: Text(DictKey.platformFetchCarrier.s),
                      enabled: _apiReady,
                      onTap: _pressFetchCarrierList,
                    ),
                    ListTile(
                      leading: const Icon(Icons.money),
                      title: Text(DictKey.platformFetchAward.s),
                      enabled: _apiReady,
                      onTap: _pressFetchAwardList,
                    ),
                    ListTile(
                      leading: const Icon(Icons.article_outlined),
                      title: Text(DictKey.platformFetchInvoice.s),
                      enabled: _apiReady,
                      onTap: _pressFetchInvoiceList,
                    ),
                  ],
                ),
              ),

              ExpandableCard(
                iconData: Icons.terminal,
                text: DictKey.platformRealTimeLog.s,
                initialExpanded: true,
                expandedChild: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: double.infinity,
                    maxHeight: 400.0,
                  ),
                  child: Scrollbar(
                    controller: _logScrollController,
                    child: SingleChildScrollView(
                      controller: _logScrollController,
                      child: SelectableText(_logs.join('\n')),
                    ),
                  ),
                ),
              ),

              ExpandableCard(
                iconData: Icons.web,
                text: DictKey.platformWebView.s,
                initialExpanded: true,
                expandedChild: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minWidth: double.infinity,
                    maxHeight: 400.0,
                  ),
                  child: InAppWebView(
                    keepAlive: _inAppWebViewKeepAlive,
                    gestureRecognizers: <Factory<OneSequenceGestureRecognizer>>{
                      Factory<OneSequenceGestureRecognizer>(
                        () => EagerGestureRecognizer(),
                      ),
                    },
                    initialUrlRequest: URLRequest(
                      url: WebUri(
                        'https://www.einvoice.nat.gov.tw/accounts/login/mw',
                      ),
                    ),
                    onWebViewCreated: (controller) {
                      setState(() => _api.controller = controller);
                      Timer(const Duration(seconds: 2), _pressFillAccount);
                    },
                    shouldInterceptRequest: (controller, request) async {
                      _api.auth = request.headers?['Authorization'];
                      if (_api.isInitialized) setState(() {});
                      return null;
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
