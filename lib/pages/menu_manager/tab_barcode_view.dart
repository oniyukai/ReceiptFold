import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:form_builder_validators/form_builder_validators.dart';
import 'package:provider/provider.dart';
import 'package:receipt_fold/common/prefs.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/entity/barcode_format.dart';
import 'package:receipt_fold/entity/barcode_item.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/modules/drift_services.dart';
import 'package:receipt_fold/pages/menu_manager/main_manager_widgets.dart';
import 'package:receipt_fold/pages/menu_nav_bar.dart';
import 'package:receipt_fold/pages/menu_settings/main_settings_widgets.dart';
import 'package:receipt_fold/pages/widget/barcode_field.dart';
import 'package:receipt_fold/pages/widget/expandable_card.dart';
import 'package:receipt_fold/pages/widget/overlay_show.dart';
import 'package:screen_brightness/screen_brightness.dart';

class TabBarcodeView extends StatefulWidget {
  const TabBarcodeView({super.key});

  @override
  State<TabBarcodeView> createState() => _TabBarcodeViewState();
}

class _TabBarcodeViewState extends State<TabBarcodeView> {
  final ScrollController _scrollController = ScrollController();
  late List<MobileBarcodeItem> _mobileItems;
  late List<MemberBarcodeItem> _memberItems;
  int? _mobileItemIndex;
  int? _memberItemIndex;
  bool _isBrightness = PrefsEnum.isAutoBrightness.defaultValue();
  bool _isLockOrientation = PrefsEnum.isAutoBrightness.defaultValue();
  bool _isLastTimeOnView = false;
  bool _isInitialized = false;

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
    _setAppBrightness(false);
    _setOrientationLock(false);
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.watch<MenuNavBarProvider>().onManager) {
      _initLoadItem();
      _isBrightness = context.readPrefs.get(PrefsEnum.isAutoBrightness);
      _setAppBrightness(_isBrightness);
      _isLockOrientation = context.readPrefs.get(
        PrefsEnum.isShowScreenRotation,
      );
      _setOrientationLock(_isLockOrientation);
      _isLastTimeOnView = true;
    } else if (_isLastTimeOnView) {
      _setAppBrightness(false);
      _isBrightness = context.readPrefs.get(PrefsEnum.isAutoBrightness);
      _setOrientationLock(false);
      _isLockOrientation = context.readPrefs.get(
        PrefsEnum.isShowScreenRotation,
      );
      _isLastTimeOnView = false;
    }
  }

  Future<void> _initLoadItem() async {
    if (_isInitialized) return;
    _isInitialized = true;
    _mobileItems = await DriftServices.appDb.keyValueStoreDao.getExistDefault(
      .mobileBarcodeList,
    );
    _memberItems = await DriftServices.appDb.keyValueStoreDao.getExistDefault(
      .memberBarcodeList,
    );
    if (_mobileItems.isNotEmpty) _mobileItemIndex = 0;
    if (_memberItems.isNotEmpty) _memberItemIndex = 0;
    if (mounted) setState(() {});
  }

  Future<void> _setAppBrightness(bool toBrightness) async {
    try {
      if (toBrightness) {
        await ScreenBrightness.instance.setApplicationScreenBrightness(1.0);
      } else if (_isBrightness) {
        await ScreenBrightness.instance.resetApplicationScreenBrightness();
      }
    } catch (e) {
      Utils.showToast(e.toString());
    }
  }

  Future<void> _setOrientationLock(bool toLock) async {
    if (toLock) {
      await Utils.lockCurrentOrientation(context);
    } else if (_isLockOrientation) {
      await Utils.unlockCurrentOrientation();
    }
  }

  Future<void> _changeMobileItem() {
    final ScrollController scrollController = ScrollController();
    return OverlayShow.dialog(
      context: context,
      title: DictKey.managerChangeMobileCarrier.s,
      noCancelButton: true,
      content: Scrollbar(
        controller: scrollController,
        child: SingleChildScrollView(
          controller: scrollController,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: List.generate(
              _mobileItems.length,
              ((index) => MobileItemCard(
                item: _mobileItems[index],
                onTap: () {
                  setState(() => _mobileItemIndex = index);
                  Navigator.pop(context);
                },
              )),
            ),
          ),
        ),
      ),
    ).whenComplete(scrollController.dispose);
  }

  @override
  Widget build(context) {
    final barcodeWidth = MediaQuery.of(context).size.shortestSide / 2;
    final isPortrait = Utils.isPortrait(context);
    return Scrollbar(
      controller: _scrollController,
      child: ListView(
        controller: _scrollController,
        padding: const EdgeInsets.all(8.0),
        children: [
          ExpandableCard(
            initialExpanded: true,
            text: DictKey.managerMembershipCard.s,
            iconData: Icons.loyalty_outlined,
            expandedChild: (_memberItemIndex == null)
                ? Center(child: Text(DictKey.managerNotYetSet.s))
                : Flex(
                    direction: isPortrait ? Axis.vertical : Axis.horizontal,
                    children: [
                      Expanded(
                        flex: isPortrait ? 0 : 1,
                        child: Card(
                          color: Colors.white,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: barcodeWidth / 10,
                              horizontal: barcodeWidth / 6,
                            ),
                            child: BarcodeSvgPicture(
                              data: _memberItems[_memberItemIndex!].code,
                              format: _memberItems[_memberItemIndex!].format,
                              width: barcodeWidth,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: isPortrait ? 0 : 1,
                        child: Column(
                          children: [
                            SingleChildScrollView(
                              padding: const EdgeInsets.all(6.0),
                              scrollDirection: Axis.horizontal,
                              child: Row(
                                spacing: 4,
                                children: List.generate(
                                  min(_memberItems.length, 12),
                                  (index) => Opacity(
                                    opacity: index == _memberItemIndex
                                        ? 1.0
                                        : 0.4,
                                    child: ImageBox(
                                      item: _memberItems[index],
                                      onTap: () => setState(
                                        () => _memberItemIndex = index,
                                      ),
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            Card(
                              child: ListTile(
                                minTileHeight: 0,
                                title: Text(
                                  _memberItems[_memberItemIndex!].name ?? '',
                                  overflow: TextOverflow.ellipsis,
                                ),
                                subtitle: Text(
                                  _memberItems[_memberItemIndex!].code,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                trailing: IconButton(
                                  onPressed: () => Utils.copyText(
                                    _memberItems[_memberItemIndex!].code,
                                  ),
                                  icon: const Icon(Icons.copy),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
          ),
          ExpandableCard(
            initialExpanded: true,
            text: DictKey.managerMobileCarrier.s,
            iconData: MaterialCommunityIcons.barcode,
            expandedChild: _mobileItemIndex == null
                ? Center(child: Text(DictKey.managerNotYetSet.s))
                : Flex(
                    direction: isPortrait ? Axis.vertical : Axis.horizontal,
                    children: [
                      Expanded(
                        flex: isPortrait ? 0 : 1,
                        child: Card(
                          color: Colors.white,
                          child: Padding(
                            padding: EdgeInsets.symmetric(
                              vertical: barcodeWidth / 10,
                              horizontal: barcodeWidth / 6,
                            ),
                            child: BarcodeSvgPicture(
                              data: _mobileItems[_mobileItemIndex!].code,
                              format: BarcodeFormat.code39,
                              width: barcodeWidth,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        flex: isPortrait ? 0 : 1,
                        child: Card(
                          child: ListTile(
                            minTileHeight: 0,
                            onTap: _changeMobileItem,
                            title: Text(
                              _mobileItems[_mobileItemIndex!].code,
                              overflow: TextOverflow.ellipsis,
                            ),
                            subtitle: Text(
                              _mobileItems[_mobileItemIndex!].name ?? '',
                              overflow: TextOverflow.ellipsis,
                            ),
                            trailing: IconButton(
                              onPressed: () => Utils.copyText(
                                _mobileItems[_mobileItemIndex!].code,
                              ),
                              icon: const Icon(Icons.copy),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
          ),
          ListTileSwitch(
            text: DictKey.managerBrightenScreen.s,
            iconData: Icons.brightness_6_outlined,
            initialValue: _isBrightness,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(64.0),
            ),
            onToggle: (value) {
              _setAppBrightness(value);
              setState(() => _isBrightness = value);
            },
          ),
        ],
      ),
    );
  }
}

class BarcodeSvgPicture extends StatelessWidget {
  final String data;
  final BarcodeFormat format;
  final double width;
  final double aspectRatio;

  const BarcodeSvgPicture({
    super.key,
    required this.data,
    required this.format,
    required this.width,
    this.aspectRatio = 2.71828,
  });

  @override
  Widget build(context) {
    String? checkMsg = barcodeValidator(data, format);
    Widget? svgWidget;
    try {
      if (checkMsg == null) {
        svgWidget = SvgPicture.string(
          format.barcodeFunc().toSvg(
            data,
            drawText: false,
            width: aspectRatio,
            height: 1,
          ),
          width: width,
        );
      }
    } catch (e) {
      checkMsg = e.toString();
    }
    return Center(
      child:
          svgWidget ??
          Text(checkMsg!, style: const TextStyle(color: Colors.grey)),
    );
  }
}

class ImageBox extends StatelessWidget {
  final MemberBarcodeItem item;
  final bool nullNeedBuild;
  final bool needBorderRadius;
  final VoidCallback? onTap;

  const ImageBox({
    super.key,
    required this.item,
    this.nullNeedBuild = true,
    this.needBorderRadius = true,
    this.onTap,
  });

  @override
  Widget build(context) {
    final double width = 100;
    final double height = 64;
    if (item.imageUrl == null || item.imageUrl!.isEmpty) {
      return nullNeedBuild
          ? SizedBox(
              width: width,
              height: height,
              child: GestureDetector(
                onTap: onTap,
                child: Card(
                  margin: EdgeInsets.zero,
                  shape: (needBorderRadius)
                      ? null
                      : RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(0),
                        ),
                  child: Center(
                    child: Text(
                      Utils.noEmptyStr(item.code) ?? item.code,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
              ),
            )
          : const SizedBox.shrink();
    }
    if (!UrlValidator().isURL(item.imageUrl)) {
      return SizedBox(
        width: width,
        height: height,
        child: GestureDetector(
          onTap: onTap,
          child: Card(
            margin: EdgeInsets.zero,
            shape: (needBorderRadius)
                ? null
                : RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(0),
                  ),
            child: Center(
              child: Text(
                DictKey.managerNotAUrl.s,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(color: Colors.red),
              ),
            ),
          ),
        ),
      );
    }
    return Card(
      margin: EdgeInsets.zero,
      shape: (needBorderRadius)
          ? null
          : RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      child: GestureDetector(
        onTap: onTap,
        child: CachedNetworkImage(
          imageUrl: item.imageUrl!,
          placeholder: (context, url) =>
              const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) =>
              const Icon(Icons.error, color: Colors.red),
          fit: BoxFit.cover,
          width: width,
          height: height,
        ),
      ),
    );
  }
}
