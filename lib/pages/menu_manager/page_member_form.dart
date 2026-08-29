import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:material_ui/material_ui.dart';
import 'package:receipt_fold/common/router.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/entity/barcode_format.dart';
import 'package:receipt_fold/entity/barcode_item.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/pages/gadget/gadget_member.dart';
import 'package:receipt_fold/pages/menu_manager/tab_barcode_view.dart';
import 'package:receipt_fold/pages/widget/barcode_field.dart';
import 'package:receipt_fold/pages/widget/overlay_show.dart';
import 'package:receipt_fold/services/drift_service.dart';

class PageMemberForm extends StatefulWidget
    with RouterBridge<PageMemberFormArgs> {
  const PageMemberForm({super.key});

  @override
  State<PageMemberForm> createState() => _PageMemberFormState();
}

class PageMemberFormArgs {
  final int index;
  final List<MemberBarcodeItem> items;

  const PageMemberFormArgs({required this.index, required this.items});
}

class _PageMemberFormState extends State<PageMemberForm> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  late final PageMemberFormArgs? _args = widget.getArgs(context);
  late BarcodeFormat _format =
      _args?.items[_args.index].format ?? BarcodeFormat.code128;

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
              .memberBarcodeList,
              _args.items,
            );
            await updateHomeScreenMember();
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
    final String? imageUrl = Utils.noEmptyStr(
      _formKey.currentState!.value['imageUrl'],
    );
    late final List<MemberBarcodeItem> items;
    if (_args == null) {
      items = await DriftService.appDb.keyValueStoreDao.getExistDefault(
        .memberBarcodeList,
      );
      items.insert(
        0,
        MemberBarcodeItem(
          code: code,
          name: name,
          imageUrl: imageUrl,
          format: _format,
        ),
      );
    } else {
      _args.items[_args.index] = MemberBarcodeItem(
        code: code,
        name: name,
        imageUrl: imageUrl,
        format: _format,
      );
      items = _args.items;
    }
    await DriftService.appDb.keyValueStoreDao.upsert(.memberBarcodeList, items);
    await updateHomeScreenMember();
  }

  @override
  Widget build(BuildContext context) {
    final barcodeWidth = MediaQuery.of(context).size.shortestSide / 2;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _args == null
              ? DictKey.managerAddMembershipCard.s
              : DictKey.managerEditMembershipCard.s,
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
                  subtitle: Text(DictKey.managerNameLabel.s),
                ),
                BarcodeField(
                  format: null,
                  name: 'name',
                  initialValue: _args?.items[_args.index].name,
                ),
                ListTile(
                  minTileHeight: 0,
                  subtitle: Text(DictKey.managerCodeLabel.s),
                ),
                DropdownMenu(
                  initialSelection: _format,
                  expandedInsets: EdgeInsets.zero,
                  inputDecorationTheme: const InputDecorationTheme(),
                  dropdownMenuEntries: [
                    for (final barcodeFormat in BarcodeFormat.values)
                      DropdownMenuEntry(
                        value: barcodeFormat,
                        label: barcodeFormat.locale,
                      ),
                  ],
                  onSelected: (value) =>
                      setState(() => _format = value ?? _format),
                ),
                const SizedBox(height: 16),
                BarcodeField(
                  format: _format,
                  name: 'code',
                  initialValue: _args?.items[_args.index].code,
                ),
                ListTile(
                  minTileHeight: 0,
                  subtitle: Text(DictKey.managerThumbnailUrl.s),
                ),
                BarcodeField(
                  format: null,
                  name: 'imageUrl',
                  initialValue: _args?.items[_args.index].imageUrl,
                ),
                if (_args != null) ...[
                  ListTile(
                    minTileHeight: 0,
                    subtitle: Text(DictKey.managerPreviousRendering.s),
                  ),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Card(
                          color: Colors.white,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: barcodeWidth / 10,
                              horizontal: barcodeWidth / 6,
                            ),
                            child: BarcodeSvgPicture(
                              data: _args.items[_args.index].code,
                              format: _args.items[_args.index].format,
                              width: barcodeWidth,
                            ),
                          ),
                        ),
                      ),
                      Expanded(
                        child: ImageBox(
                          item: _args.items[_args.index],
                          nullNeedBuild: false,
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
