import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:receipt_fold/common/router.dart';
import 'package:receipt_fold/entity/barcode_format.dart';
import 'package:receipt_fold/entity/barcode_item.dart';
import 'package:receipt_fold/entity/drift/drift_database.dart';
import 'package:receipt_fold/locale/app_language.dart';
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
  late final PageMemberFormArgs? _args;
  bool _isInitialized = false;
  BarcodeFormat _format = BarcodeFormat.code128;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _args = widget.getArgs(context);
      _format = _args?.items[_args.index].format ?? BarcodeFormat.code128;
      _isInitialized = true;
    }
  }

  Future<void> _deleteItem() async {
    assert(_args != null);
    await showMyDialog(
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
            await DriftServices.appDb.keyValueStoreDao.upsert(.memberBarcodeList, _args.items);
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
      items = await DriftServices.appDb.keyValueStoreDao.getExistDefault(.memberBarcodeList);
      items.insert(0, MemberBarcodeItem(
        code: code,
        name: name,
        imageUrl: imageUrl,
        format: _format,
      ));
    } else {
      _args.items[_args.index] = MemberBarcodeItem(
        code: code,
        name: name,
        imageUrl: imageUrl,
        format: _format,
      );
      items = _args.items;
    }
    await DriftServices.appDb.keyValueStoreDao.upsert(.memberBarcodeList, items);
    await updataHomeScreenMember();
  }

  @override
  Widget build(context) {
    if (!_isInitialized) return const Center(child: CircularProgressIndicator());
    final barcodeWidth = MediaQuery.of(context).size.shortestSide / 2;
    return Scaffold(
      appBar: AppBar(
        title: Text(_args==null
            ? DictKey.barcodeManagerAddMembershipCardLabel.s
            : DictKey.barcodeManagerEditMembershipCardLabel.s
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
                      subtitle: Text(DictKey.barcodeManagerNameLabel.s),
                    ),
                    BarcodeField(
                      format: null,
                      name: 'name',
                      initialValue: _args?.items[_args.index].name,
                    ),
                    ListTile(
                      minTileHeight: 0,
                      subtitle: Text(DictKey.barcodeManagerCodeLabel.s),
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
                      initialValue: _args?.items[_args.index].code,
                    ),
                    ListTile(
                      minTileHeight: 0,
                      subtitle: Text(DictKey.barcodeManagerThumbnailURL.s),
                    ),
                    BarcodeField(
                      format: null,
                      name: 'imageUrl',
                      initialValue: _args?.items[_args.index].imageUrl,
                    ),
                  ],
                ),
              ),
              if (_args!=null) Column(
                children: [
                  ListTile(
                    minTileHeight: 0,
                    subtitle: Text(DictKey.barcodeManagerPreviousRenderingLabel.s),
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
                          data: _args.items[_args.index].code,
                          format: _args.items[_args.index].format,
                          width: barcodeWidth,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  ImageBox(item: _args.items[_args.index], nullNeedBuild: false),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
