import 'package:collection/collection.dart';
import 'package:drift/drift.dart' show Value;
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:receipt_fold/common/router.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/entity/drift/drift_database.dart';
import 'package:receipt_fold/entity/drift/receipt.dart';
import 'package:receipt_fold/entity/period.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/modules/drift_services.dart';
import 'package:receipt_fold/pages/widget/my_text_field.dart';
import 'package:receipt_fold/pages/widget/overlay_show.dart';

class PageReceiptView extends StatefulWidget
    with RouterBridge<PageReceiptViewArgs> {
  const PageReceiptView({super.key});

  @override
  State<PageReceiptView> createState() => _PageReceiptViewState();
}

class PageReceiptViewArgs {
  final Period? period;
  final MapEntry<Receipt, List<ReceiptProduct>>? receiptEntry;

  const PageReceiptViewArgs({this.period, this.receiptEntry});

  bool get isAdd => _check(period != null);

  bool get isEdit => _check(receiptEntry != null);

  bool _check(bool value) {
    assert(
      (period == null) != (receiptEntry == null),
      'PageReceiptViewArgs(period is ${period.runtimeType}, receiptEntry is ${receiptEntry.runtimeType}), 其中一個必須有，另一個必須為空.',
    );
    return value;
  }
}

class _PageReceiptViewState extends State<PageReceiptView> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  late final PageReceiptViewArgs _args = widget.getArgs(context)!;
  late var _products = _args.receiptEntry?.value ?? <ReceiptProduct>[];
  late Receipt _receipt =
      _args.receiptEntry?.key ??
      Receipt(
        issuedAt: _args.period!.start,
        originStatus: OriginStatus.manualEntry,
        totalAmount: 0.0,
        modified: DateTime.now(),
        uuid: UuidMixin.v7.generate(),
      );

  bool get _isCloudPlatform =>
      _receipt.originStatus.sqlValue < OriginStatus.manualImport.sqlValue;

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  // < ---------- 適用於所有狀態的前端接口
  Future<void> _normalStringTileModify({
    required String titleText,
    required String? initialValue,
    bool openModifyAllTime = false,
    required ValueChanged<String?> changed,
  }) {
    const fieldName = 'normalStringField';
    final allowModify = openModifyAllTime ? true : !_isCloudPlatform;

    Future<void> checkModify() async {
      assert(allowModify);
      if (_formKey.currentState?.saveAndValidate() != true) return;
      Navigator.pop(context);
      final String? changedValue = Utils.noEmptyStr(
        _formKey.currentState!.value[fieldName],
      );
      if (changedValue == initialValue) return;
      changed(changedValue);
      await _updateInDatabase();
    }

    return OverlayShow.bottomSheet(
      context: context,
      noCancelButton: true,
      title: ListTile(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(titleText, style: Theme.of(context).textTheme.titleMedium),
        trailing: allowModify
            ? IconButton(onPressed: checkModify, icon: const Icon(Icons.check))
            : null,
      ),
      content: Column(
        children: [
          _ReceiptInfoTile(
            titleText: initialValue,
            subtitleText: DictKey.receiptViewOriginalContent.s,
            trailing: IconButton(
              onPressed: () => Utils.copyText(initialValue),
              icon: const Icon(Icons.copy),
            ),
          ),
          if (allowModify)
            ListTile(
              minTileHeight: 0,
              subtitle: Text(DictKey.receiptViewModify.s),
            ),
          if (allowModify)
            FormBuilder(
              key: _formKey,
              child: MyTextField(
                name: fieldName,
                initialValue: initialValue,
                required: false,
              ),
            ),
        ],
      ),
    );
  }

  // 適用於所有狀態的前端接口 ---------- >
  // < ---------- 適用於特定狀態的前端接口
  Future<void> _deleteIconPressed() {
    assert(_args.isEdit);
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
            await DriftServices.appDb.receiptDao.remove(_receipt);
          },
        ),
      ],
    );
  }

  Future<void> _checkIconPressed() async {
    assert(_args.isAdd);
    Navigator.pop(context);
    await DriftServices.appDb.receiptDao.upsert(_receipt, _products);
  }

  Future<void> _selectDateTime() async {
    assert(!_isCloudPlatform);
    final invoiceDateTime = _receipt.issuedAt;
    Future<DateTime?> datePicker() => showDatePicker(
      context: context,
      initialDate: invoiceDateTime,
      firstDate: DateTime(2011),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    Future<TimeOfDay?> timePicker() => showTimePicker(
      context: context,
      initialTime: TimeOfDay(
        hour: invoiceDateTime.hour,
        minute: invoiceDateTime.minute,
      ),
    );
    final pickedDate = await datePicker();
    if (pickedDate == null) return;
    final pickedTime = await timePicker();
    if (pickedTime == null) return;
    final combinedDateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
      invoiceDateTime.second,
      invoiceDateTime.millisecond,
      invoiceDateTime.microsecond,
    );
    if (combinedDateTime == invoiceDateTime) return;
    _receipt = _receipt.copyWith(issuedAt: combinedDateTime);
    await _updateInDatabase();
  }

  Future<void> _productAddOrModify([int? index, ReceiptProduct? product]) {
    assert(!_isCloudPlatform);
    if ((index == null) != (product == null)) throw 'index, product需要同時有或是同時沒有';
    const descriptionName = 'description';
    const unitPriceName = 'unitPrice';
    const quantityName = 'quantity';
    final isAddNotModify = product == null;

    Future<void> delete() {
      assert(!isAddNotModify);
      if (index == null || product == null) throw 'index不能是null';
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
              _receipt = _receipt.copyWith(
                totalAmount: _receipt.totalAmount - product.amount,
              );
              _products.removeAt(index);
              await _updateInDatabase();
            },
          ),
        ],
      );
    }

    Future<void> checkAddOrModify() async {
      if (_formKey.currentState?.saveAndValidate() != true) return;
      final String itemDescription =
          _formKey.currentState!.value[descriptionName];
      final String unitPriceString =
          _formKey.currentState!.value[unitPriceName];
      final String quantityString = _formKey.currentState!.value[quantityName];
      final double? unitPrice = double.tryParse(unitPriceString);
      final double? quantity = double.tryParse(quantityString);
      if (unitPrice == null || quantity == null || itemDescription.isEmpty) {
        return;
      }
      Navigator.pop(context);
      if (unitPrice == product?.unitPrice &&
          quantity == product?.quantity &&
          itemDescription == product?.description) {
        return;
      }
      final tempProduct =
          (product ??
                  ReceiptProduct(
                    modified: DateTime.now(),
                    uuid: UuidMixin.v7.generate(),
                    receiptUuid: _receipt.uuid,
                    sequence: _products.length + 1,
                    description: '',
                    unitPrice: 0.0,
                    quantity: 0.0,
                    amount: 0.0,
                  ))
              .copyWith(
                description: itemDescription,
                unitPrice: unitPrice,
                quantity: quantity,
                amount: unitPrice * quantity,
              );
      if (index != null) {
        _receipt = _receipt.copyWith(
          totalAmount:
              _receipt.totalAmount -
              _products[index].amount +
              tempProduct.amount,
        );
        _products[index] = tempProduct;
      } else {
        _products.add(tempProduct);
        _receipt = _receipt.copyWith(
          totalAmount: _receipt.totalAmount + tempProduct.amount,
        );
      }
      await _updateInDatabase();
    }

    return OverlayShow.bottomSheet(
      context: context,
      noCancelButton: true,
      title: ListTile(
        leading: IconButton(
          onPressed: () => Navigator.pop(context),
          icon: const Icon(Icons.arrow_back),
        ),
        title: Text(
          DictKey.receiptDetailItem.s,
          style: Theme.of(context).textTheme.titleMedium,
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (!isAddNotModify)
              IconButton(
                onPressed: delete,
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
            if (product != null)
              ListTile(
                minTileHeight: 0,
                subtitle: Text(DictKey.receiptViewOriginalContent.s),
              ),
            if (product != null)
              _ProductInfoRow(
                description: product.description,
                unitPrice: Utils.amountToDescription(product.unitPrice),
                quantity: Utils.amountToDescription(product.quantity),
                amount: Utils.amountToDescription(product.amount),
              ),
            ListTile(
              minTileHeight: 0,
              subtitle: Text(DictKey.receiptDetailItem.s),
            ),
            MyTextField(
              name: descriptionName,
              initialValue: product?.description,
            ),
            ListTile(
              minTileHeight: 0,
              subtitle: Text(DictKey.receiptDetailUnitPrice.s),
            ),
            MyTextField(
              name: unitPriceName,
              initialValue: product?.unitPrice.toString(),
              type: FieldType.number,
            ),
            ListTile(
              minTileHeight: 0,
              subtitle: Text(DictKey.receiptDetailQuantity.s),
            ),
            MyTextField(
              name: quantityName,
              initialValue: product?.quantity.toString(),
              type: FieldType.number,
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _sortProducts() {
    assert(!_isCloudPlatform && _products.length > 1);
    return OverlayShow.sortDialog(
      context: context,
      items: _products,
      itemBuilder: (product) => _ProductInfoRow(
        description: product.description,
        unitPrice: Utils.amountToDescription(product.unitPrice),
        quantity: Utils.amountToDescription(product.quantity),
        amount: Utils.amountToDescription(product.amount),
      ),
      saveOnTap: (items) async {
        _products = items;
        await _updateInDatabase();
      },
    );
  }

  // 適用於特定狀態的前端接口 ---------- >
  // < ---------- 後方函式
  Future<void> _updateInDatabase() async {
    if (_args.isEdit) {
      _receipt = await DriftServices.appDb.receiptDao.upsert(
        _receipt,
        _products,
      );
    }
    setState(() {});
  }

  // 後方函式 ---------- >

  @override
  Widget build(context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _args.isAdd
              ? DictKey.receiptViewAddRecord.s
              : DictKey.receiptViewRecord.s,
        ),
        actions: [
          if (_args.isEdit && !_isCloudPlatform)
            IconButton(
              icon: const Icon(Icons.delete_forever),
              onPressed: _deleteIconPressed,
            ),
          if (_args.isAdd)
            IconButton(
              icon: const Icon(Icons.check),
              onPressed: _checkIconPressed,
            ),
        ],
      ),
      body: SafeArea(
        child: Scrollbar(
          controller: _scrollController,
          child: ListView(
            controller: _scrollController,
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            children: [
              _ReceiptInfoTile(
                titleText: _receipt.sellerName,
                subtitleText: DictKey.receiptHeaderSellerName.s,
                onTap: () => _normalStringTileModify(
                  titleText: DictKey.receiptHeaderSellerName.s,
                  initialValue: _receipt.sellerName,
                  changed: (value) =>
                      _receipt = _receipt.copyWith(sellerName: Value(value)),
                ),
              ),
              _ReceiptInfoTile(
                titleText: UnitUtils.fullTimeText(_receipt.issuedAt),
                subtitleText:
                    '${DictKey.receiptHeaderIssuedPeriod.s} (${Period(_receipt.issuedAt).invString})',
                onTap: _isCloudPlatform ? null : _selectDateTime,
              ),
              _RowExpandedTile(
                firstWidget: _ReceiptInfoTile(
                  titleText: _receipt.invoiceNumber,
                  subtitleText: DictKey.receiptHeaderInvoiceNumber.s,
                  onTap: () => _normalStringTileModify(
                    titleText: DictKey.receiptHeaderInvoiceNumber.s,
                    initialValue: _receipt.invoiceNumber,
                    changed: (value) => _receipt = _receipt.copyWith(
                      invoiceNumber: Value(value),
                    ),
                  ),
                ),
                secondWidget: _ReceiptInfoTile(
                  titleText: _receipt.randomNumber,
                  subtitleText: DictKey.receiptHeaderRandomNumber.s,
                  onTap: () => _normalStringTileModify(
                    titleText: DictKey.receiptHeaderRandomNumber.s,
                    initialValue: _receipt.randomNumber,
                    changed: (value) => _receipt = _receipt.copyWith(
                      randomNumber: Value(value),
                    ),
                  ),
                ),
              ),
              _RowExpandedTile(
                firstWidget: _ReceiptInfoTile(
                  titleText: _receipt.sellerAddress,
                  subtitleText: DictKey.receiptHeaderSellerAddress.s,
                  onTap: () => _normalStringTileModify(
                    titleText: DictKey.receiptHeaderSellerAddress.s,
                    initialValue: _receipt.sellerAddress,
                    changed: (value) => _receipt = _receipt.copyWith(
                      sellerAddress: Value(value),
                    ),
                  ),
                ),
                secondWidget: _ReceiptInfoTile(
                  titleText: _receipt.sellerTaxId,
                  subtitleText: DictKey.receiptHeaderSellerTaxId.s,
                  onTap: () => _normalStringTileModify(
                    titleText: DictKey.receiptHeaderSellerTaxId.s,
                    initialValue: _receipt.sellerTaxId,
                    changed: (value) =>
                        _receipt = _receipt.copyWith(sellerTaxId: Value(value)),
                  ),
                ),
              ),
              _RowExpandedTile(
                firstWidget: _ReceiptInfoTile(
                  titleText: _receipt.userNote,
                  subtitleText: DictKey.receiptHeaderUserNote.s,
                  onTap: () => _normalStringTileModify(
                    titleText: DictKey.receiptHeaderUserNote.s,
                    initialValue: _receipt.userNote,
                    openModifyAllTime: true,
                    changed: (value) =>
                        _receipt = _receipt.copyWith(userNote: Value(value)),
                  ),
                ),
                secondWidget: _ReceiptInfoTile(
                  titleText: _receipt.sellerRemark,
                  subtitleText: DictKey.receiptHeaderSellerRemark.s,
                  onTap: () => _normalStringTileModify(
                    titleText: DictKey.receiptHeaderSellerRemark.s,
                    initialValue: _receipt.sellerRemark,
                    changed: (value) => _receipt = _receipt.copyWith(
                      sellerRemark: Value(value),
                    ),
                  ),
                ),
              ),
              _RowExpandedTile(
                firstWidget: _ReceiptInfoTile(
                  titleText: _receipt.prizeName,
                  subtitleText: DictKey.receiptHeaderPrizeName.s,
                ),
                secondWidget: _ReceiptInfoTile(
                  titleText: Utils.amountToDescription(
                    _receipt.prizeAmount ?? 0,
                  ),
                  subtitleText: DictKey.receiptHeaderPrizeAmount.s,
                ),
              ),

              _RowExpandedTile(
                firstWidget: _ReceiptInfoTile(
                  titleText: _receipt.carrierName,
                  subtitleText: DictKey.receiptHeaderCarrierName.s,
                  onTap: () => _normalStringTileModify(
                    titleText: DictKey.receiptHeaderCarrierName.s,
                    initialValue: _receipt.carrierName,
                    changed: (value) =>
                        _receipt = _receipt.copyWith(carrierName: Value(value)),
                  ),
                ),
                secondWidget: _ReceiptInfoTile(
                  titleText: _receipt.carrierType,
                  subtitleText: DictKey.receiptHeaderCarrierType.s,
                  onTap: () => _normalStringTileModify(
                    titleText: DictKey.receiptHeaderCarrierType.s,
                    initialValue: _receipt.carrierType,
                    changed: (value) =>
                        _receipt = _receipt.copyWith(carrierType: Value(value)),
                  ),
                ),
                thirdWidget: _ReceiptInfoTile(
                  titleText: _receipt.carrierId2,
                  subtitleText: DictKey.receiptHeaderCarrierId2.s,
                  onTap: () => _normalStringTileModify(
                    titleText: DictKey.receiptHeaderCarrierId2.s,
                    initialValue: _receipt.carrierId2,
                    changed: (value) =>
                        _receipt = _receipt.copyWith(carrierId2: Value(value)),
                  ),
                ),
              ),
              _RowExpandedTile(
                firstWidget: _ReceiptInfoTile(
                  titleText: _receipt.originStatus.locale,
                  subtitleText: DictKey.receiptHeaderOriginStatus.s,
                ),
                secondWidget: _ReceiptInfoTile(
                  titleText: Utils.amountToDescription(_receipt.totalAmount),
                  subtitleText: DictKey.receiptHeaderTotalAmount.s,
                ),
                thirdWidget: _ReceiptInfoTile(
                  titleText: Utils.amountToDescription(_products.length),
                  subtitleText: DictKey.receiptHeaderItemLength.s,
                ),
              ),
              const SizedBox(height: 4),
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      _ProductInfoRow(
                        textStyle: textTheme.titleSmall,
                        description: DictKey.receiptDetailItem.s,
                        unitPrice: DictKey.receiptDetailUnitPrice.s,
                        quantity: DictKey.receiptDetailQuantity.s,
                        amount: DictKey.receiptDetailAmount.s,
                      ),
                      ..._products.mapIndexed(
                        (index, product) => _ProductInfoRow(
                          onTap: _isCloudPlatform
                              ? null
                              : () => _productAddOrModify(index, product),
                          onLongPress: () =>
                              Utils.copyText(product.description),
                          description: product.description,
                          unitPrice: Utils.amountToDescription(
                            product.unitPrice,
                          ),
                          quantity: Utils.amountToDescription(product.quantity),
                          amount: Utils.amountToDescription(product.amount),
                        ),
                      ),
                      if (!_isCloudPlatform)
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            if (_products.length > 1)
                              ElevatedButton(
                                onPressed: _sortProducts,
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(Icons.swap_vert),
                                    const SizedBox(width: 4),
                                    Text(DictKey.commonUiSort.s),
                                  ],
                                ),
                              ),
                            ElevatedButton(
                              onPressed: _productAddOrModify,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(Icons.add),
                                  const SizedBox(width: 4),
                                  Text(DictKey.commonUiAdd.s),
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

  const _RowExpandedTile({
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
        Expanded(flex: equal ? 1 : 6, child: firstWidget),
        if (secondWidget != null)
          Expanded(flex: equal ? 1 : 4, child: secondWidget!),
        if (thirdWidget != null)
          Expanded(flex: equal ? 1 : 4, child: thirdWidget!),
      ],
    );
  }
}

class _ReceiptInfoTile extends StatelessWidget {
  final String? titleText;
  final String? subtitleText;
  final VoidCallback? onTap;
  final Widget? trailing;

  const _ReceiptInfoTile({
    this.titleText,
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
            titleText ?? StaticString.nullString,
            overflow: TextOverflow.ellipsis,
            style: textTheme.bodyLarge?.copyWith(
              color: (titleText != null)
                  ? null
                  : textTheme.bodyLarge?.color?.withValues(alpha: 0.3),
            ),
          ),
          if (subtitleText != null)
            Text(
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

class _ProductInfoRow extends StatelessWidget {
  final String description;
  final String unitPrice;
  final String quantity;
  final String amount;
  final TextStyle? textStyle;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;

  const _ProductInfoRow({
    required this.description,
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
            Expanded(flex: 5, child: Text(description, style: textStyle)),
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
              child: Text(quantity, textAlign: TextAlign.end, style: textStyle),
            ),
            Expanded(
              flex: 2,
              child: Text(amount, textAlign: TextAlign.end, style: textStyle),
            ),
          ],
        ),
      ),
    );
  }
}
