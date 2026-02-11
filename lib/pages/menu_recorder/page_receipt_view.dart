import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:receipt_fold/common/router.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/entity/invoice_period.dart';
import 'package:receipt_fold/entity/objectbox/receipt.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/modules/database_services.dart';
import 'package:receipt_fold/pages/widget/barcode_field.dart';
import 'package:receipt_fold/pages/widget/functions.dart';
import 'package:receipt_fold/pages/widget/my_menu_button.dart';
import 'package:receipt_fold/pages/widget/required_text_field.dart';

class PageReceiptView extends StatefulWidget with RouterBridge<PageReceiptViewArgs> {
  const PageReceiptView({super.key});

  @override
  State<PageReceiptView> createState() => _PageReceiptViewState();
}

class PageReceiptViewArgs {
  final InvoicePeriod? period;
  final ReceiptHeader? header;

  const PageReceiptViewArgs({
    this.period,
    this.header,
  });

  bool get isAdd => _check(period != null);

  bool get isEdit => _check(header != null);

  bool _check(bool value) {
    assert(
      (period == null) != (header == null),
      'PageReceiptViewArgs(period is ${period.runtimeType}, header is ${header.runtimeType}), 其中一個必須有，另一個必須為空.'
    );
    return value;
  }
}

class _PageReceiptViewState extends State<PageReceiptView> {
  final _formKey = GlobalKey<FormBuilderState>();
  late final PageReceiptViewArgs _args;
  late final ReceiptHeader _header;
  List<ReceiptDetail> _details = [];
  bool _isInitialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_isInitialized) {
      _args = widget.getArgs(context)!;
      if (_args.isEdit) {
        _header = _args.header!;
        _details = _header.details;
        ReceiptDetail.sortList(_details);
      } else {
        _header = ReceiptHeader(
          invoiceInstantDate: _args.period!.startDateTime.millisecondsSinceEpoch,
          receiptOrigin_: ReceiptOrigin.manualAddition.name,
          totalAmount: 0,
        );
      }
      _isInitialized = true;
    }
  }

  bool get _isCloudPlatform => _header.receiptOrigin == ReceiptOrigin.cloudPlatform;

  // < ---------- 適用於所有狀態的前端接口
  VoidCallback _switchReceiptOrigin(ReceiptOrigin selected) => () {
    if (selected == _header.receiptOrigin) return;
    _header.receiptOrigin = selected;
    _updateInDatabase(false);
  };

  VoidCallback _normalStringTileVoid({
    required String titleText,
    required String? initialValue,
    bool openModifyAllTime = false,
    required ValueChanged<String?> changed,})
  {
    const fieldName = 'normalStringField';
    final allowModify = openModifyAllTime ? true : !_isCloudPlatform;
    final textTheme = Theme.of(context).textTheme;

    void checkModify() {
      assert(allowModify);
      if (_formKey.currentState?.saveAndValidate() != true) return;
      String? changedValue = _formKey.currentState?.value[fieldName];
      if (changedValue == '') changedValue = null;
      Navigator.pop(context);
      if (changedValue == initialValue) return;
      changed(changedValue);
      _updateInDatabase(false);
    }

    return () async => showMyBottomSheet(
      context: context,
      noCancelButton: true,
      title: ListTile(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          titleText,
          style: textTheme.titleMedium,
        ),
        trailing: allowModify ? IconButton(
          onPressed: checkModify,
          icon: const Icon(Icons.check),
        ) : null,
      ),
      content: Column(
        children: [
          _ReceiptInfoTile(
            titleText: initialValue,
            subtitleText: DictKey.receiptViewOriginalContentLabel.s,
            trailing: IconButton(
              onPressed: _copyTextToClipboard(initialValue),
              icon: const Icon(Icons.copy),
            ),
          ),
          if (allowModify) ListTile(
            minTileHeight: 0,
            subtitle: Text(DictKey.receiptViewModifyLabel.s),
          ),
          if (allowModify) FormBuilder(
            key: _formKey,
            child: BarcodeField(
              initialValue: initialValue,
              format: null,
              name: fieldName,
            ),
          ),
        ],
      ),
      // noCancelButton,
    );
  }

  // 適用於所有狀態的前端接口 ---------- >
  // < ---------- 適用於特定狀態的前端接口

  Future<void> _deleteIconPressed() async {
    assert(_args.isEdit);
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
            DatabaseServices.receiptDao.remove(_header);
          },
        ),
      ],
    );
  }

  void _checkIconPressed() {
    assert(_args.isAdd && _header.id == 0);
    Navigator.pop(context);
    DatabaseServices.receiptDao.upsert(_header, _details);
  }

  Future<void> _selectDateTime() async {
    assert(!_isCloudPlatform);
    final invoiceDateTime = _header.invoiceDateTime;
    Future<DateTime?> datePicker() => showDatePicker(
      context: context,
      initialDate: invoiceDateTime,
      firstDate: DateTime(2011),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    Future<TimeOfDay?> timePicker() => showTimePicker(
      context: context,
      initialTime: TimeOfDay(hour: invoiceDateTime.hour, minute: invoiceDateTime.minute),
    );
    final pickedDate = await datePicker();
    if (pickedDate == null) return;
    final pickedTime = await timePicker();
    if (pickedTime == null) return;
    final combinedDateTime = DateTime(
      pickedDate.year, pickedDate.month, pickedDate.day,
      pickedTime.hour, pickedTime.minute,
      invoiceDateTime.second, invoiceDateTime.millisecond, invoiceDateTime.microsecond,
    );
    if (combinedDateTime == invoiceDateTime) return;
    _header.invoiceInstantDate = combinedDateTime.millisecondsSinceEpoch;
    _updateInDatabase(false);
  }

  VoidCallback _oneDetailAddOrModify([int? index, ReceiptDetail? detail]) {
    assert(!_isCloudPlatform);
    if ((index == null) != (detail == null)) throw 'index, detail需要同時有或是同時沒有';
    const itemDescriptionName = 'itemDescription';
    const unitPriceName = 'unitPrice';
    const quantityName = 'quantity';
    final isAddNotModify = detail == null;
    final textTheme = Theme.of(context).textTheme;

    Future<void> deleteDetail() async {
      assert(!isAddNotModify);
      if (index == null || detail == null) throw 'index不能是null';
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
              _header.totalAmount -= detail.amount;
              _details.removeAt(index);
              _updateInDatabase(true);
            },
          ),
        ],
      );
    }

    void checkAddOrModify() {
      if (_formKey.currentState?.saveAndValidate() != true) return;
      String itemDescription = _formKey.currentState?.value[itemDescriptionName];
      String unitPriceString = _formKey.currentState?.value[unitPriceName];
      String quantityString = _formKey.currentState?.value[quantityName];
      double? unitPrice = double.tryParse(unitPriceString);
      double? quantity = double.tryParse(quantityString);
      if (unitPrice==null || quantity==null || itemDescription=='') return;
      Navigator.pop(context);
      if (unitPrice==detail?.unitPrice && quantity==detail?.quantity && itemDescription==detail?.itemDescription) return;
      final tempDetail = detail ?? ReceiptDetail(
        sequenceNumber: '',
        itemDescription: '',
        unitPrice: 0,
        quantity: 0,
        amount: 0,
      )
        ..itemDescription = itemDescription
        ..unitPrice = unitPrice
        ..quantity = quantity
        ..amount = unitPrice * quantity;
      if (index != null) {
        _details[index] = tempDetail;
      } else {
        _details.add(tempDetail);
        _header.totalAmount += tempDetail.amount;
      }
      _updateInDatabase(true);
    }

    return () async => showMyBottomSheet(
      context: context,
      noCancelButton: true,
      title: ListTile(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          DictKey.receiptDetailLabel.s,
          style: textTheme.titleMedium,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isAddNotModify) IconButton(
              onPressed: deleteDetail,
              icon: const Icon(Icons.delete_forever),
            ),
            IconButton(
              onPressed: checkAddOrModify,
              icon: Icon(isAddNotModify ? Icons.add : Icons.check),
            ),
          ],
        ),
      ),
      content: FormBuilder(
        key: _formKey,
        child: Column(
          children: [
            if (detail != null) ListTile(
              minTileHeight: 0,
              subtitle: Text(DictKey.receiptViewOriginalContentLabel.s),
            ),
            if (detail != null) _DetailInfoRow(
              itemDescription: detail.itemDescription,
              unitPrice: Utils.amountToDescription(detail.unitPrice),
              quantity: Utils.amountToDescription(detail.quantity),
              amount: Utils.amountToDescription(detail.amount),
            ),
            ListTile(
              minTileHeight: 0,
              subtitle: Text(DictKey.receiptDetailItemLabel.s),
            ),
            RequiredTextField(
              name: itemDescriptionName,
              initialValue: detail?.itemDescription,
            ),
            ListTile(
              minTileHeight: 0,
              subtitle: Text(DictKey.receiptDetailUnitPriceLabel.s),
            ),
            RequiredTextField(
              name: unitPriceName,
              initialValue: detail?.unitPrice.toString(),
              type: FieldType.number,
            ),
            ListTile(
              minTileHeight: 0,
              subtitle: Text(DictKey.receiptDetailQuantityLabel.s),
            ),
            RequiredTextField(
              name: quantityName,
              initialValue: detail?.quantity.toString(),
              type: FieldType.number,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sortDetails() async {
    assert(!_isCloudPlatform && _details.length > 1);
    await showSortDialog(
      context: context,
      items: _details,
      itemBuilder: (detail) => _DetailInfoRow(
        itemDescription: detail.itemDescription,
        unitPrice: Utils.amountToDescription(detail.unitPrice),
        quantity: Utils.amountToDescription(detail.quantity),
        amount: Utils.amountToDescription(detail.amount),
      ),
      saveOnTap: (items) {
        _details = items;
        _updateInDatabase(true);
      },
    );
  }

  // 適用於特定狀態的前端接口 ---------- >
  // < ---------- 後方函式
  void _updateInDatabase(bool updateDetails) {
    if (!_args.isEdit) return;
    DatabaseServices.receiptDao.upsert(_header, updateDetails ? _details : null);
  }

  VoidCallback? _copyTextToClipboard(String? text) {
    if (text == null || text == '') {
      return () {
        Utils.showToast(DictKey.copiedLabel.s);
      };
    } else {
      return () async {
        await Clipboard.setData(ClipboardData(text: text));
        Utils.showToast('${DictKey.noContentToCopyLabel.s}\n${text.replaceAll('\n', ' ')}');
      };
    }
  }
  // 後方函式 ---------- >

  @override
  Widget build(context) {
    if (!_isInitialized) return const Center(child: CircularProgressIndicator());
    final textTheme = Theme.of(context).textTheme;
    final isCloudPlatform = _isCloudPlatform;
    final periodDescription = InvoicePeriod.fromUnixTime(_header.invoiceInstantDate).toString();
    return Scaffold(
      appBar: AppBar(
        title: Text(_args.isAdd
            ? DictKey.receiptViewAddRecordReceiptLabel.s
            : DictKey.receiptViewRecordReceiptLabel.s
        ),
        actions: [
          if (_args.isEdit) IconButton(
            icon: const Icon(Icons.delete_forever),
            onPressed: _deleteIconPressed,
          ),
          if (_args.isAdd) IconButton(
            icon: const Icon(Icons.check),
            onPressed: _checkIconPressed,
          ),
        ],
      ),
      body: SafeArea(
        child: Scrollbar(
          child: ListView(
            addAutomaticKeepAlives: false,
            addRepaintBoundaries: false,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            children: [
              _ReceiptInfoTile(
                titleText: _header.sellerName,
                subtitleText: DictKey.receiptHeaderSellerNameLabel.s,
                onTap: _normalStringTileVoid(
                  titleText: DictKey.receiptHeaderSellerNameLabel.s,
                  initialValue: _header.sellerName,
                  changed: (value) => _header.sellerName = value
                ),
              ),
              _ReceiptInfoTile(
                titleText: UnitUtils.fullTimeText(_header.invoiceDateTime),
                subtitleText: '${DictKey.receiptHeaderInvoicePeriodLabel.s
                }($periodDescription)\n${DictKey.receiptHeaderTimestampLabel.s}',
                onTap: isCloudPlatform ? null : _selectDateTime,
              ),
              _RowExpandedTile(
                firstWidget: _ReceiptInfoTile(
                  titleText: _header.invoiceNumber,
                  subtitleText: DictKey.receiptHeaderInvoiceNumberLabel.s,
                  onTap: _normalStringTileVoid(
                    titleText: DictKey.receiptHeaderInvoiceNumberLabel.s,
                    initialValue: _header.invoiceNumber,
                    changed: (value) => _header.invoiceNumber = value
                  ),
                ),
                secondWidget: isCloudPlatform ? _ReceiptInfoTile(
                  titleText: _header.invoiceStatus?.locale,
                  subtitleText: DictKey.receiptHeaderInvoiceStatusLabel.s,
                ) : null,
              ),
              _RowExpandedTile(
                firstWidget: _ReceiptInfoTile(
                  titleText: _header.carrierName,
                  subtitleText: DictKey.receiptHeaderCarrierNameLabel.s,
                  onTap: _normalStringTileVoid(
                    titleText: DictKey.receiptHeaderCarrierNameLabel.s,
                    initialValue: _header.carrierName,
                    changed: (value) => _header.carrierName = value
                  ),
                ),
                secondWidget: _ReceiptInfoTile(
                  titleText: _header.carrierType,
                  subtitleText: DictKey.receiptHeaderCarrierTypeLabel.s,
                  onTap: _normalStringTileVoid(
                    titleText: DictKey.receiptHeaderCarrierTypeLabel.s,
                    initialValue: _header.carrierType,
                    changed: (value) => _header.carrierType = value
                  ),
                ),
              ),
              _ReceiptInfoTile(
                titleText: _header.sellerAddress,
                subtitleText: DictKey.receiptHeaderSellerAddressLabel.s,
                onTap: _normalStringTileVoid(
                  titleText: DictKey.receiptHeaderSellerAddressLabel.s,
                  initialValue: _header.sellerAddress,
                  changed: (value) => _header.sellerAddress = value
                ),
              ),
              _RowExpandedTile(
                firstWidget: _ReceiptInfoTile(
                  titleText: _header.sellerBanId,
                  subtitleText: DictKey.receiptHeaderSellerBanIdLabel.s,
                  onTap: _normalStringTileVoid(
                    titleText: DictKey.receiptHeaderSellerBanIdLabel.s,
                    initialValue: _header.sellerBanId,
                    changed: (value) => _header.sellerBanId = value
                  ),
                ),
                secondWidget: _ReceiptInfoTile(
                  titleText: _header.randomNumber,
                  subtitleText: DictKey.receiptHeaderInvoiceRandomNumberLabel.s,
                  onTap: _normalStringTileVoid(
                    titleText: DictKey.receiptHeaderInvoiceRandomNumberLabel.s,
                    initialValue: _header.randomNumber,
                    changed: (value) => _header.randomNumber = value
                  ),
                ),
              ),
              _RowExpandedTile(
                firstWidget: _ReceiptInfoTile(
                  titleText: _header.mainRemark,
                  subtitleText: DictKey.receiptHeaderMainRemarkLabel.s,
                  onTap: _normalStringTileVoid(
                    titleText: DictKey.receiptHeaderMainRemarkLabel.s,
                    initialValue: _header.mainRemark,
                    changed: (value) => _header.mainRemark = value
                  ),
                ),
                secondWidget: _ReceiptInfoTile(
                  titleText: _header.userNote,
                  subtitleText: DictKey.receiptHeaderUserNoteLabel.s,
                  onTap: _normalStringTileVoid(
                    titleText: DictKey.receiptHeaderUserNoteLabel.s,
                    initialValue: _header.userNote,
                    openModifyAllTime: true,
                    changed: (value) => _header.userNote = value
                  ),
                ),
              ),
              _RowExpandedTile(
                equal: true,
                firstWidget: _ReceiptInfoTile(
                  titleText: _header.prizeInformation,
                  subtitleText: DictKey.receiptHeaderPrizeInformationLabel.s,
                ),
                secondWidget: _ReceiptInfoTile(
                  titleText: Utils.amountToDescription(_header.prizeAmount ?? 0),
                  subtitleText: DictKey.receiptHeaderPrizeAmountLabel.s,
                ),
                thirdWidget: _ReceiptInfoTile(
                  titleText: _header.receiptOrigin.locale,
                  subtitleText: DictKey.receiptHeaderReceiptOriginLabel.s,
                  trailing: MyMenuButton(
                    icon: Icon(Icons.arrow_drop_down),
                    items: [
                      MyMenuItem(
                        text: ReceiptOrigin.cloudPlatform.locale,
                        iconData: _header.receiptOrigin == ReceiptOrigin.cloudPlatform
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        onTap: _switchReceiptOrigin(ReceiptOrigin.cloudPlatform),
                      ),
                      MyMenuItem(
                        text: ReceiptOrigin.manualAddition.locale,
                        iconData: _header.receiptOrigin == ReceiptOrigin.manualAddition
                            ? Icons.radio_button_checked
                            : Icons.radio_button_off,
                        onTap: _switchReceiptOrigin(ReceiptOrigin.manualAddition),
                      ),
                    ]
                  ),
                ),
              ),
              _RowExpandedTile(
                equal: true,
                firstWidget: _ReceiptInfoTile(
                  titleText: Utils.amountToDescription(_header.totalAmount),
                  subtitleText: DictKey.receiptHeaderTotalAmountLabel.s,
                ),
                secondWidget: _ReceiptInfoTile(
                  titleText: Utils.amountToDescription(_details.length),
                  subtitleText: DictKey.receiptHeaderItemLengthLabel.s,
                ),
                thirdWidget: _ReceiptInfoTile(
                  titleText: _header.currency,
                  titleNullText: StaticString.currencyNTD,
                  subtitleText: DictKey.receiptHeaderCurrencyLabel.s,
                  onTap: _normalStringTileVoid(
                    titleText: DictKey.receiptHeaderCurrencyLabel.s,
                    initialValue: _header.currency,
                    changed: (value) => _header.currency = value
                  ),
                ),
              ),
              const SizedBox(height: 4),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      _DetailInfoRow(
                        textStyle: textTheme.titleSmall,
                        itemDescription: DictKey.receiptDetailItemLabel.s,
                        unitPrice: DictKey.receiptDetailUnitPriceLabel.s,
                        quantity: DictKey.receiptDetailQuantityLabel.s,
                        amount: DictKey.receiptDetailAmountLabel.s,
                      ),
                      ...List.generate(_details.length, (index) {
                        final detail = _details[index];
                        return _DetailInfoRow(
                          onTap: isCloudPlatform ? null : _oneDetailAddOrModify(index, detail),
                          onLongPress: _copyTextToClipboard(detail.itemDescription),
                          itemDescription: detail.itemDescription,
                          unitPrice: Utils.amountToDescription(detail.unitPrice),
                          quantity: Utils.amountToDescription(detail.quantity),
                          amount: Utils.amountToDescription(detail.amount),
                        );
                      }),
                      if (!isCloudPlatform) Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          if (_details.length > 1) ElevatedButton(
                            onPressed: _sortDetails,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.swap_vert),
                                const SizedBox(width: 4),
                                Text(DictKey.sortLabel.s),
                              ],
                            ),
                          ),
                          ElevatedButton(
                            onPressed: _oneDetailAddOrModify(),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(Icons.add),
                                const SizedBox(width: 4),
                                Text(DictKey.addNewLabel.s),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _RowExpandedTile extends StatelessWidget {
  final Widget firstWidget;
  final Widget? secondWidget;
  final Widget? thirdWidget;
  final bool equal;

  const _RowExpandedTile ({
    required this.firstWidget,
    this.secondWidget,
    this.thirdWidget,
    this.equal = false,
  });

  @override
  Widget build(context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          flex: equal ? 1 : 6,
          child: firstWidget,
        ),
        if (secondWidget != null) Expanded(
          flex: equal ? 1 : 4,
          child: secondWidget!,
        ),
        if (thirdWidget != null) Expanded(
          flex: equal ? 1 : 4,
          child: thirdWidget!,
        ),
      ],
    );
  }
}


class _ReceiptInfoTile extends StatelessWidget {
  final String? titleText;
  final String? titleNullText;
  final String? subtitleText;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _ReceiptInfoTile({
    this.titleText,
    this.titleNullText,
    this.subtitleText,
    this.onTap,
    this.trailing,
  });

  @override
  Widget build(context) {
    final textTheme = Theme.of(context).textTheme;
    return ListTile(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      onTap: onTap,
      visualDensity: VisualDensity.compact,
      contentPadding: const EdgeInsets.symmetric(horizontal: 8),
      title: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titleText ?? titleNullText ?? StaticString.nullString,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyLarge?.copyWith(
              color: (titleText != null) ? null : textTheme.bodyLarge?.color?.withValues(alpha: 0.3),
            ),
          ),
          if (subtitleText != null) Text(
            subtitleText!,
            style: textTheme.bodySmall,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
      trailing: trailing,
    );
  }
}


class _DetailInfoRow extends StatelessWidget {
  final String itemDescription;
  final String unitPrice;
  final String quantity;
  final String amount;
  final TextStyle? textStyle;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _DetailInfoRow({
    required this.itemDescription,
    required this.unitPrice,
    required this.quantity,
    required this.amount,
    this.textStyle,
    this.onTap,
    this.onLongPress,
  });

  @override
  Widget build(context) {
    return InkWell(
      borderRadius: BorderRadius.circular(8.0),
      onTap: onTap,
      onLongPress: onLongPress,
      child: Padding(
        padding: const EdgeInsets.all(2.0),
        child: Row(
          children: [
            Expanded(
              flex: 5,
              child: Text(
                itemDescription,
                style: textStyle,
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                unitPrice,
                textAlign: TextAlign.end,
                style: textStyle,
              ),
            ),
            Expanded(
              flex: 1,
              child: Text(
                quantity,
                textAlign: TextAlign.end,
                style: textStyle,
              ),
            ),
            Expanded(
              flex: 2,
              child: Text(
                amount,
                textAlign: TextAlign.end,
                style: textStyle,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// todo debug: add receipt中 add detail, receipt中無法及時算出並顯示details總額
