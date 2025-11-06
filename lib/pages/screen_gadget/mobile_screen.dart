import 'package:flutter/material.dart';
import 'package:home_widget/home_widget.dart';
import 'package:receipt_fold/entity/barcode_format.dart';
import 'package:receipt_fold/entity/barcode_item.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/modules/database_services.dart';
import 'package:receipt_fold/pages/menu_manager/tab_barcode_view.dart';

const String _androidName = 'HomeWidgetMobile';
const String _homeWidgetMobilePath = 'HomeWidgetMobilePath';

Future<void> updataHomeScreenMobile() async {
  await HomeWidget.renderFlutterWidget(
    HomeScreenMobileSample(items: DatabaseServices.mobileBarcodeList),
    key: _homeWidgetMobilePath,
    logicalSize: const Size(500, 200),
  );
  await HomeWidget.updateWidget(
    androidName: _androidName,
  );
}

class HomeScreenMobileSample extends StatelessWidget {
  final List<MobileBarcodeItem> items;

  const HomeScreenMobileSample({super.key, required this.items});

  @override
  Widget build(BuildContext context) {
    MobileBarcodeItem? firstCode;
    if (items.isNotEmpty) firstCode = items.first;
    if (firstCode == null) {
      return Container(
        color: Colors.white,
        child: Text(AppLocale.barcodeManagerNotYetSetLabel.s),
      );
    }
    return ScreenGadgetBarcode(
      data: firstCode.code,
      name: '${AppLocale.barcodeManagerMobileCarrierLabel.s} ${firstCode.name ?? ''}',
      format: BarcodeFormat.code39,
    );
  }
}

class ScreenGadgetBarcode extends StatelessWidget {
  final String data;
  final String? name;
  final BarcodeFormat format;

  const ScreenGadgetBarcode({
    super.key,
    required this.data,
    this.name,
    required this.format,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final barcodeWidth = constraints.biggest.shortestSide;
        return Card(
          color: Colors.white,
          elevation: 0,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
          child: Padding(
            padding: EdgeInsets.symmetric(
              vertical: barcodeWidth/20,
              horizontal: barcodeWidth/10,
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
                      child: Text(
                        name ?? '',
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(data),
                  ],
                ),
              ],
            ),
          ),
        );
      }
    );
  }
}