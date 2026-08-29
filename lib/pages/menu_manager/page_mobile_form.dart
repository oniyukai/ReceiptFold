import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:material_ui/material_ui.dart';
import 'package:receipt_fold/common/router.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/entity/barcode_format.dart';
import 'package:receipt_fold/entity/barcode_item.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/pages/gadget/gadget_mobile.dart';
import 'package:receipt_fold/pages/widget/barcode_field.dart';
import 'package:receipt_fold/pages/widget/overlay_show.dart';
import 'package:receipt_fold/services/drift_service.dart';

class PageMobileForm extends StatefulWidget
    with RouterBridge<PageBarcodeFormArgs> {
  const PageMobileForm({super.key});

  @override
  State<PageMobileForm> createState() => _PageMobileFormState();
}

class PageBarcodeFormArgs {
  final int index;
  final List<MobileBarcodeItem> items;

  const PageBarcodeFormArgs({required this.index, required this.items});
}

class _PageMobileFormState extends State<PageMobileForm> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  late final PageBarcodeFormArgs? _args = widget.getArgs(context);

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  Future<void> _deleteItem() {
    assert(_args != null);
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
            await DriftService.appDb.keyValueStoreDao.upsert(
              .mobileBarcodeList,
              _args.items,
            );
            await updateHomeScreenMobile();
          },
        ),
      ],
    );
  }

  Future<void> _pressedCheck() async {
    if (_formKey.currentState?.saveAndValidate() != true) return;
    Navigator.pop(context);
    final String code = _formKey.currentState!.value['code'];
    final String? name = Utils.noEmptyStr(_formKey.currentState!.value['name']);
    late final List<MobileBarcodeItem> items;
    if (_args == null) {
      items = await DriftService.appDb.keyValueStoreDao.getExistDefault(
        .mobileBarcodeList,
      );
      items.insert(0, MobileBarcodeItem(code: code, name: name));
    } else {
      _args.items[_args.index] = MobileBarcodeItem(code: code, name: name);
      items = _args.items;
    }
    await DriftService.appDb.keyValueStoreDao.upsert(.mobileBarcodeList, items);
    await updateHomeScreenMobile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _args == null
              ? DictKey.managerAddMobileCarrier.s
              : DictKey.managerEditMobileCarrier.s,
        ),
        actions: [
          if (_args != null)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: _deleteItem,
            ),
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
                  minTileHeight: 0,
                  subtitle: Text(DictKey.managerCodeLabel.s),
                ),
                BarcodeField(
                  format: BarcodeFormat.code39,
                  name: 'code',
                  initialValue: _args?.items[_args.index].code,
                ),
                ListTile(
                  minTileHeight: 0,
                  subtitle: Text(DictKey.managerNameLabel.s),
                ),
                BarcodeField(
                  format: null,
                  name: 'name',
                  initialValue: _args?.items[_args.index].name,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
