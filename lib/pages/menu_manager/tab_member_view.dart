import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:receipt_fold/common/router.dart';
import 'package:receipt_fold/entity/barcode_item.dart';
import 'package:receipt_fold/entity/drift/key_value_store.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/modules/drift_services.dart';
import 'package:receipt_fold/pages/gadget/gadget_member.dart';
import 'package:receipt_fold/pages/gadget/gadget_mobile.dart';
import 'package:receipt_fold/pages/menu_manager/main_manager_widgets.dart';
import 'package:receipt_fold/pages/menu_manager/page_member_form.dart';
import 'package:receipt_fold/pages/menu_manager/page_mobile_form.dart';
import 'package:receipt_fold/pages/widget/overlay_show.dart';

class TabMemberView extends StatefulWidget {
  const TabMemberView({super.key});

  @override
  State<TabMemberView> createState() => _TabMemberViewState();
}

class _TabMemberViewState extends State<TabMemberView> {
  final ScrollController _scrollController = ScrollController();
  late final StreamSubscription<Map<KVStoreKey, dynamic>> _kVStoreSubscription;
  late List<MemberBarcodeItem> _memberItems;
  late List<MobileBarcodeItem> _mobileItems;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _kVStoreSubscription = DriftServices.appDb.keyValueStoreDao
        .stream(const [.mobileBarcodeList, .memberBarcodeList])
        .listen(
          (data) => setState(() {
            _memberItems = data[KVStoreKey.memberBarcodeList];
            _mobileItems = data[KVStoreKey.mobileBarcodeList];
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

  Future<void> _sortMemberItem() => OverlayShow.sortDialog(
    context: context,
    items: _memberItems,
    itemBuilder: (item) => MemberItemCard(item: item),
    saveOnTap: (items) async {
      await DriftServices.appDb.keyValueStoreDao.upsert(
        .memberBarcodeList,
        items,
      );
      await updateHomeScreenMember();
    },
  );

  Future<void> _sortMobileItems() => OverlayShow.sortDialog(
    context: context,
    items: _mobileItems,
    itemBuilder: (item) => MobileItemCard(item: item),
    saveOnTap: (items) async {
      await DriftServices.appDb.keyValueStoreDao.upsert(
        .mobileBarcodeList,
        items,
      );
      await updateHomeScreenMobile();
    },
  );

  @override
  Widget build(context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    } else if (_errorMessage != null) {
      return Center(child: Text(_errorMessage!));
    }
    return Scrollbar(
      controller: _scrollController,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(8.0),
        children: [
          ListTile(
            title: Text(DictKey.managerMembershipCard.s),
            leading: const Icon(Icons.loyalty_outlined),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_memberItems.length > 1)
                  IconButton(
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
          ..._memberItems.mapIndexed(
            (index, item) => MemberItemCard(
              item: item,
              onTap: () => MyRouter.of<PageMemberForm>().toPass(
                PageMemberFormArgs(index: index, items: _memberItems),
              ),
            ),
          ),

          ListTile(
            title: Text(DictKey.managerMobileCarrier.s),
            leading: const Icon(MaterialCommunityIcons.barcode),
            trailing: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (_mobileItems.length > 1)
                  IconButton(
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
          ..._mobileItems.mapIndexed(
            (index, item) => MobileItemCard(
              item: item,
              onTap: () => MyRouter.of<PageMobileForm>().toPass(
                PageBarcodeFormArgs(index: index, items: _mobileItems),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
