import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:receipt_fold/common/router.dart';
import 'package:receipt_fold/entity/barcode_item.dart';
import 'package:receipt_fold/entity/objectbox/basic_data.dart';
import 'package:receipt_fold/modules/ob_services.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/pages/screen_gadget/member_screen.dart';
import 'package:receipt_fold/pages/screen_gadget/mobile_screen.dart';
import 'package:receipt_fold/pages/menu_manager/page_mobile_form.dart';
import 'package:receipt_fold/pages/menu_manager/page_member_form.dart';
import 'package:receipt_fold/pages/menu_manager/tab_barcode_view.dart';
import 'package:receipt_fold/pages/widget/functions.dart';

class TabMemberView extends StatefulWidget {
  const TabMemberView({super.key});

  @override
  State<TabMemberView> createState() => _TabMemberViewState();
}

class _TabMemberViewState extends State<TabMemberView> {
  final ScrollController _scrollController = ScrollController();
  List<MobileBarcodeItem> _mobileItems = [];
  List<MemberBarcodeItem> _memberItems = [];

  Future<void> _sortMobileItems() => showSortDialog(
    context: context,
    items: _mobileItems,
    itemBuilder: (item) => MobileItemCard(item: item),
    saveOnTap: (items) async {
      OBServices.updateMobileBarcodeList(items);
      await updateHomeScreenMobile();
    }
  );

  Future<void> _deleteAllMobileItems() => showMyDialog(
    context: context,
    title: DictKey.barcodeManagerMobileCarrierLabel.s,
    content: Text(DictKey.sureToDeleteThisLabel.s),
    actions: [
      TextButton(
        child: Text(DictKey.deleteLabel.s),
        onPressed: () async {
          Navigator.pop(context);
          OBServices.updateMobileBarcodeList([]);
          await updateHomeScreenMobile();
        },
      ),
    ],
  );

  Future<void> _sortMemberItem() => showSortDialog(
    context: context,
    items: _memberItems,
    itemBuilder: (item) => _MemberItemCard(item: item),
    saveOnTap: (items) async {
      OBServices.updateMemberBarcodeList(items);
      await updataHomeScreenMember();
    }
  );

  Future<void> _deleteAllMemberItems() => showMyDialog(
    context: context,
    title: DictKey.barcodeManagerMembershipCardLabel.s,
    content: Text(DictKey.sureToDeleteThisLabel.s),
    actions: [
      TextButton(
        child: Text(DictKey.deleteLabel.s),
        onPressed: () async {
          Navigator.pop(context);
          OBServices.updateMemberBarcodeList([]);
          await updataHomeScreenMember();
        },
      ),
    ],
  );

  @override
  Widget build(context) {
    return Scrollbar(
      controller: _scrollController,
      child: StreamBuilder<ReceiptFoldDataStore?>( // todo: Stream換個方式
        stream: OBServices.dataStoreStream,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          } else if (snapshot.hasError) {
            return Center(child: Text(snapshot.error.toString()));
          } else if (!snapshot.hasData || snapshot.data == null) {
            return Center(child: Text('snapshot.hasData:${snapshot.hasData}\nsnapshot.data:snapshot.data'));
          }
          _mobileItems = snapshot.data!.mobileBarcodeList;
          _memberItems = snapshot.data!.memberBarcodeList;
          return ListView(
            padding: const EdgeInsets.all(8.0),
            children: [
              ListTile(
                title: Text(DictKey.barcodeManagerMobileCarrierLabel.s),
                leading: const Icon(MaterialCommunityIcons.barcode),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_mobileItems.isNotEmpty) IconButton(
                      padding: const EdgeInsets.all(0),
                      visualDensity: VisualDensity.compact,
                      onPressed: _deleteAllMobileItems,
                      icon: const Icon(Icons.delete_forever),
                    ),
                    if (_mobileItems.length > 1) IconButton(
                      padding: const EdgeInsets.all(0),
                      visualDensity: VisualDensity.compact,
                      onPressed: _sortMobileItems,
                      icon: const Icon(Icons.swap_vert),
                    ),
                    IconButton(
                      padding: const EdgeInsets.all(0),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => MyRouter.routeTo(PageMobileForm),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
              Column(
                children: List.generate(_mobileItems.length, (index) => MobileItemCard(
                  item: _mobileItems[index],
                  onTap: () => MyRouter.of<PageMobileForm>().toPass(PageBarcodeFormArgs(
                    index: index,
                    items: _mobileItems,
                  )),
                )),
              ),
              ListTile(
                title: Text(DictKey.barcodeManagerMembershipCardLabel.s),
                leading: const Icon(Icons.loyalty_outlined),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_memberItems.isNotEmpty) IconButton(
                      padding: const EdgeInsets.all(0),
                      visualDensity: VisualDensity.compact,
                      onPressed: _deleteAllMemberItems,
                      icon: const Icon(Icons.delete_forever),
                    ),
                    if (_memberItems.length > 1) IconButton(
                      padding: const EdgeInsets.all(0),
                      visualDensity: VisualDensity.compact,
                      onPressed: _sortMemberItem,
                      icon: const Icon(Icons.swap_vert),
                    ),
                    IconButton(
                      padding: const EdgeInsets.all(0),
                      visualDensity: VisualDensity.compact,
                      onPressed: () => MyRouter.routeTo(PageMemberForm),
                      icon: const Icon(Icons.add),
                    ),
                  ],
                ),
              ),
              Column(
                children: List.generate(_memberItems.length, (index) => _MemberItemCard(
                  item: _memberItems[index],
                  onTap: () => MyRouter.of<PageMemberForm>().toPass(PageMemberFormArgs(
                    index: index,
                    items: _memberItems,
                  )),
                )),
              ),
            ],
          );
        },
      ),
    );
  }
}

class MobileItemCard extends StatelessWidget {
  final MobileBarcodeItem item;
  final VoidCallback? onTap;

  const MobileItemCard({
    super.key,
    required this.item,
    this.onTap
  });

  @override
  Widget build(context) {
    return Card(
      child: ListTile(
        minTileHeight: 0,
        title: Text(
          item.code,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          item.name ?? '',
          overflow: TextOverflow.ellipsis,
        ),
        onTap: onTap,
      ),
    );
  }
}

class _MemberItemCard extends StatelessWidget {
  final MemberBarcodeItem item;
  final VoidCallback? onTap;

  const _MemberItemCard({
    required this.item,
    this.onTap
  });

  @override
  Widget build(context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        minTileHeight: 0,
        title: Text(
          item.name ?? '',
          overflow: TextOverflow.ellipsis
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              item.code,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              item.format.locale,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
        trailing: ImageBox(item: item, nullNeedBuild: false),
      ),
    );
  }
}
