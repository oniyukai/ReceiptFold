import 'dart:convert';
import 'package:collection/collection.dart';
import 'package:drift/drift.dart';
import 'package:receipt_fold/common/utils.dart';
import 'package:receipt_fold/entity/barcode_item.dart';
import 'package:receipt_fold/entity/drift/drift_database.dart';
import 'package:receipt_fold/entity/invoice_carrier.dart';
import 'package:receipt_fold/entity/invoice_prize.dart';
import 'package:receipt_fold/modules/log_service.dart';

class KeyValueStores extends Table with ModifiedMixin {
  late final key = text()();
  late final value = text().nullable()();

  @override
  Set<Column> get primaryKey => {key};
}

/// 這是專門給 [KeyValueStores] 的 [TypeConverter].
///
/// 當 [KeyValueStores] 中不存在 [KeyValueStore] 或是該 [KeyValueStore.value] 本身為 null 時,
/// 也會給 [toR] 處理, 一般上都會對應轉換到 null, 這時 [KeyValueStoreDao] 就會將 [defaultValue] 回傳以替換 null.
class KVConverter<R> extends BasicTypeConverter<R?, String?> {
  final R? Function()? _defaultValue;

  R? get defaultValue => _defaultValue?.call();

  KVConverter({required super.toS, required super.toR, this._defaultValue});

  static KVConverter<bool> boolean([bool? defaultValue]) => KVConverter<bool>(
    toS: (fromR) => fromR?.toString(),
    toR: (fromS) => fromS != null ? bool.tryParse(fromS) : null,
    defaultValue: () => defaultValue,
  );

  static KVConverter<int> integer([int? defaultValue]) => KVConverter<int>(
    toS: (fromR) => fromR?.toString(),
    toR: (fromS) => fromS != null ? int.tryParse(fromS) : null,
    defaultValue: () => defaultValue,
  );

  static KVConverter<double> floating([double? defaultValue]) =>
      KVConverter<double>(
        toS: (fromR) => fromR?.toString(),
        toR: (fromS) => fromS != null ? double.tryParse(fromS) : null,
        defaultValue: () => defaultValue,
      );

  static KVConverter<String> string([String? defaultValue]) =>
      KVConverter<String>(
        toS: (fromR) => fromR,
        toR: (fromS) => fromS,
        defaultValue: () => defaultValue,
      );

  static KVConverter<List<String>> listString([List<String>? defaultValue]) =>
      KVConverter<List<String>>(
        toS: (fromR) => fromR != null ? jsonEncode(fromR) : null,
        toR: (fromS) {
          if (fromS == null) return null;
          try {
            return List<String>.from(jsonDecode(fromS));
          } catch (e) {
            LogService(
              'listString.toR',
              errorObject: e,
              classType: KVConverter<List<String>>,
            ).w();
            return null;
          }
        },
        defaultValue: () => defaultValue?.toList(),
      );

  static KVConverter<List<R>> listCustom<R>(
    String Function(R) itemToS,
    R Function(String) itemToR, [
    List<R>? defaultValue,
  ]) {
    final KVConverter<List<String>> lsConverter = listString();
    return KVConverter<List<R>>(
      toS: (fromR) => lsConverter.toS(fromR?.map(itemToS).toList()),
      toR: (fromS) => lsConverter.toR(fromS)?.map(itemToR).toList(),
      defaultValue: () => defaultValue?.toList(),
    );
  }
}

enum KVStoreKey {
  mobileBarcodeList,
  memberBarcodeList,
  invoicePrizeAwardList,
  invoiceCarrierList;

  static final _converterCache = <KVStoreKey, KVConverter>{};

  KVConverter<R> _getConverter<R>() =>
      _converterCache.putIfAbsent(this, () {
            final converter = switch (this) {
              mobileBarcodeList => KVConverter.listCustom<MobileBarcodeItem>(
                jsonEncode,
                MobileBarcodeItem.fromString,
                const [],
              ),
              memberBarcodeList => KVConverter.listCustom<MemberBarcodeItem>(
                jsonEncode,
                MemberBarcodeItem.fromString,
                const [],
              ),
              invoicePrizeAwardList =>
                KVConverter.listCustom<InvoicePrizeAward>(
                  jsonEncode,
                  InvoicePrizeAward.fromString,
                  const [],
                ),
              invoiceCarrierList => KVConverter.listCustom<InvoiceCarrier>(
                jsonEncode,
                InvoiceCarrier.fromString,
                const [],
              ),
            };
            return converter;
          })
          as KVConverter<R>;
}

class KeyValueStoreDao extends SyncableDao {
  KeyValueStoreDao(super.attachedDatabase);

  $KeyValueStoresTable get _stores => attachedDatabase.keyValueStores;

  Stream<Map<KVStoreKey, dynamic>> stream(Iterable<KVStoreKey> keys) {
    final keyConverterMap = Map.fromEntries(
      keys.map((key) => MapEntry(key, key._getConverter())),
    );
    final keyNames = keyConverterMap.keys.map((key) => key.name);
    return (_stores.select()
          ..where((tbl) => tbl.key.isIn(keyNames))
          ..orderBy([(tbl) => OrderingTerm(expression: tbl.key)]))
        .watch()
        .distinct(const ListEquality().equals)
        .map(((kvStores) {
          final resultMap = <KVStoreKey, dynamic>{};
          for (final kvStore in kvStores) {
            final key = KVStoreKey.values.fromName(kvStore.key)!;
            final converter = keyConverterMap[key]!;
            resultMap[key] =
                converter.toR(kvStore.value) ?? converter.defaultValue;
          }
          keyConverterMap.forEach(
            (key, converter) => resultMap[key] ??= converter.defaultValue,
          );
          return resultMap;
        }));
  }

  Future<R?> get<R>(KVStoreKey key) async {
    final kvStore =
        await (_stores.select()..where((tbl) => tbl.key.equals(key.name)))
            .getSingleOrNull();
    final converter = key._getConverter<R>();
    return converter.toR(kvStore?.value) ?? converter.defaultValue;
  }

  Future<R> getExistDefault<R>(KVStoreKey key) async {
    final value = await get<R>(key);
    assert(
      value != null,
      '$key.${key._getConverter<R>()}.defaultValue cannot be null.',
    );
    return value!;
  }

  /// 如果設定 [value] 為 null 預期會變成預設值, 這代表要設定跟隨預設, 如果要執行還原預設請參照 [deleteRow]
  Future<void> upsert<R>(KVStoreKey key, R? value) {
    return transaction(() async {
      await _stores.insertOnConflictUpdate(
        KeyValueStoresCompanion.insert(
          key: key.name,
          value: Value(key._getConverter().toS(value)),
          modified: Value(DateTime.now()),
        ),
      );
    });
  }

  Future<int> deleteRow(KVStoreKey key) =>
      transaction(() => _stores.deleteWhere((tbl) => tbl.key.equals(key.name)));

  @override
  Future<void> selfTidy() {
    final knownKeys = KVStoreKey.values.map((e) => e.name);
    return _stores.deleteWhere((tbl) => tbl.key.isNotIn(knownKeys));
  }

  @override
  Future<void> mergeFrom(MyDriftDatabase otherDb) async {
    final keyModifiedMap = Map.fromEntries(
      await (_stores.selectOnly()..addColumns([_stores.key, _stores.modified]))
          .map(
            (row) =>
                MapEntry(row.read(_stores.key)!, row.read(_stores.modified)!),
          )
          .get(),
    );
    final allowUpdateKeys = <String>{
      ...keyModifiedMap.keys,
      ...KVStoreKey.values.map((e) => e.name),
    };
    if (allowUpdateKeys.isEmpty) return;
    final otherKVStores = await Future.wait(
      allowUpdateKeys
          .slices(chunkSize)
          .map(
            (chunk) =>
                (otherDb.keyValueStores.select()
                      ..where((tbl) => tbl.key.isIn(chunk)))
                    .get(),
          ),
    ).then((value) => value.expand((ls) => ls));
    await batch((batch) {
      batch.insertAllOnConflictUpdate(
        _stores,
        otherKVStores.where((otherKVStore) {
          final modified = keyModifiedMap[otherKVStore.key];
          return modified == null ||
              otherKVStore.modified.isAfter(dateTimeConverter.toR(modified));
        }),
      );
    });
  }
}
