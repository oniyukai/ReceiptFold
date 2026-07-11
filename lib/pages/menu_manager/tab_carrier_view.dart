import 'dart:async';

import 'package:flutter/material.dart';
import 'package:receipt_fold/common/router.dart';
import 'package:receipt_fold/entity/drift/key_value_store.dart';
import 'package:receipt_fold/entity/invoice_carrier.dart';
import 'package:receipt_fold/modules/drift_services.dart';
import 'package:receipt_fold/pages/menu_manager/main_manager_widgets.dart';
import 'package:receipt_fold/pages/menu_manager/page_carrier_form.dart';
import 'package:receipt_fold/pages/widget/overlay_show.dart';

class TabCarrierView extends StatefulWidget {
  const TabCarrierView({super.key});

  @override
  State<TabCarrierView> createState() => _TabCarrierViewState();
}

class _TabCarrierViewState extends State<TabCarrierView> {
  final ScrollController _scrollController = ScrollController();
  late final StreamSubscription<Map<KVStoreKey, dynamic>> _kVStoreSubscription;
  List<InvoiceCarrier> _carrierList = const [];
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _kVStoreSubscription = DriftServices.appDb.keyValueStoreDao
        .stream(const [.invoiceCarrierList])
        .listen(
          (data) => setState(() {
            _carrierList = data[KVStoreKey.invoiceCarrierList];
            _isLoading = false;
            _errorMessage = null;
          }),
          onError: (e) => setState(() {
            _isLoading = false;
            _errorMessage = e.toString();
          }),
        );
  }

  @override
  void dispose() {
    super.dispose();
    _kVStoreSubscription.cancel();
    _scrollController.dispose();
  }

  Future<void> _writeToAll() {
    return OverlayShow.dialog(
      context: context,
      title: '搜尋發票並寫入資料',
      content: Text('確定要執行此操作嗎?'),
      actions: [
        TextButton(
          child: Text('確認並執行'),
          onPressed: () async {
            Navigator.pop(context);
            // todo: 搜尋發票並寫入資料
          },
        ),
      ],
    );
  }

  Future<void> _sortCarrierList() => OverlayShow.sortDialog(
    context: context,
    items: _carrierList,
    itemBuilder: (item) => CarrierCard(carrier: item),
    saveOnTap: (items) async {
      await DriftServices.appDb.keyValueStoreDao.upsert(
        .invoiceCarrierList,
        items,
      );
    },
  );

  @override
  Widget build(context) {
    return Scrollbar(
      controller: _scrollController,
      child: Builder(
        builder: (context) {
          if (_isLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (_errorMessage != null) {
            return Center(child: Text(_errorMessage!));
          }
          return ListView(
            padding: const EdgeInsets.all(8.0),
            children: [
              ListTile(
                title: ElevatedButton(
                  onPressed: _writeToAll,
                  child: Text('搜尋發票並寫入資料'),
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_carrierList.length > 1)
                      IconButton(
                        padding: const EdgeInsets.all(0),
                        visualDensity: VisualDensity.compact,
                        onPressed: _sortCarrierList,
                        icon: const Icon(Icons.swap_vert),
                      ),
                    IconButton(
                      padding: const EdgeInsets.all(0),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => MyRouter.routeTo(PageCarrierForm),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
              Column(
                children: List.generate(
                  _carrierList.length,
                  (index) => CarrierCard(
                    carrier: _carrierList[index],
                    onTap: () => MyRouter.of<PageCarrierForm>().toPass(
                      PageCarrierFormArgs(index: index, items: _carrierList),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
