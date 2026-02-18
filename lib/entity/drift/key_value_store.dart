import 'dart:convert';
import 'package:drift/drift.dart';
import 'package:receipt_fold/entity/barcode_item.dart';
import 'package:receipt_fold/entity/drift/drift_database.dart';
import 'package:receipt_fold/entity/invoice_prize.dart';

class KeyValueStores extends Table with ModifiedMixin {
  late final key = text()();
  late final value = text().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}

class KVConverter<R> extends BasicTypeConverter<R?, String?> {
  KVConverter({
    required super.toR,
    required super.toS,
    this.defaultValue,
  });

  final R? defaultValue;

  static KVConverter<int> integer([int? defaultValue]) => KVConverter<int>(
    toR: (fromS) => fromS != null ? int.tryParse(fromS) : null,
    toS: (fromR) => fromR?.toString(),
    defaultValue: defaultValue,
  );

  static KVConverter<double> floating([double? defaultValue]) => KVConverter<double>(
    toR: (fromS) => fromS != null ? double.tryParse(fromS) : null,
    toS: (fromR) => fromR?.toString(),
    defaultValue: defaultValue,
  );

  static KVConverter<String> string([String? defaultValue]) => KVConverter<String>(
    toR: (fromS) => fromS,
    toS: (fromR) => fromR,
    defaultValue: defaultValue,
  );

  static KVConverter<List<String>> listString([List<String>? defaultValue]) => KVConverter<List<String>>(
    toR: (fromS) {
      if (fromS == null) return null;
      try {
        return List<String>.from(jsonDecode(fromS));
      } catch (e) {
        return null;
      }
    },
    toS: (fromR) => fromR != null ? jsonEncode(fromR) : null,
    defaultValue: defaultValue,
  );

  static KVConverter<List<R>> listCustom<R>(R Function(String) itemFromS, String Function(R) itemToS, [List<R>? defaultValue]) =>
      KVConverter<List<R>>(
    toR: (fromS) => listString().toR(fromS)?.map(itemFromS).toList(),
    toS: (fromR) => fromR != null ? jsonEncode(fromR.map(itemToS)) : null,
    defaultValue: defaultValue,
  );
}

enum KVStoreKey {
  mobileBarcodeList,
  memberBarcodeList,
  invoiceWinningNumberList;

  KVConverter<R> getConverter<R>() {
    final converter = switch (this) {
      .mobileBarcodeList => KVConverter.listCustom<MobileBarcodeItem>(
        MobileBarcodeItem.fromString, jsonEncode, [],
      ),
      .memberBarcodeList => KVConverter.listCustom<MemberBarcodeItem>(
        MemberBarcodeItem.fromString, jsonEncode, [],
      ),
      .invoiceWinningNumberList => KVConverter.listCustom<InvoiceWinningNumber>(
        InvoiceWinningNumber.fromString, jsonEncode, [],
      ),
    };
    return converter as KVConverter<R>;
  }
}

class KeyValueStoreDao extends SyncableDao {
  KeyValueStoreDao(super.attachedDatabase);

  $KeyValueStoresTable get _table => attachedDatabase.keyValueStores;

  Future<R?> get<R>(KVStoreKey key, {bool acceptDefault = true}) async {
    final KeyValueStore? row = await (_table.select()
      ..where((tbl) => tbl.key.equals(key.name))
    ).getSingleOrNull();
    final KVConverter<R> converter = key.getConverter<R>();
    final R? value = converter.toR(row?.value);
    return value ?? (acceptDefault ? converter.defaultValue : null);
  }

  Future<R> getExistDefault<R>(KVStoreKey key) async {
    final R? value = await get<R>(key);
    assert(value != null, '$key.${key.getConverter<R>()}.defaultValue cannot be null.');
    return value!;
  }

  Future<int> upsert<R>(KVStoreKey key, R? value) {
    final KVConverter<R> converter = key.getConverter<R>();
    return _table.insertOnConflictUpdate(
      KeyValueStoresCompanion.insert(
        key: key.name,
        value: Value(converter.toS(value)),
        modified: .now(),
      ),
    );
  }

  Future<int> deleteRow(KVStoreKey key) => _table.deleteWhere((tbl) => tbl.key.equals(key.name));


  @override
  Future<void> selfTidy() {
    final Iterable<String> knownKeys = KVStoreKey.values.map((e) => e.name);
    return _table.deleteWhere((tbl) => tbl.key.isNotIn(knownKeys));
  }

  @override
  Future<void> mergeFrom(MyDriftDatabase otherDb) async {
    final List<KeyValueStore> appRows = await _table.select().get();
    final Map<String, KeyValueStore> appRowsMap = {
      for (final KeyValueStore row in appRows)
        row.key: row
    };
    final Set<String> allowUpdateKeys = {
      ...appRowsMap.keys,
      ...KVStoreKey.values.map((e) => e.name),
    };
    if (allowUpdateKeys.isEmpty) return;
    final List<KeyValueStore> otherRows = await (otherDb.keyValueStores.select()
      ..where((tbl) => tbl.key.isIn(allowUpdateKeys))
    ).get();
    await batch((batch) {
      batch.insertAll(
        _table,
        otherRows.where((otherRow) {
          final KeyValueStore? appRow = appRowsMap[otherRow.key];
          return appRow == null || otherRow.modified.isAfter(appRow.modified);
        }),
        mode: .insertOrReplace,
      );
    });
  }
}
