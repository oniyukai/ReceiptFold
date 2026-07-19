import 'dart:io';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:receipt_fold/entity/barcode_item.dart';
import 'package:receipt_fold/modules/drift_services.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/pages/menu_manager/tab_barcode_view.dart';
import 'package:receipt_fold/pages/gadget/gadget_mobile.dart';

const String _androidName = 'HomeWidgetMember';
const String _homeWidgetMemberItemIndex = 'HomeWidgetMemberItemIndex';
const String _homeWidgetMemberItemLength = 'HomeWidgetMemberItemLength';
const int _maxItemLength = 6;

Future<void> updateHomeScreenMember() async {
  if (!Platform.isAndroid && !Platform.isIOS) return;
  final List<MemberBarcodeItem> memberItems = await DriftServices.appDb.keyValueStoreDao.getExistDefault(.memberBarcodeList);
  final itemLength = min(memberItems.length, _maxItemLength);
  await HomeWidget.saveWidgetData<int>(_homeWidgetMemberItemLength, itemLength);
  await HomeWidget.saveWidgetData<int>(_homeWidgetMemberItemIndex, -1);
  for (int index=0; index<itemLength; index++) {
    await HomeWidget.renderFlutterWidget(
      GadgetBarcode(
        data: memberItems[index].code,
        format: memberItems[index].format,
        name:  memberItems[index].name,
      ),
      key: 'HomeWidgetMemberItemBarcodes[$index]',
      logicalSize: const Size(500, 200),
    );
    await HomeWidget.renderFlutterWidget(
      ImageBox(
        item: memberItems[index],
        needBorderRadius: false,
      ),
      key: 'HomeWidgetMemberItemImages[$index]',
      logicalSize: const Size(100, 64),
    );
  }
  await HomeWidget.updateWidget(
    androidName: _androidName,
  );
}

class GadgetMember extends StatefulWidget {
  final List<MemberBarcodeItem> items;

  const GadgetMember({super.key, required this.items});

  @override
  State<GadgetMember> createState() => _GadgetMemberState();
}

class _GadgetMemberState extends State<GadgetMember> {
  int _memberItemIndex = 0;

  @override
  Widget build(context) {
    if (widget.items.isEmpty) {
      return Container(
        color: Colors.white,
        child: Text(DictKey.managerNotYetSet.s),
      );
    } else if (_memberItemIndex != -1) {
      return InkWell(
        onTap: () => setState(() => _memberItemIndex = -1),
        child: GadgetBarcode(
          data: widget.items[_memberItemIndex].code,
          format: widget.items[_memberItemIndex].format,
          name:  widget.items[_memberItemIndex].name,
        ),
      );
    } else {
      return Card(
        child: SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: List.generate(min(widget.items.length, _maxItemLength), (index) => ImageBox(
              item: widget.items[index],
              needBorderRadius: false,
              onTap: () => setState(() => _memberItemIndex = index),
            )),
          ),
        ),
      );
    }
  }
}
