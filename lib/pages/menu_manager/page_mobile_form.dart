import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:receipt_fold/common/router.dart';
import 'package:receipt_fold/entity/barcode_format.dart';
import 'package:receipt_fold/entity/barcode_item.dart';
import 'package:receipt_fold/entity/drift/drift_database.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/pages/screen_gadget/mobile_screen.dart';
import 'package:receipt_fold/pages/widget/barcode_field.dart';
import 'package:receipt_fold/pages/widget/overlay_show.dart';

class PageMobileForm extends StatefulWidget with RouterBridge<PageBarcodeFormArgs> {
  const PageMobileForm({super.key});

  @override
  State<PageMobileForm> createState() => _PageMobileFormState();
}

class PageBarcodeFormArgs {
  final int index;
  final List<MobileBarcodeItem> items;

  const PageBarcodeFormArgs({
    required this.index,
    required this.items,
  });
}

class _PageMobileFormState extends State<PageMobileForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  late final PageBarcodeFormArgs? _args;
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _args = widget.getArgs(context);
      _isInitialized = true;
    }
  }

  Future<void> _deleteItem() {
    assert(_args!=null);
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
            await DriftServices.appDb.keyValueStoreDao.upsert(.mobileBarcodeList, _args.items);
            await updateHomeScreenMobile();
          },
        ),
      ],
    );
  }

  Future<void> _pressedCheck() async {
    if (_formKey.currentState?.saveAndValidate() != true) return;
    Navigator.pop(context);
    final String code = _formKey.currentState?.value['code'] ?? '';
    final String? name = _formKey.currentState?.value['name'];
    late final List<MobileBarcodeItem> items;
    if (_args==null) {
      items = await DriftServices.appDb.keyValueStoreDao.getExistDefault(.mobileBarcodeList);
      items.insert(0, MobileBarcodeItem(
        code: code,
        name: name,
      ));
    } else {
      _args.items[_args.index] = MobileBarcodeItem(
        code: code,
        name: name,
      );
      items = _args.items;
    }
    await DriftServices.appDb.keyValueStoreDao.upsert(.mobileBarcodeList, items);
    await updateHomeScreenMobile();
  }

  @override
  Widget build(context) {
    if (!_isInitialized) return const Center(child: CircularProgressIndicator());
    return Scaffold(
      appBar: AppBar(
        title: Text(_args==null
            ? DictKey.barcodeManagerAddMobileCarrierLabel.s
            : DictKey.barcodeManagerEditMobileCarrierLabel.s
        ),
        actions: [
          if (_args!=null) IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _deleteItem,
          ),
          IconButton(
            icon: const Icon(Icons.check),
            onPressed: _pressedCheck,
          ),
        ],
      ),
      body: SafeArea(
        child: Scrollbar(
          child: ListView(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            children: [
              FormBuilder(
                key: _formKey,
                child: Column(
                  children: [
                    ListTile(
                      minTileHeight: 0,
                      subtitle: Text(DictKey.barcodeManagerCodeLabel.s),
                    ),
                    BarcodeField(
                      format: BarcodeFormat.code39,
                      name: 'code',
                      initialValue: _args?.items[_args.index].code,
                    ),
                    ListTile(
                      minTileHeight: 0,
                      subtitle: Text(DictKey.barcodeManagerNameLabel.s),
                    ),
                    BarcodeField(
                      format: null,
                      name: 'name',
                      initialValue: _args?.items[_args.index].name,
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
