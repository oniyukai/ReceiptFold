import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:receipt_fold/common/router.dart';
import 'package:receipt_fold/entity/barcode_format.dart';
import 'package:receipt_fold/entity/barcode_item.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/modules/database_services.dart';
import 'package:receipt_fold/pages/screen_gadget/mobile_screen.dart';
import 'package:receipt_fold/pages/widget/barcode_field.dart';
import 'package:receipt_fold/pages/widget/functions.dart';

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
  bool _isInitialized = false;
  PageBarcodeFormArgs? _args;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _args = widget.argumentOf(context);
      _isInitialized = true;
    }
  }

  void _deleteitem() {
    assert(_args!=null);
    showMyDialog(
      context: context,
      title: AppLocale.deleteLabel.s,
      content: Text(AppLocale.sureToDeleteThisLabel.s),
      actions: [
        TextButton(
          child: Text(AppLocale.deleteLabel.s),
          onPressed: () async {
            Navigator.of(context).pop();
            Navigator.of(context).pop();
            _args!.items.removeAt(_args!.index);
            DatabaseServices.updateMobileBarcodeList(_args!.items);
            await updataHomeScreenMobile();
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
      items = DatabaseServices.mobileBarcodeList;
      items.insert(0, MobileBarcodeItem(
        code: code,
        name: name,
      ));
    } else {
      _args!.items[_args!.index] = MobileBarcodeItem(
        code: code,
        name: name,
      );
      items = _args!.items;
    }
    DatabaseServices.updateMobileBarcodeList(items);
    await updataHomeScreenMobile();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_args==null
            ? AppLocale.barcodeManagerAddMobileCarrierLabel.s
            : AppLocale.barcodeManagerEditMobileCarrierLabel.s
        ),
        actions: [
          if (_args!=null) IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _deleteitem,
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
                      subtitle: Text(AppLocale.barcodeManagerCodeLabel.s),
                    ),
                    BarcodeField(
                      format: BarcodeFormat.code39,
                      name: 'code',
                      formKey: _formKey,
                      initialValue: _args?.items[_args!.index].code,
                    ),
                    ListTile(
                      minTileHeight: 0,
                      subtitle: Text(AppLocale.barcodeManagerNameLabel.s),
                    ),
                    BarcodeField(
                      format: null,
                      name: 'name',
                      formKey: _formKey,
                      initialValue: _args?.items[_args!.index].name,
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