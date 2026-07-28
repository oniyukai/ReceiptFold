import 'package:drift/drift.dart'
    show
        GeneratedColumn,
        DriftSqlType,
        ComparableExpr,
        Expression,
        BooleanExpressionOperators,
        StringExpressionOperators;
import 'package:flutter/material.dart';
import 'package:flutter_form_builder/flutter_form_builder.dart';
import 'package:intl/intl.dart';
import 'package:receipt_fold/common/router.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/entity/drift/drift_database.dart';
import 'package:receipt_fold/entity/drift/receipt.dart';
import 'package:receipt_fold/locale/app_language.dart';
import 'package:receipt_fold/modules/drift_services.dart';
import 'package:receipt_fold/pages/menu_recorder/page_search_view.dart';
import 'package:receipt_fold/pages/menu_settings/main_settings_widgets.dart';
import 'package:receipt_fold/pages/widget/my_text_field.dart';

const int _maxSplitString = 4;

class PageSearchForm extends StatefulWidget {
  const PageSearchForm({super.key});

  @override
  State<PageSearchForm> createState() => _PageSearchFormState();
}

class _PageSearchFormState extends State<PageSearchForm> {
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<FormBuilderState> _formKey = GlobalKey<FormBuilderState>();
  final $ReceiptsTable _receiptsTable = DriftServices.appDb.receipts;
  final $ReceiptProductsTable _productsTable =
      DriftServices.appDb.receiptProducts;
  late final _stringDriftColumn = <GeneratedColumn<String>>[
    for (final column in _receiptsTable.$columns)
      if (column is GeneratedColumn<String> &&
          column.driftSqlType == DriftSqlType.string)
        column,
  ];
  int _keywordColumnCount = 1;

  @override
  void dispose() {
    super.dispose();
    _scrollController.dispose();
  }

  void _pressCheck() {
    try {
      _submitForm();
    } catch (e) {
      Utils.showToast('${DictKey.commonUiError.s}: $e');
    }
  }

  void _submitForm() {
    assert(_keywordColumnCount <= _maxSplitString);
    if (_formKey.currentState?.saveAndValidate() != true) return;
    List<String> splitSearchStr(String str) {
      final List<String> list = str
          .split(StaticString.searchSplit)
          .map((s) => s.trim())
          .where((e) => e.isNotEmpty)
          .toSet()
          .toList();
      if (list.length > _maxSplitString) {
        throw Exception(
          Utils.multilingualFiller(DictKey.searchErrorSplit.s, [
            (StaticString.fillObjectNumber, '$_maxSplitString'),
          ]),
        );
      }
      return list;
    }

    final Map<String, dynamic> map = _formKey.currentState!.value;
    final List<OriginStatus> originStatus = map['originStatus'] ?? const [];
    final DateTime? startDate = map['startDate'];
    final DateTime? endDate = map['endDate'];
    final double? minTotalAmount = double.tryParse(map['minTotalAmount'] ?? '');
    final double? maxTotalAmount = double.tryParse(map['maxTotalAmount'] ?? '');
    final double? minPrizeAmount = double.tryParse(map['minPrizeAmount'] ?? '');
    final double? maxPrizeAmount = double.tryParse(map['maxPrizeAmount'] ?? '');
    final List<String> descriptions = splitSearchStr(map['description'] ?? '');
    final columnsScopes = List<List<GeneratedColumn<String>>>.generate(
      _keywordColumnCount,
      (index) => map['scopeColumn$index'] ?? const [],
    );
    final columnsKeywords = List<List<String>>.generate(
      _keywordColumnCount,
      (index) => splitSearchStr(map['keywordColumn$index'] ?? ''),
    );

    if (startDate != null && endDate != null && startDate.isAfter(endDate)) {
      throw Exception(DictKey.searchErrorDateOrder.s);
    } else if (minTotalAmount != null &&
        maxTotalAmount != null &&
        minTotalAmount > maxTotalAmount) {
      throw Exception(DictKey.searchErrorMinMax.s);
    } else if (minPrizeAmount != null &&
        maxPrizeAmount != null &&
        minPrizeAmount > maxPrizeAmount) {
      throw Exception(DictKey.searchErrorMinMax.s);
    }

    MyRouter.of<PageSearchView>().toPass([
      ?originStatus.fold(null, (prev, status) {
        Expression<bool>? statusAnd;
        if (status != OriginStatus.sorted.first) {
          statusAnd = _receiptsTable.originStatus.isBiggerOrEqualValue(
            status.sqlValue,
          );
        }
        if (status != OriginStatus.sorted.last) {
          final endIndex = OriginStatus.sorted.indexOf(status);
          final smaller = _receiptsTable.originStatus.isSmallerThanValue(
            OriginStatus.sorted[endIndex + 1].sqlValue,
          );
          if (statusAnd == null) {
            statusAnd = smaller;
          } else {
            statusAnd &= smaller;
          }
        }
        return prev == null ? statusAnd : prev | statusAnd!;
      }),

      if (startDate != null)
        _receiptsTable.issuedAt.isBiggerOrEqualValue(
          dateTimeConverter.toS(startDate),
        ),
      if (endDate != null)
        _receiptsTable.issuedAt.isSmallerOrEqualValue(
          dateTimeConverter.toS(endDate),
        ),
      if (minTotalAmount != null)
        _receiptsTable.totalAmount.isBiggerOrEqualValue(minTotalAmount),
      if (maxTotalAmount != null)
        _receiptsTable.totalAmount.isSmallerOrEqualValue(maxTotalAmount),
      if (minPrizeAmount != null)
        _receiptsTable.prizeAmount.isBiggerOrEqualValue(minPrizeAmount),
      if (maxPrizeAmount != null)
        _receiptsTable.prizeAmount.isSmallerOrEqualValue(maxPrizeAmount),

      ?descriptions.fold(null, (prev, description) {
        final contains = _productsTable.description.contains(description);
        return prev == null ? contains : prev | contains;
      }),

      ...List.generate(_keywordColumnCount, (index) {
        final keywords = columnsKeywords[index];
        if (keywords.isEmpty) return null;
        final scopes = columnsScopes[index];
        return (scopes.isNotEmpty ? scopes : _stringDriftColumn)
            .fold<Expression<bool>?>(null, (prev, scope) {
              final keywordOr = keywords.fold<Expression<bool>?>(null, (
                prev,
                keyword,
              ) {
                final contains = scope.contains(keyword);
                return prev == null ? contains : prev | contains;
              });
              return prev == null ? keywordOr : prev | keywordOr!;
            });
      }).whereType<Expression<bool>>(),
    ]);
  }

  @override
  Widget build(context) {
    final FormBuilderFields? formFields = _formKey.currentState?.fields;
    return Scaffold(
      appBar: AppBar(
        title: Text(DictKey.searchTitle.s),
        actions: [
          IconButton(onPressed: _pressCheck, icon: const Icon(Icons.check)),
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
                FormBuilderCheckboxGroup<OriginStatus>(
                  name: 'originStatus',
                  decoration: InputDecoration(
                    labelText: DictKey.receiptHeaderOriginStatus.s,
                    border: InputBorder.none,
                  ),
                  options: [
                    for (final value in OriginStatus.values)
                      FormBuilderChipOption(
                        value: value,
                        child: Text(value.locale),
                      ),
                  ],
                ),

                ListTile(
                  minTileHeight: 0,
                  subtitle: Text(DictKey.searchIssuedDate.s),
                ),
                Row(
                  children: [
                    Expanded(
                      child: FormBuilderDateTimePicker(
                        name: 'startDate',
                        inputType: InputType.date,
                        format: DateFormat('yyyy-MM-dd'),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: DictKey.searchDateEarliest.s,
                          prefixIcon: const Icon(Icons.event),
                          suffixIcon: formFields?['startDate']?.value == null
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () =>
                                      formFields?['startDate']?.didChange(null),
                                ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: FormBuilderDateTimePicker(
                        name: 'endDate',
                        inputType: InputType.date,
                        format: DateFormat('yyyy-MM-dd'),
                        onChanged: (_) => setState(() {}),
                        decoration: InputDecoration(
                          labelText: DictKey.searchDateLatest.s,
                          prefixIcon: const Icon(Icons.event),
                          suffixIcon: formFields?['endDate']?.value == null
                              ? null
                              : IconButton(
                                  icon: const Icon(Icons.close),
                                  onPressed: () =>
                                      formFields?['endDate']?.didChange(null),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),

                ListTile(
                  minTileHeight: 0,
                  subtitle: Text(DictKey.receiptHeaderTotalAmount.s),
                ),
                Row(
                  children: [
                    Expanded(
                      child: MyTextField(
                        name: 'minTotalAmount',
                        labelText: DictKey.searchMinValue.s,
                        prefixIconData: Icons.attach_money,
                        required: false,
                        type: FieldType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: MyTextField(
                        name: 'maxTotalAmount',
                        labelText: DictKey.searchMaxValue.s,
                        prefixIconData: Icons.attach_money,
                        required: false,
                        type: FieldType.number,
                      ),
                    ),
                  ],
                ),

                ListTile(
                  minTileHeight: 0,
                  subtitle: Text(DictKey.receiptHeaderPrizeAmount.s),
                ),
                Row(
                  children: [
                    Expanded(
                      child: MyTextField(
                        name: 'minPrizeAmount',
                        labelText: DictKey.searchMinValue.s,
                        prefixIconData: Icons.attach_money,
                        required: false,
                        type: FieldType.number,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: MyTextField(
                        name: 'maxPrizeAmount',
                        labelText: DictKey.searchMaxValue.s,
                        prefixIconData: Icons.attach_money,
                        required: false,
                        type: FieldType.number,
                      ),
                    ),
                  ],
                ),

                ListTile(
                  minTileHeight: 0,
                  subtitle: Text(DictKey.receiptDetailItem.s),
                ),
                MyTextField(
                  name: 'description',
                  labelText: DictKey.searchKeyword.s,
                  required: false,
                ),

                const SizedBox(height: 16),
                ListTilePicker<int>(
                  iconData: Icons.format_list_numbered,
                  text: DictKey.searchColumnCount.s,
                  selectedOption: _keywordColumnCount,
                  optionMap: Map.fromEntries(
                    List.generate(4, (i) => MapEntry(i + 1, '${i + 1}')),
                  ),
                  onChanged: (value) async {
                    setState(() => _keywordColumnCount = value);
                  },
                ),
                ...List.generate(_keywordColumnCount, (index) {
                  return [
                    FormBuilderCheckboxGroup<GeneratedColumn<String>>(
                      name: 'scopeColumn$index',
                      decoration: InputDecoration(
                        labelText:
                            '${DictKey.searchColumnScope.s} ${index + 1}',
                        border: InputBorder.none,
                      ),
                      options: [
                        for (final column in _stringDriftColumn)
                          FormBuilderChipOption(
                            value: column,
                            child: Text(column.name),
                          ),
                      ],
                    ),
                    MyTextField(
                      name: 'keywordColumn$index',
                      labelText: DictKey.searchKeyword.s,
                      required: false,
                    ),
                    const SizedBox(height: 16),
                  ];
                }).expand((ls) => ls),

                Text(DictKey.searchHint.s, textAlign: TextAlign.center),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
