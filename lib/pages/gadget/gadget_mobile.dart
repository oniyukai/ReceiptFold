import 'dart:io';
import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:receipt_fold/entity/barcode_format.dart';
import 'package:receipt_fold/entity/barcode_item.dart';
import 'package:receipt_fold/modules/drift_services.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/pages/menu_manager/tab_barcode_view.dart';

const String _androidName = 'HomeWidgetMobile';
const String _homeWidgetMobilePath = 'HomeWidgetMobilePath';

Future<void> updateHomeScreenMobile() async {
  if (!Platform.isAndroid && !Platform.isIOS) return;
  await HomeWidget.renderFlutterWidget(
    GadgetMobile(
      items: await DriftServices.appDb.keyValueStoreDao.getExistDefault(
        .mobileBarcodeList,
      ),
    ),
    key: _homeWidgetMobilePath,
    logicalSize: const Size(500, 200),
  );
  await HomeWidget.updateWidget(androidName: _androidName);
}

class GadgetMobile extends StatelessWidget {
  final List<MobileBarcodeItem> items;

  const GadgetMobile({super.key, required this.items});

  @override
  Widget build(context) {
    MobileBarcodeItem? firstCode;
    if (items.isNotEmpty) firstCode = items.first;
    if (firstCode == null) {
      return Container(
        color: Colors.white,
        child: Text(DictKey.managerNotYetSet.s),
      );
    }
    return GadgetBarcode(
      data: firstCode.code,
      name: '${DictKey.managerMobileCarrier.s} ${firstCode.name ?? ''}',
      format: BarcodeFormat.code39,
    );
  }
}

class GadgetBarcode extends StatelessWidget {
  final String data;
  final String? name;
  final BarcodeFormat format;

  const GadgetBarcode({
    super.key,
    required this.data,
    this.name,
    required this.format,
  });

  @override
  Widget build(context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barcodeWidth = constraints.biggest.shortestSide;
        return Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: barcodeWidth / 20.0,
              horizontal: barcodeWidth / 10.0,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                BarcodeSvgPicture(
                  data: data,
                  format: format,
                  width: barcodeWidth,
                  aspectRatio: 4.66920,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      child: Text(name ?? '', overflow: TextOverflow.ellipsis),
                    ),
                    Text(data),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// todo debug: 當APP位於路由中, 在用小工具進入會push路由
