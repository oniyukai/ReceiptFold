import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:receipt_fold/common/prefs.dart';
import 'package:receipt_fold/common/router.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/entity/invoice_carrier.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/modules/drift_services.dart';
import 'package:receipt_fold/pages/widget/my_text_field.dart';
import 'package:receipt_fold/pages/widget/overlay_show.dart';

class PageCarrierForm extends StatefulWidget
    with RouterBridge<PageCarrierFormArgs> {
  const PageCarrierForm({super.key});

  @override
  State<PageCarrierForm> createState() => _PageCarrierFormState();
}

class PageCarrierFormArgs {
  final int index;
  final List<InvoiceCarrier> items;

  const PageCarrierFormArgs({required this.index, required this.items});
}

class _PageCarrierFormState extends State<PageCarrierForm> {
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  late final PageCarrierFormArgs? _args = widget.getArgs(context);

  Future<void> _deleteItem() {
    return OverlayShow.dialog(
      context: context,
      title: DictKey.deleteLabel.s,
      content: Text(DictKey.sureToDeleteThisLabel.s),
      actions: [
        TextButton(
          child: Text(DictKey.deleteLabel.s),
          onPressed: () async {
            Navigator.pop(context);
            Navigator.pop(context);
            _args!.items.removeAt(_args.index);
            await DriftServices.appDb.keyValueStoreDao.upsert(
              .invoiceCarrierList,
              _args.items,
            );
          },
        ),
      ],
    );
  }

  Future<void> _pressedCheck() async {
    if (_formKey.currentState?.saveAndValidate() != true) return;
    final String carrierId2 = _formKey.currentState!.value['carrierId2'];
    final String name = _formKey.currentState!.value['name'];
    String? carrierType = _formKey.currentState!.value['carrierType'];
    String? carrierTypeName = _formKey.currentState!.value['carrierTypeName'];
    if (carrierType?.isEmpty == true) carrierType = null;
    if (carrierTypeName?.isEmpty == true) carrierTypeName = null;
    late final List<InvoiceCarrier> items;
    if (_args == null) {
      items = await DriftServices.appDb.keyValueStoreDao.getExistDefault(
        .invoiceCarrierList,
      );
      if (items.indexWhere((e) => e.carrierId2 == carrierId2) >= 0) {
        Utils.showToast('不允許新增已存在的相同載具隱碼');
        return;
      }
      items.insert(
        0,
        InvoiceCarrier(
          carrierId2: carrierId2,
          name: name,
          status: .manual,
          carrierType: carrierType,
          carrierTypeName: carrierTypeName,
        ),
      );
    } else {
      _args.items[_args.index] = InvoiceCarrier(
        carrierId2: carrierId2,
        name: name,
        status: _args.items[_args.index].status,
        carrierType: carrierType,
        carrierTypeName: carrierTypeName,
      );
      items = _args.items;
    }
    Navigator.pop(context);
    await DriftServices.appDb.keyValueStoreDao.upsert(
      .invoiceCarrierList,
      items,
    );
  }

  @override
  Widget build(context) {
    final bool allowEdit =
        _args?.items[_args.index].status != .platform ||
        context.readPrefs.get(.isAppDeveloperMode);
    return Scaffold(
      appBar: AppBar(
        title: Text(_args == null ? '新增歸戶載具' : '編輯歸戶載具'),
        actions: [
          if (_args != null && allowEdit)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: _deleteItem,
            ),
          if (allowEdit)
            IconButton(icon: const Icon(Icons.check), onPressed: _pressedCheck),
        ],
      ),
      body: SafeArea(
        child: Scrollbar(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              ListTile(
                subtitle: Text(
                  _args?.items[_args.index].status.locale ??
                      CarrierStatus.manual.locale,
                  overflow: TextOverflow.ellipsis,
                ),
                title: Text('載具狀態'),
              ),
              FormBuilder(
                key: _formKey,
                child: Column(
                  children: [
                    ListTile(minTileHeight: 0, subtitle: Text('載具隱碼')),
                    MyTextField(
                      name: 'carrierId2',
                      initialValue: _args?.items[_args.index].carrierId2,
                      readOnly: _args != null,
                    ),

                    ListTile(minTileHeight: 0, subtitle: Text('自訂名稱')),
                    MyTextField(
                      name: 'name',
                      initialValue: _args?.items[_args.index].name,
                      readOnly: !allowEdit,
                    ),

                    ListTile(minTileHeight: 0, subtitle: Text('類別代號')),
                    MyTextField(
                      name: 'carrierType',
                      initialValue: _args?.items[_args.index].carrierType,
                      required: false,
                      readOnly: !allowEdit,
                    ),

                    ListTile(minTileHeight: 0, subtitle: Text('類別名稱')),
                    MyTextField(
                      name: 'carrierTypeName',
                      initialValue: _args?.items[_args.index].carrierTypeName,
                      required: false,
                      readOnly: !allowEdit,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
