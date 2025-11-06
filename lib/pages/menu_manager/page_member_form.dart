import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:receipt_fold/common/router.dart';
import 'package:receipt_fold/entity/barcode_format.dart';
import 'package:receipt_fold/entity/barcode_item.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/modules/database_services.dart';
import 'package:receipt_fold/pages/menu_manager/tab_barcode_view.dart';
import 'package:receipt_fold/pages/screen_gadget/member_screen.dart';
import 'package:receipt_fold/pages/widget/barcode_field.dart';
import 'package:receipt_fold/pages/widget/functions.dart';

class PageMemberForm extends StatefulWidget with RouterBridge<PageMemberFormArgs>  {
  const PageMemberForm({super.key});

  @override
  State<PageMemberForm> createState() => _PageMemberFormState();
}

class PageMemberFormArgs {
  final int index;
  final List<MemberBarcodeItem> items;

  const PageMemberFormArgs({
    required this.index,
    required this.items,
  });
}

class _PageMemberFormState extends State<PageMemberForm> {
  final _formKey = GlobalKey<FormBuilderState>();
  bool _isInitialized = false;
  BarcodeFormat _format = BarcodeFormat.code128;
  PageMemberFormArgs? _args;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _args = widget.argumentOf(context);
      _format = _args?.items[_args!.index].format ?? BarcodeFormat.code128;
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
            DatabaseServices.updateMemberBarcodeList(_args!.items);
            await updataHomeScreenMember();
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
    final String? imageUrl = _formKey.currentState?.value['imageUrl'];
    late final List<MemberBarcodeItem> items;
    if (_args==null) {
      items = DatabaseServices.memberBarcodeList;
      items.insert(0, MemberBarcodeItem(
        code: code,
        name: name,
        imageUrl: imageUrl,
        format: _format,
      ));
    } else {
      _args!.items[_args!.index] = MemberBarcodeItem(
        code: code,
        name: name,
        imageUrl: imageUrl,
        format: _format,
      );
      items = _args!.items;
    }
    DatabaseServices.updateMemberBarcodeList(items);
    await updataHomeScreenMember();
  }

  @override
  Widget build(BuildContext context) {
    final barcodeWidth = MediaQuery.of(context).size.shortestSide / 2;
    return Scaffold(
      appBar: AppBar(
        title: Text(_args==null
            ? AppLocale.barcodeManagerAddMembershipCardLabel.s
            : AppLocale.barcodeManagerEditMembershipCardLabel.s
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
                      subtitle: Text(AppLocale.barcodeManagerNameLabel.s),
                    ),
                    BarcodeField(
                      format: null,
                      name: 'name',
                      formKey: _formKey,
                      initialValue: _args?.items[_args!.index].name,
                    ),
                    ListTile(
                      minTileHeight: 0,
                      subtitle: Text(AppLocale.barcodeManagerCodeLabel.s),
                    ),
                    DropdownMenu(
                      initialSelection: _format,
                      expandedInsets: EdgeInsets.zero,
                      inputDecorationTheme: const InputDecorationTheme(),
                      dropdownMenuEntries: BarcodeFormat.values.map((value) => DropdownMenuEntry(
                        value: value,
                        label: value.locale,
                      )).toList(),
                      onSelected: (value) => setState(() => _format = value ?? _format),
                    ),
                    const SizedBox(height: 16),
                    BarcodeField(
                      format: _format,
                      name: 'code',
                      formKey: _formKey,
                      initialValue: _args?.items[_args!.index].code,
                    ),
                    ListTile(
                      minTileHeight: 0,
                      subtitle: Text(AppLocale.barcodeManagerThumbnailURL.s),
                    ),
                    BarcodeField(
                      format: null,
                      name: 'imageUrl',
                      formKey: _formKey,
                      initialValue: _args?.items[_args!.index].imageUrl,
                    ),
                  ],
                ),
              ),
              if (_args!=null) Column(
                children: [
                  ListTile(
                    minTileHeight: 0,
                    subtitle: Text(AppLocale.barcodeManagerPreviousRenderingLabel.s),
                  ),
                  Card(
                    color: Colors.white,
                    child: Padding(
                      padding: EdgeInsets.symmetric(
                        vertical: barcodeWidth/10,
                        horizontal: barcodeWidth/6,
                      ),
                      child: Center(
                        child: BarcodeSvgPicture(
                          data: _args!.items[_args!.index].code,
                          format: _args!.items[_args!.index].format,
                          width: barcodeWidth,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ImageBox(item: _args!.items[_args!.index], nullNeedBuild: false),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
