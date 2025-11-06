import 'dart:math';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:flutter_vector_icons/flutter_vector_icons.dart';
import 'package:provider/provider.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/entity/barcode_format.dart';
import 'package:receipt_fold/entity/barcode_item.dart';
import 'package:receipt_fold/modules/database_services.dart';
import 'package:receipt_fold/modules/prefs.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/pages/menu_manager/tab_member_view.dart';
import 'package:receipt_fold/pages/menu_nav_bar.dart';
import 'package:receipt_fold/pages/menu_settings/main_settings_widgets.dart';
import 'package:receipt_fold/pages/widget/barcode_field.dart';
import 'package:receipt_fold/pages/widget/expandable_card.dart';
import 'package:receipt_fold/pages/widget/functions.dart';
import 'package:screen_brightness/screen_brightness.dart';
import 'package:string_validator/string_validator.dart';

class TabBarcodeView extends StatefulWidget {
  const TabBarcodeView({super.key});

  @override
  State<TabBarcodeView> createState() => _TabBarcodeViewState();
}

class _TabBarcodeViewState extends State<TabBarcodeView> {
  final ScrollController _scrollController = ScrollController();
  final List<MobileBarcodeItem> _mobileItems = DatabaseServices.mobileBarcodeList;
  final List<MemberBarcodeItem> _memberItems = DatabaseServices.memberBarcodeList;
  int? _mobileItemIndex;
  int? _memberItemIndex;
  bool _isBrightness = PrefsEnum.isAutoBrightness.defaultValue();
  bool _isLockOrientation = PrefsEnum.isAutoBrightness.defaultValue();
  bool _isLastTimeOnView = false;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _setAppBrightness(false);
    _setOrientationLock(false);
    super.dispose();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (context.watch<MenuNavBarProvider>().onManager) {
      _initLoadItem();
      _isBrightness = context.readPrefs.get(PrefsEnum.isAutoBrightness);
      _setAppBrightness(_isBrightness);
      _isLockOrientation = context.readPrefs.get(PrefsEnum.isShowScreenRotation);
      _setOrientationLock(_isLockOrientation);
      _isLastTimeOnView = true;
    } else if (_isLastTimeOnView) {
      _setAppBrightness(false);
      _isBrightness = context.readPrefs.get(PrefsEnum.isAutoBrightness);
      _setOrientationLock(false);
      _isLockOrientation = context.readPrefs.get(PrefsEnum.isShowScreenRotation);
      _isLastTimeOnView = false;
    }
  }

  void _initLoadItem() {
    if (_mobileItems.isNotEmpty) _mobileItemIndex = 0;
    if (_memberItems.isNotEmpty) _memberItemIndex = 0;
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

  Future<void> _copyMember() async {
    if (_memberItemIndex == null) return;
    await Clipboard.setData(ClipboardData(text: _memberItems[_memberItemIndex!].code));
  }

  Future<void> _copyMobile() async {
    if (_mobileItemIndex == null) return;
    await Clipboard.setData(ClipboardData(text: _mobileItems[_mobileItemIndex!].code));
  }

  void _changeMobileItem() => showMyDialog(
    context: context,
    title: AppLocale.barcodeManagerChangeMobileCarrierLabel.s,
    noCancelButton: true,
    content: Scrollbar(
      child: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: List.generate(_mobileItems.length, ((index) => MobileItemCard(
            item: _mobileItems[index],
            onTap: () {
              setState(() => _mobileItemIndex = index);
              Navigator.of(context).pop();
            },
          ))),
        ),
      ),
    ),
  );

  @override
  Widget build(BuildContext context) {
    final barcodeWidth = MediaQuery.of(context).size.shortestSide / 2;
    final isPortrait = Utils.isPortrait(context);
    return Scrollbar(
      controller: _scrollController,
      child: ListView(
        padding: const EdgeInsets.all(8.0),
        children: [
          ExpandableCard(
            initialExpanded: true,
            text: AppLocale.barcodeManagerMembershipCardLabel.s,
            iconData: Icons.loyalty_outlined,
            expandedChild: (_memberItemIndex == null)
                ? Center(child: Text(AppLocale.barcodeManagerNotYetSetLabel.s))
                : Flex(
              direction: isPortrait ? Axis.vertical : Axis.horizontal,
              children: [
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: barcodeWidth/10,
                      horizontal: barcodeWidth/6,
                    ),
                    child: Center(
                      child: BarcodeSvgPicture(
                        data:_memberItems[_memberItemIndex!].code,
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
                          children: List.generate(min(_memberItems.length, 12), (index) => Opacity(
                            opacity: index == _memberItemIndex ? 1.0 : 0.4,
                            child: ImageBox(
                              item: _memberItems[index],
                              onTap: () => setState(() => _memberItemIndex = index),
                            ),
                          )),
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
                            onPressed: _copyMember,
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
            text: AppLocale.barcodeManagerMobileCarrierLabel.s,
            iconData: MaterialCommunityIcons.barcode,
            expandedChild: _mobileItemIndex == null
                ? Center(child: Text(AppLocale.barcodeManagerNotYetSetLabel.s))
                : Flex(
              direction: isPortrait ? Axis.vertical : Axis.horizontal,
              children: [
                Card(
                  color: Colors.white,
                  child: Padding(
                    padding: EdgeInsets.symmetric(
                      vertical: barcodeWidth/10,
                      horizontal: barcodeWidth/6,
                    ),
                    child: Center(
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
                        onPressed: _copyMobile,
                        icon: const Icon(Icons.copy),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          ListTileSwitch(
            text: AppLocale.barcodeManagerBrightenScreenLabel.s,
            initialValue: _isBrightness,
            iconData: Icons.brightness_6_outlined,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(64.0)),
            onToggle: (value) {
              _setAppBrightness(value);
              setState(() => _isBrightness = value);
            },
          )
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
  Widget build(BuildContext context) {
    final checkMsg = barcodeValidator(data, format);
    if (checkMsg != null) return Text(checkMsg, style: TextStyle(color: Colors.grey));
    try {
      final barcode = format.barcodeFunc();
      return SvgPicture.string(
        barcode.toSvg(
          data,
          drawText: false,
          width: aspectRatio,
          height: 1,
        ),
        width: width,
      );
    } catch (e) {
      return Text(e.toString(), style: TextStyle(color: Colors.grey));
    }
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
  Widget build(BuildContext context) {
    final double width = 100;
    final double height = 64;
    if (item.imageUrl == null || item.imageUrl==''){
      return nullNeedBuild ? SizedBox(
        width: width,
        height: height,
        child: GestureDetector(
          onTap: onTap,
          child: Card(
            margin: EdgeInsets.zero,
            shape: (needBorderRadius) ? null : RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
            child: Center(
              child: Text(
                (item.name=='') ? (item.code) : (item.name ?? item.code),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        )
      ) : const SizedBox.shrink();
    }
    if (item.imageUrl?.isURL() != true) {
      return SizedBox(
        width: width,
        height: height,
        child: GestureDetector(
          onTap: onTap,
          child: Card(
            margin: EdgeInsets.zero,
            shape: (needBorderRadius) ? null : RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
            child: Center(
              child: Text(
                AppLocale.barcodeManagerNotanURL.s,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  color: Colors.red,
                ),
              ),
            ),
          ),
        )
      );
    }
    return Card(
      margin: EdgeInsets.zero,
      shape: (needBorderRadius) ? null : RoundedRectangleBorder(borderRadius: BorderRadius.circular(0)),
      child: GestureDetector(
        onTap: onTap,
        child: CachedNetworkImage(
          imageUrl: item.imageUrl!,
          placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
          errorWidget: (context, url, error) => const Icon(Icons.error, color: Colors.red),
          fit: BoxFit.cover,
          width: width,
          height: height,
        ),
      ),
    );
  }
}
