// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'drift_database.dart';

// ignore_for_file: type=lint
class $KeyValueStoresTable extends KeyValueStores
    with TableInfo<$KeyValueStoresTable, KeyValueStore> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $KeyValueStoresTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> modified =
      GeneratedColumn<int>(
        'modified',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($KeyValueStoresTable.$convertermodified);
  static const VerificationMeta _keyMeta = const VerificationMeta('key');
  @override
  late final GeneratedColumn<String> key = GeneratedColumn<String>(
    'key',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueMeta = const VerificationMeta('value');
  @override
  late final GeneratedColumn<String> value = GeneratedColumn<String>(
    'value',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [modified, key, value];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'key_value_stores';
  @override
  VerificationContext validateIntegrity(
    Insertable<KeyValueStore> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('key')) {
      context.handle(
        _keyMeta,
        key.isAcceptableOrUnknown(data['key']!, _keyMeta),
      );
    } else if (isInserting) {
      context.missing(_keyMeta);
    }
    if (data.containsKey('value')) {
      context.handle(
        _valueMeta,
        value.isAcceptableOrUnknown(data['value']!, _valueMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {key};
  @override
  KeyValueStore map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return KeyValueStore(
      modified: $KeyValueStoresTable.$convertermodified.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}modified'],
        )!,
      ),
      key: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}key'],
      )!,
      value: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value'],
      ),
    );
  }

  @override
  $KeyValueStoresTable createAlias(String alias) {
    return $KeyValueStoresTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertermodified = dateTimeConverter;
}

class KeyValueStore extends DataClass implements Insertable<KeyValueStore> {
  final DateTime modified;
  final String key;
  final String? value;
  const KeyValueStore({required this.modified, required this.key, this.value});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['modified'] = Variable<int>(
        $KeyValueStoresTable.$convertermodified.toSql(modified),
      );
    }
    map['key'] = Variable<String>(key);
    if (!nullToAbsent || value != null) {
      map['value'] = Variable<String>(value);
    }
    return map;
  }

  KeyValueStoresCompanion toCompanion(bool nullToAbsent) {
    return KeyValueStoresCompanion(
      modified: Value(modified),
      key: Value(key),
      value: value == null && nullToAbsent
          ? const Value.absent()
          : Value(value),
    );
  }

  factory KeyValueStore.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return KeyValueStore(
      modified: serializer.fromJson<DateTime>(json['modified']),
      key: serializer.fromJson<String>(json['key']),
      value: serializer.fromJson<String?>(json['value']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'modified': serializer.toJson<DateTime>(modified),
      'key': serializer.toJson<String>(key),
      'value': serializer.toJson<String?>(value),
    };
  }

  KeyValueStore copyWith({
    DateTime? modified,
    String? key,
    Value<String?> value = const Value.absent(),
  }) => KeyValueStore(
    modified: modified ?? this.modified,
    key: key ?? this.key,
    value: value.present ? value.value : this.value,
  );
  KeyValueStore copyWithCompanion(KeyValueStoresCompanion data) {
    return KeyValueStore(
      modified: data.modified.present ? data.modified.value : this.modified,
      key: data.key.present ? data.key.value : this.key,
      value: data.value.present ? data.value.value : this.value,
    );
  }

  @override
  String toString() {
    return (StringBuffer('KeyValueStore(')
          ..write('modified: $modified, ')
          ..write('key: $key, ')
          ..write('value: $value')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(modified, key, value);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is KeyValueStore &&
          other.modified == this.modified &&
          other.key == this.key &&
          other.value == this.value);
}

class KeyValueStoresCompanion extends UpdateCompanion<KeyValueStore> {
  final Value<DateTime> modified;
  final Value<String> key;
  final Value<String?> value;
  final Value<int> rowid;
  const KeyValueStoresCompanion({
    this.modified = const Value.absent(),
    this.key = const Value.absent(),
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  KeyValueStoresCompanion.insert({
    required DateTime modified,
    required String key,
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : modified = Value(modified),
       key = Value(key);
  static Insertable<KeyValueStore> custom({
    Expression<int>? modified,
    Expression<String>? key,
    Expression<String>? value,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (modified != null) 'modified': modified,
      if (key != null) 'key': key,
      if (value != null) 'value': value,
      if (rowid != null) 'rowid': rowid,
    });
  }

  KeyValueStoresCompanion copyWith({
    Value<DateTime>? modified,
    Value<String>? key,
    Value<String?>? value,
    Value<int>? rowid,
  }) {
    return KeyValueStoresCompanion(
      modified: modified ?? this.modified,
      key: key ?? this.key,
      value: value ?? this.value,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (modified.present) {
      map['modified'] = Variable<int>(
        $KeyValueStoresTable.$convertermodified.toSql(modified.value),
      );
    }
    if (key.present) {
      map['key'] = Variable<String>(key.value);
    }
    if (value.present) {
      map['value'] = Variable<String>(value.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('KeyValueStoresCompanion(')
          ..write('modified: $modified, ')
          ..write('key: $key, ')
          ..write('value: $value, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReceiptsTable extends Receipts with TableInfo<$ReceiptsTable, Receipt> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReceiptsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> modified =
      GeneratedColumn<int>(
        'modified',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ReceiptsTable.$convertermodified);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 36),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _valueStringMeta = const VerificationMeta(
    'valueString',
  );
  @override
  late final GeneratedColumn<String> valueString = GeneratedColumn<String>(
    'value_string',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [modified, uuid, valueString];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'receipts';
  @override
  VerificationContext validateIntegrity(
    Insertable<Receipt> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    } else if (isInserting) {
      context.missing(_uuidMeta);
    }
    if (data.containsKey('value_string')) {
      context.handle(
        _valueStringMeta,
        valueString.isAcceptableOrUnknown(
          data['value_string']!,
          _valueStringMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_valueStringMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  Receipt map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return Receipt(
      modified: $ReceiptsTable.$convertermodified.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}modified'],
        )!,
      ),
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      valueString: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}value_string'],
      )!,
    );
  }

  @override
  $ReceiptsTable createAlias(String alias) {
    return $ReceiptsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertermodified = dateTimeConverter;
}

class Receipt extends DataClass implements Insertable<Receipt> {
  final DateTime modified;
  final String uuid;
  final String valueString;
  const Receipt({
    required this.modified,
    required this.uuid,
    required this.valueString,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['modified'] = Variable<int>(
        $ReceiptsTable.$convertermodified.toSql(modified),
      );
    }
    map['uuid'] = Variable<String>(uuid);
    map['value_string'] = Variable<String>(valueString);
    return map;
  }

  ReceiptsCompanion toCompanion(bool nullToAbsent) {
    return ReceiptsCompanion(
      modified: Value(modified),
      uuid: Value(uuid),
      valueString: Value(valueString),
    );
  }

  factory Receipt.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return Receipt(
      modified: serializer.fromJson<DateTime>(json['modified']),
      uuid: serializer.fromJson<String>(json['uuid']),
      valueString: serializer.fromJson<String>(json['valueString']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'modified': serializer.toJson<DateTime>(modified),
      'uuid': serializer.toJson<String>(uuid),
      'valueString': serializer.toJson<String>(valueString),
    };
  }

  Receipt copyWith({DateTime? modified, String? uuid, String? valueString}) =>
      Receipt(
        modified: modified ?? this.modified,
        uuid: uuid ?? this.uuid,
        valueString: valueString ?? this.valueString,
      );
  Receipt copyWithCompanion(ReceiptsCompanion data) {
    return Receipt(
      modified: data.modified.present ? data.modified.value : this.modified,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      valueString: data.valueString.present
          ? data.valueString.value
          : this.valueString,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Receipt(')
          ..write('modified: $modified, ')
          ..write('uuid: $uuid, ')
          ..write('valueString: $valueString')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(modified, uuid, valueString);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Receipt &&
          other.modified == this.modified &&
          other.uuid == this.uuid &&
          other.valueString == this.valueString);
}

class ReceiptsCompanion extends UpdateCompanion<Receipt> {
  final Value<DateTime> modified;
  final Value<String> uuid;
  final Value<String> valueString;
  final Value<int> rowid;
  const ReceiptsCompanion({
    this.modified = const Value.absent(),
    this.uuid = const Value.absent(),
    this.valueString = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReceiptsCompanion.insert({
    required DateTime modified,
    required String uuid,
    required String valueString,
    this.rowid = const Value.absent(),
  }) : modified = Value(modified),
       uuid = Value(uuid),
       valueString = Value(valueString);
  static Insertable<Receipt> custom({
    Expression<int>? modified,
    Expression<String>? uuid,
    Expression<String>? valueString,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (modified != null) 'modified': modified,
      if (uuid != null) 'uuid': uuid,
      if (valueString != null) 'value_string': valueString,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReceiptsCompanion copyWith({
    Value<DateTime>? modified,
    Value<String>? uuid,
    Value<String>? valueString,
    Value<int>? rowid,
  }) {
    return ReceiptsCompanion(
      modified: modified ?? this.modified,
      uuid: uuid ?? this.uuid,
      valueString: valueString ?? this.valueString,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (modified.present) {
      map['modified'] = Variable<int>(
        $ReceiptsTable.$convertermodified.toSql(modified.value),
      );
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (valueString.present) {
      map['value_string'] = Variable<String>(valueString.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptsCompanion(')
          ..write('modified: $modified, ')
          ..write('uuid: $uuid, ')
          ..write('valueString: $valueString, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$MyDriftDatabase extends GeneratedDatabase {
  _$MyDriftDatabase(QueryExecutor e) : super(e);
  $MyDriftDatabaseManager get managers => $MyDriftDatabaseManager(this);
  late final $KeyValueStoresTable keyValueStores = $KeyValueStoresTable(this);
  late final $ReceiptsTable receipts = $ReceiptsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    keyValueStores,
    receipts,
  ];
}

typedef $$KeyValueStoresTableCreateCompanionBuilder =
    KeyValueStoresCompanion Function({
      required DateTime modified,
      required String key,
      Value<String?> value,
      Value<int> rowid,
    });
typedef $$KeyValueStoresTableUpdateCompanionBuilder =
    KeyValueStoresCompanion Function({
      Value<DateTime> modified,
      Value<String> key,
      Value<String?> value,
      Value<int> rowid,
    });

class $$KeyValueStoresTableFilterComposer
    extends Composer<_$MyDriftDatabase, $KeyValueStoresTable> {
  $$KeyValueStoresTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get modified =>
      $composableBuilder(
        column: $table.modified,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnFilters(column),
  );
}

class $$KeyValueStoresTableOrderingComposer
    extends Composer<_$MyDriftDatabase, $KeyValueStoresTable> {
  $$KeyValueStoresTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get modified => $composableBuilder(
    column: $table.modified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get key => $composableBuilder(
    column: $table.key,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get value => $composableBuilder(
    column: $table.value,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$KeyValueStoresTableAnnotationComposer
    extends Composer<_$MyDriftDatabase, $KeyValueStoresTable> {
  $$KeyValueStoresTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<DateTime, int> get modified =>
      $composableBuilder(column: $table.modified, builder: (column) => column);

  GeneratedColumn<String> get key =>
      $composableBuilder(column: $table.key, builder: (column) => column);

  GeneratedColumn<String> get value =>
      $composableBuilder(column: $table.value, builder: (column) => column);
}

class $$KeyValueStoresTableTableManager
    extends
        RootTableManager<
          _$MyDriftDatabase,
          $KeyValueStoresTable,
          KeyValueStore,
          $$KeyValueStoresTableFilterComposer,
          $$KeyValueStoresTableOrderingComposer,
          $$KeyValueStoresTableAnnotationComposer,
          $$KeyValueStoresTableCreateCompanionBuilder,
          $$KeyValueStoresTableUpdateCompanionBuilder,
          (
            KeyValueStore,
            BaseReferences<
              _$MyDriftDatabase,
              $KeyValueStoresTable,
              KeyValueStore
            >,
          ),
          KeyValueStore,
          PrefetchHooks Function()
        > {
  $$KeyValueStoresTableTableManager(
    _$MyDriftDatabase db,
    $KeyValueStoresTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$KeyValueStoresTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$KeyValueStoresTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$KeyValueStoresTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> modified = const Value.absent(),
                Value<String> key = const Value.absent(),
                Value<String?> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KeyValueStoresCompanion(
                modified: modified,
                key: key,
                value: value,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required DateTime modified,
                required String key,
                Value<String?> value = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => KeyValueStoresCompanion.insert(
                modified: modified,
                key: key,
                value: value,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$KeyValueStoresTableProcessedTableManager =
    ProcessedTableManager<
      _$MyDriftDatabase,
      $KeyValueStoresTable,
      KeyValueStore,
      $$KeyValueStoresTableFilterComposer,
      $$KeyValueStoresTableOrderingComposer,
      $$KeyValueStoresTableAnnotationComposer,
      $$KeyValueStoresTableCreateCompanionBuilder,
      $$KeyValueStoresTableUpdateCompanionBuilder,
      (
        KeyValueStore,
        BaseReferences<_$MyDriftDatabase, $KeyValueStoresTable, KeyValueStore>,
      ),
      KeyValueStore,
      PrefetchHooks Function()
    >;
typedef $$ReceiptsTableCreateCompanionBuilder =
    ReceiptsCompanion Function({
      required DateTime modified,
      required String uuid,
      required String valueString,
      Value<int> rowid,
    });
typedef $$ReceiptsTableUpdateCompanionBuilder =
    ReceiptsCompanion Function({
      Value<DateTime> modified,
      Value<String> uuid,
      Value<String> valueString,
      Value<int> rowid,
    });

class $$ReceiptsTableFilterComposer
    extends Composer<_$MyDriftDatabase, $ReceiptsTable> {
  $$ReceiptsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get modified =>
      $composableBuilder(
        column: $table.modified,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get valueString => $composableBuilder(
    column: $table.valueString,
    builder: (column) => ColumnFilters(column),
  );
}

class $$ReceiptsTableOrderingComposer
    extends Composer<_$MyDriftDatabase, $ReceiptsTable> {
  $$ReceiptsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<int> get modified => $composableBuilder(
    column: $table.modified,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get uuid => $composableBuilder(
    column: $table.uuid,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get valueString => $composableBuilder(
    column: $table.valueString,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$ReceiptsTableAnnotationComposer
    extends Composer<_$MyDriftDatabase, $ReceiptsTable> {
  $$ReceiptsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumnWithTypeConverter<DateTime, int> get modified =>
      $composableBuilder(column: $table.modified, builder: (column) => column);

  GeneratedColumn<String> get uuid =>
      $composableBuilder(column: $table.uuid, builder: (column) => column);

  GeneratedColumn<String> get valueString => $composableBuilder(
    column: $table.valueString,
    builder: (column) => column,
  );
}

class $$ReceiptsTableTableManager
    extends
        RootTableManager<
          _$MyDriftDatabase,
          $ReceiptsTable,
          Receipt,
          $$ReceiptsTableFilterComposer,
          $$ReceiptsTableOrderingComposer,
          $$ReceiptsTableAnnotationComposer,
          $$ReceiptsTableCreateCompanionBuilder,
          $$ReceiptsTableUpdateCompanionBuilder,
          (Receipt, BaseReferences<_$MyDriftDatabase, $ReceiptsTable, Receipt>),
          Receipt,
          PrefetchHooks Function()
        > {
  $$ReceiptsTableTableManager(_$MyDriftDatabase db, $ReceiptsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReceiptsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReceiptsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReceiptsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> modified = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> valueString = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReceiptsCompanion(
                modified: modified,
                uuid: uuid,
                valueString: valueString,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required DateTime modified,
                required String uuid,
                required String valueString,
                Value<int> rowid = const Value.absent(),
              }) => ReceiptsCompanion.insert(
                modified: modified,
                uuid: uuid,
                valueString: valueString,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ReceiptsTableProcessedTableManager =
    ProcessedTableManager<
      _$MyDriftDatabase,
      $ReceiptsTable,
      Receipt,
      $$ReceiptsTableFilterComposer,
      $$ReceiptsTableOrderingComposer,
      $$ReceiptsTableAnnotationComposer,
      $$ReceiptsTableCreateCompanionBuilder,
      $$ReceiptsTableUpdateCompanionBuilder,
      (Receipt, BaseReferences<_$MyDriftDatabase, $ReceiptsTable, Receipt>),
      Receipt,
      PrefetchHooks Function()
    >;

class $MyDriftDatabaseManager {
  final _$MyDriftDatabase _db;
  $MyDriftDatabaseManager(this._db);
  $$KeyValueStoresTableTableManager get keyValueStores =>
      $$KeyValueStoresTableTableManager(_db, _db.keyValueStores);
  $$ReceiptsTableTableManager get receipts =>
      $$ReceiptsTableTableManager(_db, _db.receipts);
}
