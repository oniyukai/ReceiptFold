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
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  late final PageCarrierFormArgs? _args = widget.getArgs(context);

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  Future<void> _deleteItem() {
    return OverlayShow.dialog(
      context: context,
      title: DictKey.commonUiDelete.s,
      content: Text(DictKey.commonUiSureDelete.s),
      actions: [
        TextButton(
          child: Text(DictKey.commonUiDelete.s),
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
    final String? carrierType = Utils.noEmptyStr(
      _formKey.currentState!.value['carrierType'],
    );
    final String? carrierTypeName = Utils.noEmptyStr(
      _formKey.currentState!.value['carrierTypeName'],
    );
    late final List<InvoiceCarrier> items;
    if (_args == null) {
      items = await DriftServices.appDb.keyValueStoreDao.getExistDefault(
        .invoiceCarrierList,
      );
      if (items.indexWhere((e) => e.carrierId2 == carrierId2) >= 0) {
        Utils.showToast(DictKey.managerCarrierDuplicate.s);
        return;
      }
      items.insert(
        0,
        InvoiceCarrier(
          carrierId2: carrierId2,
          name: name,
          status: CarrierStatus.device,
          carrierType: carrierType,
          carrierTypeName: carrierTypeName,
        ),
      );
    } else {
      assert(_args.items[_args.index].carrierId2 == carrierId2);
      _args.items[_args.index]
        ..name = name
        ..carrierType = carrierType
        ..carrierTypeName = carrierTypeName;
      items = _args.items;
    }
    Navigator.pop(context);
    await DriftServices.appDb.keyValueStoreDao.upsert(
      .invoiceCarrierList,
      items,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool allowEdit =
        _args?.items[_args.index].status != CarrierStatus.platform ||
        context.readPrefs.get(.isAppDeveloperMode);
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _args == null
              ? DictKey.managerAddCarrier.s
              : DictKey.managerEditCarrier.s,
        ),
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
        child: FormBuilder(
          key: _formKey,
          child: Scrollbar(
            controller: _scrollController,
            child: ListView(
              controller: _scrollController,
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              children: [
                ListTile(
                  subtitle: Text(
                    _args?.items[_args.index].status.locale ??
                        CarrierStatus.device.locale,
                    overflow: TextOverflow.ellipsis,
                  ),
                  title: Text(DictKey.managerCarrierStatus.s),
                ),
                MyTextField(
                  labelText: DictKey.receiptHeaderCarrierId2.s,
                  name: 'carrierId2',
                  initialValue: _args?.items[_args.index].carrierId2,
                  readOnly: _args != null,
                ),
                const SizedBox(height: 16),
                MyTextField(
                  labelText: DictKey.managerCarrierCustomName.s,
                  name: 'name',
                  initialValue: _args?.items[_args.index].name,
                  readOnly: !allowEdit,
                ),
                const SizedBox(height: 16),
                MyTextField(
                  labelText: DictKey.managerCarrierTypeCode.s,
                  name: 'carrierType',
                  initialValue: _args?.items[_args.index].carrierType,
                  required: false,
                  readOnly: !allowEdit,
                ),
                const SizedBox(height: 16),
                MyTextField(
                  labelText: DictKey.managerCarrierTypeName.s,
                  name: 'carrierTypeName',
                  initialValue: _args?.items[_args.index].carrierTypeName,
                  required: false,
                  readOnly: !allowEdit,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
