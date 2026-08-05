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
        requiredDuringInsert: false,
        clientDefault: () => UnitUtils.nowUnixTime,
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
    this.modified = const Value.absent(),
    required String key,
    this.value = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : key = Value(key);
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
        requiredDuringInsert: false,
        clientDefault: () => UnitUtils.nowUnixTime,
      ).withConverter<DateTime>($ReceiptsTable.$convertermodified);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 36),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => UuidMixin.v7.generate(),
  );
  @override
  late final GeneratedColumnWithTypeConverter<OriginStatus, int> originStatus =
      GeneratedColumn<int>(
        'origin_status',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<OriginStatus>($ReceiptsTable.$converteroriginStatus);
  static const VerificationMeta _userNoteMeta = const VerificationMeta(
    'userNote',
  );
  @override
  late final GeneratedColumn<String> userNote = GeneratedColumn<String>(
    'user_note',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> issuedAt =
      GeneratedColumn<int>(
        'issued_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($ReceiptsTable.$converterissuedAt);
  static const VerificationMeta _totalAmountMeta = const VerificationMeta(
    'totalAmount',
  );
  @override
  late final GeneratedColumn<double> totalAmount = GeneratedColumn<double>(
    'total_amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _invoiceNumberMeta = const VerificationMeta(
    'invoiceNumber',
  );
  @override
  late final GeneratedColumn<String> invoiceNumber = GeneratedColumn<String>(
    'invoice_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _randomNumberMeta = const VerificationMeta(
    'randomNumber',
  );
  @override
  late final GeneratedColumn<String> randomNumber = GeneratedColumn<String>(
    'random_number',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _carrierNameMeta = const VerificationMeta(
    'carrierName',
  );
  @override
  late final GeneratedColumn<String> carrierName = GeneratedColumn<String>(
    'carrier_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _carrierTypeMeta = const VerificationMeta(
    'carrierType',
  );
  @override
  late final GeneratedColumn<String> carrierType = GeneratedColumn<String>(
    'carrier_type',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _carrierId2Meta = const VerificationMeta(
    'carrierId2',
  );
  @override
  late final GeneratedColumn<String> carrierId2 = GeneratedColumn<String>(
    'carrier_id2',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sellerNameMeta = const VerificationMeta(
    'sellerName',
  );
  @override
  late final GeneratedColumn<String> sellerName = GeneratedColumn<String>(
    'seller_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sellerTaxIdMeta = const VerificationMeta(
    'sellerTaxId',
  );
  @override
  late final GeneratedColumn<String> sellerTaxId = GeneratedColumn<String>(
    'seller_tax_id',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sellerAddressMeta = const VerificationMeta(
    'sellerAddress',
  );
  @override
  late final GeneratedColumn<String> sellerAddress = GeneratedColumn<String>(
    'seller_address',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _sellerRemarkMeta = const VerificationMeta(
    'sellerRemark',
  );
  @override
  late final GeneratedColumn<String> sellerRemark = GeneratedColumn<String>(
    'seller_remark',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _prizeNameMeta = const VerificationMeta(
    'prizeName',
  );
  @override
  late final GeneratedColumn<String> prizeName = GeneratedColumn<String>(
    'prize_name',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _prizeAmountMeta = const VerificationMeta(
    'prizeAmount',
  );
  @override
  late final GeneratedColumn<double> prizeAmount = GeneratedColumn<double>(
    'prize_amount',
    aliasedName,
    true,
    type: DriftSqlType.double,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _invoiceJsonSummaryMeta =
      const VerificationMeta('invoiceJsonSummary');
  @override
  late final GeneratedColumn<String> invoiceJsonSummary =
      GeneratedColumn<String>(
        'invoice_json_summary',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _invoiceJsonDataMeta = const VerificationMeta(
    'invoiceJsonData',
  );
  @override
  late final GeneratedColumn<String> invoiceJsonData = GeneratedColumn<String>(
    'invoice_json_data',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _invoiceJsonDetailMeta = const VerificationMeta(
    'invoiceJsonDetail',
  );
  @override
  late final GeneratedColumn<String> invoiceJsonDetail =
      GeneratedColumn<String>(
        'invoice_json_detail',
        aliasedName,
        true,
        type: DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const VerificationMeta _invoiceJsonAwardMeta = const VerificationMeta(
    'invoiceJsonAward',
  );
  @override
  late final GeneratedColumn<String> invoiceJsonAward = GeneratedColumn<String>(
    'invoice_json_award',
    aliasedName,
    true,
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  List<GeneratedColumn> get $columns => [
    modified,
    uuid,
    originStatus,
    userNote,
    issuedAt,
    totalAmount,
    invoiceNumber,
    randomNumber,
    carrierName,
    carrierType,
    carrierId2,
    sellerName,
    sellerTaxId,
    sellerAddress,
    sellerRemark,
    prizeName,
    prizeAmount,
    invoiceJsonSummary,
    invoiceJsonData,
    invoiceJsonDetail,
    invoiceJsonAward,
  ];
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
    }
    if (data.containsKey('user_note')) {
      context.handle(
        _userNoteMeta,
        userNote.isAcceptableOrUnknown(data['user_note']!, _userNoteMeta),
      );
    }
    if (data.containsKey('total_amount')) {
      context.handle(
        _totalAmountMeta,
        totalAmount.isAcceptableOrUnknown(
          data['total_amount']!,
          _totalAmountMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_totalAmountMeta);
    }
    if (data.containsKey('invoice_number')) {
      context.handle(
        _invoiceNumberMeta,
        invoiceNumber.isAcceptableOrUnknown(
          data['invoice_number']!,
          _invoiceNumberMeta,
        ),
      );
    }
    if (data.containsKey('random_number')) {
      context.handle(
        _randomNumberMeta,
        randomNumber.isAcceptableOrUnknown(
          data['random_number']!,
          _randomNumberMeta,
        ),
      );
    }
    if (data.containsKey('carrier_name')) {
      context.handle(
        _carrierNameMeta,
        carrierName.isAcceptableOrUnknown(
          data['carrier_name']!,
          _carrierNameMeta,
        ),
      );
    }
    if (data.containsKey('carrier_type')) {
      context.handle(
        _carrierTypeMeta,
        carrierType.isAcceptableOrUnknown(
          data['carrier_type']!,
          _carrierTypeMeta,
        ),
      );
    }
    if (data.containsKey('carrier_id2')) {
      context.handle(
        _carrierId2Meta,
        carrierId2.isAcceptableOrUnknown(data['carrier_id2']!, _carrierId2Meta),
      );
    }
    if (data.containsKey('seller_name')) {
      context.handle(
        _sellerNameMeta,
        sellerName.isAcceptableOrUnknown(data['seller_name']!, _sellerNameMeta),
      );
    }
    if (data.containsKey('seller_tax_id')) {
      context.handle(
        _sellerTaxIdMeta,
        sellerTaxId.isAcceptableOrUnknown(
          data['seller_tax_id']!,
          _sellerTaxIdMeta,
        ),
      );
    }
    if (data.containsKey('seller_address')) {
      context.handle(
        _sellerAddressMeta,
        sellerAddress.isAcceptableOrUnknown(
          data['seller_address']!,
          _sellerAddressMeta,
        ),
      );
    }
    if (data.containsKey('seller_remark')) {
      context.handle(
        _sellerRemarkMeta,
        sellerRemark.isAcceptableOrUnknown(
          data['seller_remark']!,
          _sellerRemarkMeta,
        ),
      );
    }
    if (data.containsKey('prize_name')) {
      context.handle(
        _prizeNameMeta,
        prizeName.isAcceptableOrUnknown(data['prize_name']!, _prizeNameMeta),
      );
    }
    if (data.containsKey('prize_amount')) {
      context.handle(
        _prizeAmountMeta,
        prizeAmount.isAcceptableOrUnknown(
          data['prize_amount']!,
          _prizeAmountMeta,
        ),
      );
    }
    if (data.containsKey('invoice_json_summary')) {
      context.handle(
        _invoiceJsonSummaryMeta,
        invoiceJsonSummary.isAcceptableOrUnknown(
          data['invoice_json_summary']!,
          _invoiceJsonSummaryMeta,
        ),
      );
    }
    if (data.containsKey('invoice_json_data')) {
      context.handle(
        _invoiceJsonDataMeta,
        invoiceJsonData.isAcceptableOrUnknown(
          data['invoice_json_data']!,
          _invoiceJsonDataMeta,
        ),
      );
    }
    if (data.containsKey('invoice_json_detail')) {
      context.handle(
        _invoiceJsonDetailMeta,
        invoiceJsonDetail.isAcceptableOrUnknown(
          data['invoice_json_detail']!,
          _invoiceJsonDetailMeta,
        ),
      );
    }
    if (data.containsKey('invoice_json_award')) {
      context.handle(
        _invoiceJsonAwardMeta,
        invoiceJsonAward.isAcceptableOrUnknown(
          data['invoice_json_award']!,
          _invoiceJsonAwardMeta,
        ),
      );
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
      originStatus: $ReceiptsTable.$converteroriginStatus.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}origin_status'],
        )!,
      ),
      userNote: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}user_note'],
      ),
      issuedAt: $ReceiptsTable.$converterissuedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}issued_at'],
        )!,
      ),
      totalAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}total_amount'],
      )!,
      invoiceNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_number'],
      ),
      randomNumber: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}random_number'],
      ),
      carrierName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}carrier_name'],
      ),
      carrierType: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}carrier_type'],
      ),
      carrierId2: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}carrier_id2'],
      ),
      sellerName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seller_name'],
      ),
      sellerTaxId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seller_tax_id'],
      ),
      sellerAddress: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seller_address'],
      ),
      sellerRemark: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}seller_remark'],
      ),
      prizeName: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}prize_name'],
      ),
      prizeAmount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}prize_amount'],
      ),
      invoiceJsonSummary: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_json_summary'],
      ),
      invoiceJsonData: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_json_data'],
      ),
      invoiceJsonDetail: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_json_detail'],
      ),
      invoiceJsonAward: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}invoice_json_award'],
      ),
    );
  }

  @override
  $ReceiptsTable createAlias(String alias) {
    return $ReceiptsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertermodified = dateTimeConverter;
  static TypeConverter<OriginStatus, int> $converteroriginStatus =
      OriginStatus.converter;
  static TypeConverter<DateTime, int> $converterissuedAt = dateTimeConverter;
}

class Receipt extends DataClass implements Insertable<Receipt> {
  final DateTime modified;
  final String uuid;
  final OriginStatus originStatus;
  final String? userNote;
  final DateTime issuedAt;
  final double totalAmount;
  final String? invoiceNumber;
  final String? randomNumber;
  final String? carrierName;
  final String? carrierType;
  final String? carrierId2;
  final String? sellerName;
  final String? sellerTaxId;
  final String? sellerAddress;
  final String? sellerRemark;
  final String? prizeName;
  final double? prizeAmount;
  final String? invoiceJsonSummary;
  final String? invoiceJsonData;
  final String? invoiceJsonDetail;
  final String? invoiceJsonAward;
  const Receipt({
    required this.modified,
    required this.uuid,
    required this.originStatus,
    this.userNote,
    required this.issuedAt,
    required this.totalAmount,
    this.invoiceNumber,
    this.randomNumber,
    this.carrierName,
    this.carrierType,
    this.carrierId2,
    this.sellerName,
    this.sellerTaxId,
    this.sellerAddress,
    this.sellerRemark,
    this.prizeName,
    this.prizeAmount,
    this.invoiceJsonSummary,
    this.invoiceJsonData,
    this.invoiceJsonDetail,
    this.invoiceJsonAward,
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
    {
      map['origin_status'] = Variable<int>(
        $ReceiptsTable.$converteroriginStatus.toSql(originStatus),
      );
    }
    if (!nullToAbsent || userNote != null) {
      map['user_note'] = Variable<String>(userNote);
    }
    {
      map['issued_at'] = Variable<int>(
        $ReceiptsTable.$converterissuedAt.toSql(issuedAt),
      );
    }
    map['total_amount'] = Variable<double>(totalAmount);
    if (!nullToAbsent || invoiceNumber != null) {
      map['invoice_number'] = Variable<String>(invoiceNumber);
    }
    if (!nullToAbsent || randomNumber != null) {
      map['random_number'] = Variable<String>(randomNumber);
    }
    if (!nullToAbsent || carrierName != null) {
      map['carrier_name'] = Variable<String>(carrierName);
    }
    if (!nullToAbsent || carrierType != null) {
      map['carrier_type'] = Variable<String>(carrierType);
    }
    if (!nullToAbsent || carrierId2 != null) {
      map['carrier_id2'] = Variable<String>(carrierId2);
    }
    if (!nullToAbsent || sellerName != null) {
      map['seller_name'] = Variable<String>(sellerName);
    }
    if (!nullToAbsent || sellerTaxId != null) {
      map['seller_tax_id'] = Variable<String>(sellerTaxId);
    }
    if (!nullToAbsent || sellerAddress != null) {
      map['seller_address'] = Variable<String>(sellerAddress);
    }
    if (!nullToAbsent || sellerRemark != null) {
      map['seller_remark'] = Variable<String>(sellerRemark);
    }
    if (!nullToAbsent || prizeName != null) {
      map['prize_name'] = Variable<String>(prizeName);
    }
    if (!nullToAbsent || prizeAmount != null) {
      map['prize_amount'] = Variable<double>(prizeAmount);
    }
    if (!nullToAbsent || invoiceJsonSummary != null) {
      map['invoice_json_summary'] = Variable<String>(invoiceJsonSummary);
    }
    if (!nullToAbsent || invoiceJsonData != null) {
      map['invoice_json_data'] = Variable<String>(invoiceJsonData);
    }
    if (!nullToAbsent || invoiceJsonDetail != null) {
      map['invoice_json_detail'] = Variable<String>(invoiceJsonDetail);
    }
    if (!nullToAbsent || invoiceJsonAward != null) {
      map['invoice_json_award'] = Variable<String>(invoiceJsonAward);
    }
    return map;
  }

  ReceiptsCompanion toCompanion(bool nullToAbsent) {
    return ReceiptsCompanion(
      modified: Value(modified),
      uuid: Value(uuid),
      originStatus: Value(originStatus),
      userNote: userNote == null && nullToAbsent
          ? const Value.absent()
          : Value(userNote),
      issuedAt: Value(issuedAt),
      totalAmount: Value(totalAmount),
      invoiceNumber: invoiceNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(invoiceNumber),
      randomNumber: randomNumber == null && nullToAbsent
          ? const Value.absent()
          : Value(randomNumber),
      carrierName: carrierName == null && nullToAbsent
          ? const Value.absent()
          : Value(carrierName),
      carrierType: carrierType == null && nullToAbsent
          ? const Value.absent()
          : Value(carrierType),
      carrierId2: carrierId2 == null && nullToAbsent
          ? const Value.absent()
          : Value(carrierId2),
      sellerName: sellerName == null && nullToAbsent
          ? const Value.absent()
          : Value(sellerName),
      sellerTaxId: sellerTaxId == null && nullToAbsent
          ? const Value.absent()
          : Value(sellerTaxId),
      sellerAddress: sellerAddress == null && nullToAbsent
          ? const Value.absent()
          : Value(sellerAddress),
      sellerRemark: sellerRemark == null && nullToAbsent
          ? const Value.absent()
          : Value(sellerRemark),
      prizeName: prizeName == null && nullToAbsent
          ? const Value.absent()
          : Value(prizeName),
      prizeAmount: prizeAmount == null && nullToAbsent
          ? const Value.absent()
          : Value(prizeAmount),
      invoiceJsonSummary: invoiceJsonSummary == null && nullToAbsent
          ? const Value.absent()
          : Value(invoiceJsonSummary),
      invoiceJsonData: invoiceJsonData == null && nullToAbsent
          ? const Value.absent()
          : Value(invoiceJsonData),
      invoiceJsonDetail: invoiceJsonDetail == null && nullToAbsent
          ? const Value.absent()
          : Value(invoiceJsonDetail),
      invoiceJsonAward: invoiceJsonAward == null && nullToAbsent
          ? const Value.absent()
          : Value(invoiceJsonAward),
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
      originStatus: serializer.fromJson<OriginStatus>(json['originStatus']),
      userNote: serializer.fromJson<String?>(json['userNote']),
      issuedAt: serializer.fromJson<DateTime>(json['issuedAt']),
      totalAmount: serializer.fromJson<double>(json['totalAmount']),
      invoiceNumber: serializer.fromJson<String?>(json['invoiceNumber']),
      randomNumber: serializer.fromJson<String?>(json['randomNumber']),
      carrierName: serializer.fromJson<String?>(json['carrierName']),
      carrierType: serializer.fromJson<String?>(json['carrierType']),
      carrierId2: serializer.fromJson<String?>(json['carrierId2']),
      sellerName: serializer.fromJson<String?>(json['sellerName']),
      sellerTaxId: serializer.fromJson<String?>(json['sellerTaxId']),
      sellerAddress: serializer.fromJson<String?>(json['sellerAddress']),
      sellerRemark: serializer.fromJson<String?>(json['sellerRemark']),
      prizeName: serializer.fromJson<String?>(json['prizeName']),
      prizeAmount: serializer.fromJson<double?>(json['prizeAmount']),
      invoiceJsonSummary: serializer.fromJson<String?>(
        json['invoiceJsonSummary'],
      ),
      invoiceJsonData: serializer.fromJson<String?>(json['invoiceJsonData']),
      invoiceJsonDetail: serializer.fromJson<String?>(
        json['invoiceJsonDetail'],
      ),
      invoiceJsonAward: serializer.fromJson<String?>(json['invoiceJsonAward']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'modified': serializer.toJson<DateTime>(modified),
      'uuid': serializer.toJson<String>(uuid),
      'originStatus': serializer.toJson<OriginStatus>(originStatus),
      'userNote': serializer.toJson<String?>(userNote),
      'issuedAt': serializer.toJson<DateTime>(issuedAt),
      'totalAmount': serializer.toJson<double>(totalAmount),
      'invoiceNumber': serializer.toJson<String?>(invoiceNumber),
      'randomNumber': serializer.toJson<String?>(randomNumber),
      'carrierName': serializer.toJson<String?>(carrierName),
      'carrierType': serializer.toJson<String?>(carrierType),
      'carrierId2': serializer.toJson<String?>(carrierId2),
      'sellerName': serializer.toJson<String?>(sellerName),
      'sellerTaxId': serializer.toJson<String?>(sellerTaxId),
      'sellerAddress': serializer.toJson<String?>(sellerAddress),
      'sellerRemark': serializer.toJson<String?>(sellerRemark),
      'prizeName': serializer.toJson<String?>(prizeName),
      'prizeAmount': serializer.toJson<double?>(prizeAmount),
      'invoiceJsonSummary': serializer.toJson<String?>(invoiceJsonSummary),
      'invoiceJsonData': serializer.toJson<String?>(invoiceJsonData),
      'invoiceJsonDetail': serializer.toJson<String?>(invoiceJsonDetail),
      'invoiceJsonAward': serializer.toJson<String?>(invoiceJsonAward),
    };
  }

  Receipt copyWith({
    DateTime? modified,
    String? uuid,
    OriginStatus? originStatus,
    Value<String?> userNote = const Value.absent(),
    DateTime? issuedAt,
    double? totalAmount,
    Value<String?> invoiceNumber = const Value.absent(),
    Value<String?> randomNumber = const Value.absent(),
    Value<String?> carrierName = const Value.absent(),
    Value<String?> carrierType = const Value.absent(),
    Value<String?> carrierId2 = const Value.absent(),
    Value<String?> sellerName = const Value.absent(),
    Value<String?> sellerTaxId = const Value.absent(),
    Value<String?> sellerAddress = const Value.absent(),
    Value<String?> sellerRemark = const Value.absent(),
    Value<String?> prizeName = const Value.absent(),
    Value<double?> prizeAmount = const Value.absent(),
    Value<String?> invoiceJsonSummary = const Value.absent(),
    Value<String?> invoiceJsonData = const Value.absent(),
    Value<String?> invoiceJsonDetail = const Value.absent(),
    Value<String?> invoiceJsonAward = const Value.absent(),
  }) => Receipt(
    modified: modified ?? this.modified,
    uuid: uuid ?? this.uuid,
    originStatus: originStatus ?? this.originStatus,
    userNote: userNote.present ? userNote.value : this.userNote,
    issuedAt: issuedAt ?? this.issuedAt,
    totalAmount: totalAmount ?? this.totalAmount,
    invoiceNumber: invoiceNumber.present
        ? invoiceNumber.value
        : this.invoiceNumber,
    randomNumber: randomNumber.present ? randomNumber.value : this.randomNumber,
    carrierName: carrierName.present ? carrierName.value : this.carrierName,
    carrierType: carrierType.present ? carrierType.value : this.carrierType,
    carrierId2: carrierId2.present ? carrierId2.value : this.carrierId2,
    sellerName: sellerName.present ? sellerName.value : this.sellerName,
    sellerTaxId: sellerTaxId.present ? sellerTaxId.value : this.sellerTaxId,
    sellerAddress: sellerAddress.present
        ? sellerAddress.value
        : this.sellerAddress,
    sellerRemark: sellerRemark.present ? sellerRemark.value : this.sellerRemark,
    prizeName: prizeName.present ? prizeName.value : this.prizeName,
    prizeAmount: prizeAmount.present ? prizeAmount.value : this.prizeAmount,
    invoiceJsonSummary: invoiceJsonSummary.present
        ? invoiceJsonSummary.value
        : this.invoiceJsonSummary,
    invoiceJsonData: invoiceJsonData.present
        ? invoiceJsonData.value
        : this.invoiceJsonData,
    invoiceJsonDetail: invoiceJsonDetail.present
        ? invoiceJsonDetail.value
        : this.invoiceJsonDetail,
    invoiceJsonAward: invoiceJsonAward.present
        ? invoiceJsonAward.value
        : this.invoiceJsonAward,
  );
  Receipt copyWithCompanion(ReceiptsCompanion data) {
    return Receipt(
      modified: data.modified.present ? data.modified.value : this.modified,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      originStatus: data.originStatus.present
          ? data.originStatus.value
          : this.originStatus,
      userNote: data.userNote.present ? data.userNote.value : this.userNote,
      issuedAt: data.issuedAt.present ? data.issuedAt.value : this.issuedAt,
      totalAmount: data.totalAmount.present
          ? data.totalAmount.value
          : this.totalAmount,
      invoiceNumber: data.invoiceNumber.present
          ? data.invoiceNumber.value
          : this.invoiceNumber,
      randomNumber: data.randomNumber.present
          ? data.randomNumber.value
          : this.randomNumber,
      carrierName: data.carrierName.present
          ? data.carrierName.value
          : this.carrierName,
      carrierType: data.carrierType.present
          ? data.carrierType.value
          : this.carrierType,
      carrierId2: data.carrierId2.present
          ? data.carrierId2.value
          : this.carrierId2,
      sellerName: data.sellerName.present
          ? data.sellerName.value
          : this.sellerName,
      sellerTaxId: data.sellerTaxId.present
          ? data.sellerTaxId.value
          : this.sellerTaxId,
      sellerAddress: data.sellerAddress.present
          ? data.sellerAddress.value
          : this.sellerAddress,
      sellerRemark: data.sellerRemark.present
          ? data.sellerRemark.value
          : this.sellerRemark,
      prizeName: data.prizeName.present ? data.prizeName.value : this.prizeName,
      prizeAmount: data.prizeAmount.present
          ? data.prizeAmount.value
          : this.prizeAmount,
      invoiceJsonSummary: data.invoiceJsonSummary.present
          ? data.invoiceJsonSummary.value
          : this.invoiceJsonSummary,
      invoiceJsonData: data.invoiceJsonData.present
          ? data.invoiceJsonData.value
          : this.invoiceJsonData,
      invoiceJsonDetail: data.invoiceJsonDetail.present
          ? data.invoiceJsonDetail.value
          : this.invoiceJsonDetail,
      invoiceJsonAward: data.invoiceJsonAward.present
          ? data.invoiceJsonAward.value
          : this.invoiceJsonAward,
    );
  }

  @override
  String toString() {
    return (StringBuffer('Receipt(')
          ..write('modified: $modified, ')
          ..write('uuid: $uuid, ')
          ..write('originStatus: $originStatus, ')
          ..write('userNote: $userNote, ')
          ..write('issuedAt: $issuedAt, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('randomNumber: $randomNumber, ')
          ..write('carrierName: $carrierName, ')
          ..write('carrierType: $carrierType, ')
          ..write('carrierId2: $carrierId2, ')
          ..write('sellerName: $sellerName, ')
          ..write('sellerTaxId: $sellerTaxId, ')
          ..write('sellerAddress: $sellerAddress, ')
          ..write('sellerRemark: $sellerRemark, ')
          ..write('prizeName: $prizeName, ')
          ..write('prizeAmount: $prizeAmount, ')
          ..write('invoiceJsonSummary: $invoiceJsonSummary, ')
          ..write('invoiceJsonData: $invoiceJsonData, ')
          ..write('invoiceJsonDetail: $invoiceJsonDetail, ')
          ..write('invoiceJsonAward: $invoiceJsonAward')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hashAll([
    modified,
    uuid,
    originStatus,
    userNote,
    issuedAt,
    totalAmount,
    invoiceNumber,
    randomNumber,
    carrierName,
    carrierType,
    carrierId2,
    sellerName,
    sellerTaxId,
    sellerAddress,
    sellerRemark,
    prizeName,
    prizeAmount,
    invoiceJsonSummary,
    invoiceJsonData,
    invoiceJsonDetail,
    invoiceJsonAward,
  ]);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is Receipt &&
          other.modified == this.modified &&
          other.uuid == this.uuid &&
          other.originStatus == this.originStatus &&
          other.userNote == this.userNote &&
          other.issuedAt == this.issuedAt &&
          other.totalAmount == this.totalAmount &&
          other.invoiceNumber == this.invoiceNumber &&
          other.randomNumber == this.randomNumber &&
          other.carrierName == this.carrierName &&
          other.carrierType == this.carrierType &&
          other.carrierId2 == this.carrierId2 &&
          other.sellerName == this.sellerName &&
          other.sellerTaxId == this.sellerTaxId &&
          other.sellerAddress == this.sellerAddress &&
          other.sellerRemark == this.sellerRemark &&
          other.prizeName == this.prizeName &&
          other.prizeAmount == this.prizeAmount &&
          other.invoiceJsonSummary == this.invoiceJsonSummary &&
          other.invoiceJsonData == this.invoiceJsonData &&
          other.invoiceJsonDetail == this.invoiceJsonDetail &&
          other.invoiceJsonAward == this.invoiceJsonAward);
}

class ReceiptsCompanion extends UpdateCompanion<Receipt> {
  final Value<DateTime> modified;
  final Value<String> uuid;
  final Value<OriginStatus> originStatus;
  final Value<String?> userNote;
  final Value<DateTime> issuedAt;
  final Value<double> totalAmount;
  final Value<String?> invoiceNumber;
  final Value<String?> randomNumber;
  final Value<String?> carrierName;
  final Value<String?> carrierType;
  final Value<String?> carrierId2;
  final Value<String?> sellerName;
  final Value<String?> sellerTaxId;
  final Value<String?> sellerAddress;
  final Value<String?> sellerRemark;
  final Value<String?> prizeName;
  final Value<double?> prizeAmount;
  final Value<String?> invoiceJsonSummary;
  final Value<String?> invoiceJsonData;
  final Value<String?> invoiceJsonDetail;
  final Value<String?> invoiceJsonAward;
  final Value<int> rowid;
  const ReceiptsCompanion({
    this.modified = const Value.absent(),
    this.uuid = const Value.absent(),
    this.originStatus = const Value.absent(),
    this.userNote = const Value.absent(),
    this.issuedAt = const Value.absent(),
    this.totalAmount = const Value.absent(),
    this.invoiceNumber = const Value.absent(),
    this.randomNumber = const Value.absent(),
    this.carrierName = const Value.absent(),
    this.carrierType = const Value.absent(),
    this.carrierId2 = const Value.absent(),
    this.sellerName = const Value.absent(),
    this.sellerTaxId = const Value.absent(),
    this.sellerAddress = const Value.absent(),
    this.sellerRemark = const Value.absent(),
    this.prizeName = const Value.absent(),
    this.prizeAmount = const Value.absent(),
    this.invoiceJsonSummary = const Value.absent(),
    this.invoiceJsonData = const Value.absent(),
    this.invoiceJsonDetail = const Value.absent(),
    this.invoiceJsonAward = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReceiptsCompanion.insert({
    this.modified = const Value.absent(),
    this.uuid = const Value.absent(),
    required OriginStatus originStatus,
    this.userNote = const Value.absent(),
    required DateTime issuedAt,
    required double totalAmount,
    this.invoiceNumber = const Value.absent(),
    this.randomNumber = const Value.absent(),
    this.carrierName = const Value.absent(),
    this.carrierType = const Value.absent(),
    this.carrierId2 = const Value.absent(),
    this.sellerName = const Value.absent(),
    this.sellerTaxId = const Value.absent(),
    this.sellerAddress = const Value.absent(),
    this.sellerRemark = const Value.absent(),
    this.prizeName = const Value.absent(),
    this.prizeAmount = const Value.absent(),
    this.invoiceJsonSummary = const Value.absent(),
    this.invoiceJsonData = const Value.absent(),
    this.invoiceJsonDetail = const Value.absent(),
    this.invoiceJsonAward = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : originStatus = Value(originStatus),
       issuedAt = Value(issuedAt),
       totalAmount = Value(totalAmount);
  static Insertable<Receipt> custom({
    Expression<int>? modified,
    Expression<String>? uuid,
    Expression<int>? originStatus,
    Expression<String>? userNote,
    Expression<int>? issuedAt,
    Expression<double>? totalAmount,
    Expression<String>? invoiceNumber,
    Expression<String>? randomNumber,
    Expression<String>? carrierName,
    Expression<String>? carrierType,
    Expression<String>? carrierId2,
    Expression<String>? sellerName,
    Expression<String>? sellerTaxId,
    Expression<String>? sellerAddress,
    Expression<String>? sellerRemark,
    Expression<String>? prizeName,
    Expression<double>? prizeAmount,
    Expression<String>? invoiceJsonSummary,
    Expression<String>? invoiceJsonData,
    Expression<String>? invoiceJsonDetail,
    Expression<String>? invoiceJsonAward,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (modified != null) 'modified': modified,
      if (uuid != null) 'uuid': uuid,
      if (originStatus != null) 'origin_status': originStatus,
      if (userNote != null) 'user_note': userNote,
      if (issuedAt != null) 'issued_at': issuedAt,
      if (totalAmount != null) 'total_amount': totalAmount,
      if (invoiceNumber != null) 'invoice_number': invoiceNumber,
      if (randomNumber != null) 'random_number': randomNumber,
      if (carrierName != null) 'carrier_name': carrierName,
      if (carrierType != null) 'carrier_type': carrierType,
      if (carrierId2 != null) 'carrier_id2': carrierId2,
      if (sellerName != null) 'seller_name': sellerName,
      if (sellerTaxId != null) 'seller_tax_id': sellerTaxId,
      if (sellerAddress != null) 'seller_address': sellerAddress,
      if (sellerRemark != null) 'seller_remark': sellerRemark,
      if (prizeName != null) 'prize_name': prizeName,
      if (prizeAmount != null) 'prize_amount': prizeAmount,
      if (invoiceJsonSummary != null)
        'invoice_json_summary': invoiceJsonSummary,
      if (invoiceJsonData != null) 'invoice_json_data': invoiceJsonData,
      if (invoiceJsonDetail != null) 'invoice_json_detail': invoiceJsonDetail,
      if (invoiceJsonAward != null) 'invoice_json_award': invoiceJsonAward,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReceiptsCompanion copyWith({
    Value<DateTime>? modified,
    Value<String>? uuid,
    Value<OriginStatus>? originStatus,
    Value<String?>? userNote,
    Value<DateTime>? issuedAt,
    Value<double>? totalAmount,
    Value<String?>? invoiceNumber,
    Value<String?>? randomNumber,
    Value<String?>? carrierName,
    Value<String?>? carrierType,
    Value<String?>? carrierId2,
    Value<String?>? sellerName,
    Value<String?>? sellerTaxId,
    Value<String?>? sellerAddress,
    Value<String?>? sellerRemark,
    Value<String?>? prizeName,
    Value<double?>? prizeAmount,
    Value<String?>? invoiceJsonSummary,
    Value<String?>? invoiceJsonData,
    Value<String?>? invoiceJsonDetail,
    Value<String?>? invoiceJsonAward,
    Value<int>? rowid,
  }) {
    return ReceiptsCompanion(
      modified: modified ?? this.modified,
      uuid: uuid ?? this.uuid,
      originStatus: originStatus ?? this.originStatus,
      userNote: userNote ?? this.userNote,
      issuedAt: issuedAt ?? this.issuedAt,
      totalAmount: totalAmount ?? this.totalAmount,
      invoiceNumber: invoiceNumber ?? this.invoiceNumber,
      randomNumber: randomNumber ?? this.randomNumber,
      carrierName: carrierName ?? this.carrierName,
      carrierType: carrierType ?? this.carrierType,
      carrierId2: carrierId2 ?? this.carrierId2,
      sellerName: sellerName ?? this.sellerName,
      sellerTaxId: sellerTaxId ?? this.sellerTaxId,
      sellerAddress: sellerAddress ?? this.sellerAddress,
      sellerRemark: sellerRemark ?? this.sellerRemark,
      prizeName: prizeName ?? this.prizeName,
      prizeAmount: prizeAmount ?? this.prizeAmount,
      invoiceJsonSummary: invoiceJsonSummary ?? this.invoiceJsonSummary,
      invoiceJsonData: invoiceJsonData ?? this.invoiceJsonData,
      invoiceJsonDetail: invoiceJsonDetail ?? this.invoiceJsonDetail,
      invoiceJsonAward: invoiceJsonAward ?? this.invoiceJsonAward,
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
    if (originStatus.present) {
      map['origin_status'] = Variable<int>(
        $ReceiptsTable.$converteroriginStatus.toSql(originStatus.value),
      );
    }
    if (userNote.present) {
      map['user_note'] = Variable<String>(userNote.value);
    }
    if (issuedAt.present) {
      map['issued_at'] = Variable<int>(
        $ReceiptsTable.$converterissuedAt.toSql(issuedAt.value),
      );
    }
    if (totalAmount.present) {
      map['total_amount'] = Variable<double>(totalAmount.value);
    }
    if (invoiceNumber.present) {
      map['invoice_number'] = Variable<String>(invoiceNumber.value);
    }
    if (randomNumber.present) {
      map['random_number'] = Variable<String>(randomNumber.value);
    }
    if (carrierName.present) {
      map['carrier_name'] = Variable<String>(carrierName.value);
    }
    if (carrierType.present) {
      map['carrier_type'] = Variable<String>(carrierType.value);
    }
    if (carrierId2.present) {
      map['carrier_id2'] = Variable<String>(carrierId2.value);
    }
    if (sellerName.present) {
      map['seller_name'] = Variable<String>(sellerName.value);
    }
    if (sellerTaxId.present) {
      map['seller_tax_id'] = Variable<String>(sellerTaxId.value);
    }
    if (sellerAddress.present) {
      map['seller_address'] = Variable<String>(sellerAddress.value);
    }
    if (sellerRemark.present) {
      map['seller_remark'] = Variable<String>(sellerRemark.value);
    }
    if (prizeName.present) {
      map['prize_name'] = Variable<String>(prizeName.value);
    }
    if (prizeAmount.present) {
      map['prize_amount'] = Variable<double>(prizeAmount.value);
    }
    if (invoiceJsonSummary.present) {
      map['invoice_json_summary'] = Variable<String>(invoiceJsonSummary.value);
    }
    if (invoiceJsonData.present) {
      map['invoice_json_data'] = Variable<String>(invoiceJsonData.value);
    }
    if (invoiceJsonDetail.present) {
      map['invoice_json_detail'] = Variable<String>(invoiceJsonDetail.value);
    }
    if (invoiceJsonAward.present) {
      map['invoice_json_award'] = Variable<String>(invoiceJsonAward.value);
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
          ..write('originStatus: $originStatus, ')
          ..write('userNote: $userNote, ')
          ..write('issuedAt: $issuedAt, ')
          ..write('totalAmount: $totalAmount, ')
          ..write('invoiceNumber: $invoiceNumber, ')
          ..write('randomNumber: $randomNumber, ')
          ..write('carrierName: $carrierName, ')
          ..write('carrierType: $carrierType, ')
          ..write('carrierId2: $carrierId2, ')
          ..write('sellerName: $sellerName, ')
          ..write('sellerTaxId: $sellerTaxId, ')
          ..write('sellerAddress: $sellerAddress, ')
          ..write('sellerRemark: $sellerRemark, ')
          ..write('prizeName: $prizeName, ')
          ..write('prizeAmount: $prizeAmount, ')
          ..write('invoiceJsonSummary: $invoiceJsonSummary, ')
          ..write('invoiceJsonData: $invoiceJsonData, ')
          ..write('invoiceJsonDetail: $invoiceJsonDetail, ')
          ..write('invoiceJsonAward: $invoiceJsonAward, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $ReceiptProductsTable extends ReceiptProducts
    with TableInfo<$ReceiptProductsTable, ReceiptProduct> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ReceiptProductsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> modified =
      GeneratedColumn<int>(
        'modified',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        clientDefault: () => UnitUtils.nowUnixTime,
      ).withConverter<DateTime>($ReceiptProductsTable.$convertermodified);
  static const VerificationMeta _uuidMeta = const VerificationMeta('uuid');
  @override
  late final GeneratedColumn<String> uuid = GeneratedColumn<String>(
    'uuid',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 36),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => UuidMixin.v7.generate(),
  );
  static const VerificationMeta _receiptUuidMeta = const VerificationMeta(
    'receiptUuid',
  );
  @override
  late final GeneratedColumn<String> receiptUuid = GeneratedColumn<String>(
    'receipt_uuid',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: GeneratedColumn.constraintIsAlways(
      'REFERENCES receipts (uuid) ON DELETE CASCADE',
    ),
  );
  static const VerificationMeta _sequenceMeta = const VerificationMeta(
    'sequence',
  );
  @override
  late final GeneratedColumn<int> sequence = GeneratedColumn<int>(
    'sequence',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _descriptionMeta = const VerificationMeta(
    'description',
  );
  @override
  late final GeneratedColumn<String> description = GeneratedColumn<String>(
    'description',
    aliasedName,
    false,
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _unitPriceMeta = const VerificationMeta(
    'unitPrice',
  );
  @override
  late final GeneratedColumn<double> unitPrice = GeneratedColumn<double>(
    'unit_price',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _quantityMeta = const VerificationMeta(
    'quantity',
  );
  @override
  late final GeneratedColumn<double> quantity = GeneratedColumn<double>(
    'quantity',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _amountMeta = const VerificationMeta('amount');
  @override
  late final GeneratedColumn<double> amount = GeneratedColumn<double>(
    'amount',
    aliasedName,
    false,
    type: DriftSqlType.double,
    requiredDuringInsert: true,
  );
  @override
  List<GeneratedColumn> get $columns => [
    modified,
    uuid,
    receiptUuid,
    sequence,
    description,
    unitPrice,
    quantity,
    amount,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'receipt_products';
  @override
  VerificationContext validateIntegrity(
    Insertable<ReceiptProduct> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('uuid')) {
      context.handle(
        _uuidMeta,
        uuid.isAcceptableOrUnknown(data['uuid']!, _uuidMeta),
      );
    }
    if (data.containsKey('receipt_uuid')) {
      context.handle(
        _receiptUuidMeta,
        receiptUuid.isAcceptableOrUnknown(
          data['receipt_uuid']!,
          _receiptUuidMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_receiptUuidMeta);
    }
    if (data.containsKey('sequence')) {
      context.handle(
        _sequenceMeta,
        sequence.isAcceptableOrUnknown(data['sequence']!, _sequenceMeta),
      );
    } else if (isInserting) {
      context.missing(_sequenceMeta);
    }
    if (data.containsKey('description')) {
      context.handle(
        _descriptionMeta,
        description.isAcceptableOrUnknown(
          data['description']!,
          _descriptionMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_descriptionMeta);
    }
    if (data.containsKey('unit_price')) {
      context.handle(
        _unitPriceMeta,
        unitPrice.isAcceptableOrUnknown(data['unit_price']!, _unitPriceMeta),
      );
    } else if (isInserting) {
      context.missing(_unitPriceMeta);
    }
    if (data.containsKey('quantity')) {
      context.handle(
        _quantityMeta,
        quantity.isAcceptableOrUnknown(data['quantity']!, _quantityMeta),
      );
    } else if (isInserting) {
      context.missing(_quantityMeta);
    }
    if (data.containsKey('amount')) {
      context.handle(
        _amountMeta,
        amount.isAcceptableOrUnknown(data['amount']!, _amountMeta),
      );
    } else if (isInserting) {
      context.missing(_amountMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  ReceiptProduct map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return ReceiptProduct(
      modified: $ReceiptProductsTable.$convertermodified.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}modified'],
        )!,
      ),
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
      receiptUuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}receipt_uuid'],
      )!,
      sequence: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sequence'],
      )!,
      description: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}description'],
      )!,
      unitPrice: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}unit_price'],
      )!,
      quantity: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}quantity'],
      )!,
      amount: attachedDatabase.typeMapping.read(
        DriftSqlType.double,
        data['${effectivePrefix}amount'],
      )!,
    );
  }

  @override
  $ReceiptProductsTable createAlias(String alias) {
    return $ReceiptProductsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertermodified = dateTimeConverter;
}

class ReceiptProduct extends DataClass implements Insertable<ReceiptProduct> {
  final DateTime modified;
  final String uuid;
  final String receiptUuid;
  final int sequence;
  final String description;
  final double unitPrice;
  final double quantity;
  final double amount;
  const ReceiptProduct({
    required this.modified,
    required this.uuid,
    required this.receiptUuid,
    required this.sequence,
    required this.description,
    required this.unitPrice,
    required this.quantity,
    required this.amount,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['modified'] = Variable<int>(
        $ReceiptProductsTable.$convertermodified.toSql(modified),
      );
    }
    map['uuid'] = Variable<String>(uuid);
    map['receipt_uuid'] = Variable<String>(receiptUuid);
    map['sequence'] = Variable<int>(sequence);
    map['description'] = Variable<String>(description);
    map['unit_price'] = Variable<double>(unitPrice);
    map['quantity'] = Variable<double>(quantity);
    map['amount'] = Variable<double>(amount);
    return map;
  }

  ReceiptProductsCompanion toCompanion(bool nullToAbsent) {
    return ReceiptProductsCompanion(
      modified: Value(modified),
      uuid: Value(uuid),
      receiptUuid: Value(receiptUuid),
      sequence: Value(sequence),
      description: Value(description),
      unitPrice: Value(unitPrice),
      quantity: Value(quantity),
      amount: Value(amount),
    );
  }

  factory ReceiptProduct.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return ReceiptProduct(
      modified: serializer.fromJson<DateTime>(json['modified']),
      uuid: serializer.fromJson<String>(json['uuid']),
      receiptUuid: serializer.fromJson<String>(json['receiptUuid']),
      sequence: serializer.fromJson<int>(json['sequence']),
      description: serializer.fromJson<String>(json['description']),
      unitPrice: serializer.fromJson<double>(json['unitPrice']),
      quantity: serializer.fromJson<double>(json['quantity']),
      amount: serializer.fromJson<double>(json['amount']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'modified': serializer.toJson<DateTime>(modified),
      'uuid': serializer.toJson<String>(uuid),
      'receiptUuid': serializer.toJson<String>(receiptUuid),
      'sequence': serializer.toJson<int>(sequence),
      'description': serializer.toJson<String>(description),
      'unitPrice': serializer.toJson<double>(unitPrice),
      'quantity': serializer.toJson<double>(quantity),
      'amount': serializer.toJson<double>(amount),
    };
  }

  ReceiptProduct copyWith({
    DateTime? modified,
    String? uuid,
    String? receiptUuid,
    int? sequence,
    String? description,
    double? unitPrice,
    double? quantity,
    double? amount,
  }) => ReceiptProduct(
    modified: modified ?? this.modified,
    uuid: uuid ?? this.uuid,
    receiptUuid: receiptUuid ?? this.receiptUuid,
    sequence: sequence ?? this.sequence,
    description: description ?? this.description,
    unitPrice: unitPrice ?? this.unitPrice,
    quantity: quantity ?? this.quantity,
    amount: amount ?? this.amount,
  );
  ReceiptProduct copyWithCompanion(ReceiptProductsCompanion data) {
    return ReceiptProduct(
      modified: data.modified.present ? data.modified.value : this.modified,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
      receiptUuid: data.receiptUuid.present
          ? data.receiptUuid.value
          : this.receiptUuid,
      sequence: data.sequence.present ? data.sequence.value : this.sequence,
      description: data.description.present
          ? data.description.value
          : this.description,
      unitPrice: data.unitPrice.present ? data.unitPrice.value : this.unitPrice,
      quantity: data.quantity.present ? data.quantity.value : this.quantity,
      amount: data.amount.present ? data.amount.value : this.amount,
    );
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptProduct(')
          ..write('modified: $modified, ')
          ..write('uuid: $uuid, ')
          ..write('receiptUuid: $receiptUuid, ')
          ..write('sequence: $sequence, ')
          ..write('description: $description, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('quantity: $quantity, ')
          ..write('amount: $amount')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    modified,
    uuid,
    receiptUuid,
    sequence,
    description,
    unitPrice,
    quantity,
    amount,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is ReceiptProduct &&
          other.modified == this.modified &&
          other.uuid == this.uuid &&
          other.receiptUuid == this.receiptUuid &&
          other.sequence == this.sequence &&
          other.description == this.description &&
          other.unitPrice == this.unitPrice &&
          other.quantity == this.quantity &&
          other.amount == this.amount);
}

class ReceiptProductsCompanion extends UpdateCompanion<ReceiptProduct> {
  final Value<DateTime> modified;
  final Value<String> uuid;
  final Value<String> receiptUuid;
  final Value<int> sequence;
  final Value<String> description;
  final Value<double> unitPrice;
  final Value<double> quantity;
  final Value<double> amount;
  final Value<int> rowid;
  const ReceiptProductsCompanion({
    this.modified = const Value.absent(),
    this.uuid = const Value.absent(),
    this.receiptUuid = const Value.absent(),
    this.sequence = const Value.absent(),
    this.description = const Value.absent(),
    this.unitPrice = const Value.absent(),
    this.quantity = const Value.absent(),
    this.amount = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  ReceiptProductsCompanion.insert({
    this.modified = const Value.absent(),
    this.uuid = const Value.absent(),
    required String receiptUuid,
    required int sequence,
    required String description,
    required double unitPrice,
    required double quantity,
    required double amount,
    this.rowid = const Value.absent(),
  }) : receiptUuid = Value(receiptUuid),
       sequence = Value(sequence),
       description = Value(description),
       unitPrice = Value(unitPrice),
       quantity = Value(quantity),
       amount = Value(amount);
  static Insertable<ReceiptProduct> custom({
    Expression<int>? modified,
    Expression<String>? uuid,
    Expression<String>? receiptUuid,
    Expression<int>? sequence,
    Expression<String>? description,
    Expression<double>? unitPrice,
    Expression<double>? quantity,
    Expression<double>? amount,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (modified != null) 'modified': modified,
      if (uuid != null) 'uuid': uuid,
      if (receiptUuid != null) 'receipt_uuid': receiptUuid,
      if (sequence != null) 'sequence': sequence,
      if (description != null) 'description': description,
      if (unitPrice != null) 'unit_price': unitPrice,
      if (quantity != null) 'quantity': quantity,
      if (amount != null) 'amount': amount,
      if (rowid != null) 'rowid': rowid,
    });
  }

  ReceiptProductsCompanion copyWith({
    Value<DateTime>? modified,
    Value<String>? uuid,
    Value<String>? receiptUuid,
    Value<int>? sequence,
    Value<String>? description,
    Value<double>? unitPrice,
    Value<double>? quantity,
    Value<double>? amount,
    Value<int>? rowid,
  }) {
    return ReceiptProductsCompanion(
      modified: modified ?? this.modified,
      uuid: uuid ?? this.uuid,
      receiptUuid: receiptUuid ?? this.receiptUuid,
      sequence: sequence ?? this.sequence,
      description: description ?? this.description,
      unitPrice: unitPrice ?? this.unitPrice,
      quantity: quantity ?? this.quantity,
      amount: amount ?? this.amount,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (modified.present) {
      map['modified'] = Variable<int>(
        $ReceiptProductsTable.$convertermodified.toSql(modified.value),
      );
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (receiptUuid.present) {
      map['receipt_uuid'] = Variable<String>(receiptUuid.value);
    }
    if (sequence.present) {
      map['sequence'] = Variable<int>(sequence.value);
    }
    if (description.present) {
      map['description'] = Variable<String>(description.value);
    }
    if (unitPrice.present) {
      map['unit_price'] = Variable<double>(unitPrice.value);
    }
    if (quantity.present) {
      map['quantity'] = Variable<double>(quantity.value);
    }
    if (amount.present) {
      map['amount'] = Variable<double>(amount.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('ReceiptProductsCompanion(')
          ..write('modified: $modified, ')
          ..write('uuid: $uuid, ')
          ..write('receiptUuid: $receiptUuid, ')
          ..write('sequence: $sequence, ')
          ..write('description: $description, ')
          ..write('unitPrice: $unitPrice, ')
          ..write('quantity: $quantity, ')
          ..write('amount: $amount, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DeletedUuidsTable extends DeletedUuids
    with TableInfo<$DeletedUuidsTable, DeletedUuid> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DeletedUuidsTable(this.attachedDatabase, [this._alias]);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> modified =
      GeneratedColumn<int>(
        'modified',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
        clientDefault: () => UnitUtils.nowUnixTime,
      ).withConverter<DateTime>($DeletedUuidsTable.$convertermodified);
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
  @override
  List<GeneratedColumn> get $columns => [modified, uuid];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'deleted_uuids';
  @override
  VerificationContext validateIntegrity(
    Insertable<DeletedUuid> instance, {
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
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {uuid};
  @override
  DeletedUuid map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DeletedUuid(
      modified: $DeletedUuidsTable.$convertermodified.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}modified'],
        )!,
      ),
      uuid: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}uuid'],
      )!,
    );
  }

  @override
  $DeletedUuidsTable createAlias(String alias) {
    return $DeletedUuidsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertermodified = dateTimeConverter;
}

class DeletedUuid extends DataClass implements Insertable<DeletedUuid> {
  final DateTime modified;
  final String uuid;
  const DeletedUuid({required this.modified, required this.uuid});
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    {
      map['modified'] = Variable<int>(
        $DeletedUuidsTable.$convertermodified.toSql(modified),
      );
    }
    map['uuid'] = Variable<String>(uuid);
    return map;
  }

  DeletedUuidsCompanion toCompanion(bool nullToAbsent) {
    return DeletedUuidsCompanion(modified: Value(modified), uuid: Value(uuid));
  }

  factory DeletedUuid.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DeletedUuid(
      modified: serializer.fromJson<DateTime>(json['modified']),
      uuid: serializer.fromJson<String>(json['uuid']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'modified': serializer.toJson<DateTime>(modified),
      'uuid': serializer.toJson<String>(uuid),
    };
  }

  DeletedUuid copyWith({DateTime? modified, String? uuid}) =>
      DeletedUuid(modified: modified ?? this.modified, uuid: uuid ?? this.uuid);
  DeletedUuid copyWithCompanion(DeletedUuidsCompanion data) {
    return DeletedUuid(
      modified: data.modified.present ? data.modified.value : this.modified,
      uuid: data.uuid.present ? data.uuid.value : this.uuid,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DeletedUuid(')
          ..write('modified: $modified, ')
          ..write('uuid: $uuid')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(modified, uuid);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DeletedUuid &&
          other.modified == this.modified &&
          other.uuid == this.uuid);
}

class DeletedUuidsCompanion extends UpdateCompanion<DeletedUuid> {
  final Value<DateTime> modified;
  final Value<String> uuid;
  final Value<int> rowid;
  const DeletedUuidsCompanion({
    this.modified = const Value.absent(),
    this.uuid = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DeletedUuidsCompanion.insert({
    this.modified = const Value.absent(),
    required String uuid,
    this.rowid = const Value.absent(),
  }) : uuid = Value(uuid);
  static Insertable<DeletedUuid> custom({
    Expression<int>? modified,
    Expression<String>? uuid,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (modified != null) 'modified': modified,
      if (uuid != null) 'uuid': uuid,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DeletedUuidsCompanion copyWith({
    Value<DateTime>? modified,
    Value<String>? uuid,
    Value<int>? rowid,
  }) {
    return DeletedUuidsCompanion(
      modified: modified ?? this.modified,
      uuid: uuid ?? this.uuid,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (modified.present) {
      map['modified'] = Variable<int>(
        $DeletedUuidsTable.$convertermodified.toSql(modified.value),
      );
    }
    if (uuid.present) {
      map['uuid'] = Variable<String>(uuid.value);
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DeletedUuidsCompanion(')
          ..write('modified: $modified, ')
          ..write('uuid: $uuid, ')
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
  late final $ReceiptProductsTable receiptProducts = $ReceiptProductsTable(
    this,
  );
  late final $DeletedUuidsTable deletedUuids = $DeletedUuidsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    keyValueStores,
    receipts,
    receiptProducts,
    deletedUuids,
  ];
  @override
  StreamQueryUpdateRules get streamUpdateRules => const StreamQueryUpdateRules([
    WritePropagation(
      on: TableUpdateQuery.onTableName(
        'receipts',
        limitUpdateKind: UpdateKind.delete,
      ),
      result: [TableUpdate('receipt_products', kind: UpdateKind.delete)],
    ),
  ]);
}

typedef $$KeyValueStoresTableCreateCompanionBuilder =
    KeyValueStoresCompanion Function({
      Value<DateTime> modified,
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
                Value<DateTime> modified = const Value.absent(),
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
      Value<DateTime> modified,
      Value<String> uuid,
      required OriginStatus originStatus,
      Value<String?> userNote,
      required DateTime issuedAt,
      required double totalAmount,
      Value<String?> invoiceNumber,
      Value<String?> randomNumber,
      Value<String?> carrierName,
      Value<String?> carrierType,
      Value<String?> carrierId2,
      Value<String?> sellerName,
      Value<String?> sellerTaxId,
      Value<String?> sellerAddress,
      Value<String?> sellerRemark,
      Value<String?> prizeName,
      Value<double?> prizeAmount,
      Value<String?> invoiceJsonSummary,
      Value<String?> invoiceJsonData,
      Value<String?> invoiceJsonDetail,
      Value<String?> invoiceJsonAward,
      Value<int> rowid,
    });
typedef $$ReceiptsTableUpdateCompanionBuilder =
    ReceiptsCompanion Function({
      Value<DateTime> modified,
      Value<String> uuid,
      Value<OriginStatus> originStatus,
      Value<String?> userNote,
      Value<DateTime> issuedAt,
      Value<double> totalAmount,
      Value<String?> invoiceNumber,
      Value<String?> randomNumber,
      Value<String?> carrierName,
      Value<String?> carrierType,
      Value<String?> carrierId2,
      Value<String?> sellerName,
      Value<String?> sellerTaxId,
      Value<String?> sellerAddress,
      Value<String?> sellerRemark,
      Value<String?> prizeName,
      Value<double?> prizeAmount,
      Value<String?> invoiceJsonSummary,
      Value<String?> invoiceJsonData,
      Value<String?> invoiceJsonDetail,
      Value<String?> invoiceJsonAward,
      Value<int> rowid,
    });

final class $$ReceiptsTableReferences
    extends BaseReferences<_$MyDriftDatabase, $ReceiptsTable, Receipt> {
  $$ReceiptsTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static MultiTypedResultKey<$ReceiptProductsTable, List<ReceiptProduct>>
  _receiptProductsRefsTable(_$MyDriftDatabase db) =>
      MultiTypedResultKey.fromTable(
        db.receiptProducts,
        aliasName: 'receipts__uuid__receipt_products__receipt_uuid',
      );

  $$ReceiptProductsTableProcessedTableManager get receiptProductsRefs {
    final manager =
        $$ReceiptProductsTableTableManager($_db, $_db.receiptProducts).filter(
          (f) => f.receiptUuid.uuid.sqlEquals($_itemColumn<String>('uuid')!),
        );

    final cache = $_typedResult.readTableOrNull(
      _receiptProductsRefsTable($_db),
    );
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

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

  ColumnWithTypeConverterFilters<OriginStatus, OriginStatus, int>
  get originStatus => $composableBuilder(
    column: $table.originStatus,
    builder: (column) => ColumnWithTypeConverterFilters(column),
  );

  ColumnFilters<String> get userNote => $composableBuilder(
    column: $table.userNote,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get issuedAt =>
      $composableBuilder(
        column: $table.issuedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get randomNumber => $composableBuilder(
    column: $table.randomNumber,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get carrierName => $composableBuilder(
    column: $table.carrierName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get carrierType => $composableBuilder(
    column: $table.carrierType,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get carrierId2 => $composableBuilder(
    column: $table.carrierId2,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sellerName => $composableBuilder(
    column: $table.sellerName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sellerTaxId => $composableBuilder(
    column: $table.sellerTaxId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sellerAddress => $composableBuilder(
    column: $table.sellerAddress,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get sellerRemark => $composableBuilder(
    column: $table.sellerRemark,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get prizeName => $composableBuilder(
    column: $table.prizeName,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get prizeAmount => $composableBuilder(
    column: $table.prizeAmount,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get invoiceJsonSummary => $composableBuilder(
    column: $table.invoiceJsonSummary,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get invoiceJsonData => $composableBuilder(
    column: $table.invoiceJsonData,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get invoiceJsonDetail => $composableBuilder(
    column: $table.invoiceJsonDetail,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get invoiceJsonAward => $composableBuilder(
    column: $table.invoiceJsonAward,
    builder: (column) => ColumnFilters(column),
  );

  Expression<bool> receiptProductsRefs(
    Expression<bool> Function($$ReceiptProductsTableFilterComposer f) f,
  ) {
    final $$ReceiptProductsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.receiptProducts,
      getReferencedColumn: (t) => t.receiptUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptProductsTableFilterComposer(
            $db: $db,
            $table: $db.receiptProducts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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

  ColumnOrderings<int> get originStatus => $composableBuilder(
    column: $table.originStatus,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get userNote => $composableBuilder(
    column: $table.userNote,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get issuedAt => $composableBuilder(
    column: $table.issuedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get randomNumber => $composableBuilder(
    column: $table.randomNumber,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get carrierName => $composableBuilder(
    column: $table.carrierName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get carrierType => $composableBuilder(
    column: $table.carrierType,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get carrierId2 => $composableBuilder(
    column: $table.carrierId2,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sellerName => $composableBuilder(
    column: $table.sellerName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sellerTaxId => $composableBuilder(
    column: $table.sellerTaxId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sellerAddress => $composableBuilder(
    column: $table.sellerAddress,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get sellerRemark => $composableBuilder(
    column: $table.sellerRemark,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get prizeName => $composableBuilder(
    column: $table.prizeName,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get prizeAmount => $composableBuilder(
    column: $table.prizeAmount,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get invoiceJsonSummary => $composableBuilder(
    column: $table.invoiceJsonSummary,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get invoiceJsonData => $composableBuilder(
    column: $table.invoiceJsonData,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get invoiceJsonDetail => $composableBuilder(
    column: $table.invoiceJsonDetail,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get invoiceJsonAward => $composableBuilder(
    column: $table.invoiceJsonAward,
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

  GeneratedColumnWithTypeConverter<OriginStatus, int> get originStatus =>
      $composableBuilder(
        column: $table.originStatus,
        builder: (column) => column,
      );

  GeneratedColumn<String> get userNote =>
      $composableBuilder(column: $table.userNote, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get issuedAt =>
      $composableBuilder(column: $table.issuedAt, builder: (column) => column);

  GeneratedColumn<double> get totalAmount => $composableBuilder(
    column: $table.totalAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get invoiceNumber => $composableBuilder(
    column: $table.invoiceNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get randomNumber => $composableBuilder(
    column: $table.randomNumber,
    builder: (column) => column,
  );

  GeneratedColumn<String> get carrierName => $composableBuilder(
    column: $table.carrierName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get carrierType => $composableBuilder(
    column: $table.carrierType,
    builder: (column) => column,
  );

  GeneratedColumn<String> get carrierId2 => $composableBuilder(
    column: $table.carrierId2,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sellerName => $composableBuilder(
    column: $table.sellerName,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sellerTaxId => $composableBuilder(
    column: $table.sellerTaxId,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sellerAddress => $composableBuilder(
    column: $table.sellerAddress,
    builder: (column) => column,
  );

  GeneratedColumn<String> get sellerRemark => $composableBuilder(
    column: $table.sellerRemark,
    builder: (column) => column,
  );

  GeneratedColumn<String> get prizeName =>
      $composableBuilder(column: $table.prizeName, builder: (column) => column);

  GeneratedColumn<double> get prizeAmount => $composableBuilder(
    column: $table.prizeAmount,
    builder: (column) => column,
  );

  GeneratedColumn<String> get invoiceJsonSummary => $composableBuilder(
    column: $table.invoiceJsonSummary,
    builder: (column) => column,
  );

  GeneratedColumn<String> get invoiceJsonData => $composableBuilder(
    column: $table.invoiceJsonData,
    builder: (column) => column,
  );

  GeneratedColumn<String> get invoiceJsonDetail => $composableBuilder(
    column: $table.invoiceJsonDetail,
    builder: (column) => column,
  );

  GeneratedColumn<String> get invoiceJsonAward => $composableBuilder(
    column: $table.invoiceJsonAward,
    builder: (column) => column,
  );

  Expression<T> receiptProductsRefs<T extends Object>(
    Expression<T> Function($$ReceiptProductsTableAnnotationComposer a) f,
  ) {
    final $$ReceiptProductsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.uuid,
      referencedTable: $db.receiptProducts,
      getReferencedColumn: (t) => t.receiptUuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptProductsTableAnnotationComposer(
            $db: $db,
            $table: $db.receiptProducts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
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
          (Receipt, $$ReceiptsTableReferences),
          Receipt,
          PrefetchHooks Function({bool receiptProductsRefs})
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
                Value<OriginStatus> originStatus = const Value.absent(),
                Value<String?> userNote = const Value.absent(),
                Value<DateTime> issuedAt = const Value.absent(),
                Value<double> totalAmount = const Value.absent(),
                Value<String?> invoiceNumber = const Value.absent(),
                Value<String?> randomNumber = const Value.absent(),
                Value<String?> carrierName = const Value.absent(),
                Value<String?> carrierType = const Value.absent(),
                Value<String?> carrierId2 = const Value.absent(),
                Value<String?> sellerName = const Value.absent(),
                Value<String?> sellerTaxId = const Value.absent(),
                Value<String?> sellerAddress = const Value.absent(),
                Value<String?> sellerRemark = const Value.absent(),
                Value<String?> prizeName = const Value.absent(),
                Value<double?> prizeAmount = const Value.absent(),
                Value<String?> invoiceJsonSummary = const Value.absent(),
                Value<String?> invoiceJsonData = const Value.absent(),
                Value<String?> invoiceJsonDetail = const Value.absent(),
                Value<String?> invoiceJsonAward = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReceiptsCompanion(
                modified: modified,
                uuid: uuid,
                originStatus: originStatus,
                userNote: userNote,
                issuedAt: issuedAt,
                totalAmount: totalAmount,
                invoiceNumber: invoiceNumber,
                randomNumber: randomNumber,
                carrierName: carrierName,
                carrierType: carrierType,
                carrierId2: carrierId2,
                sellerName: sellerName,
                sellerTaxId: sellerTaxId,
                sellerAddress: sellerAddress,
                sellerRemark: sellerRemark,
                prizeName: prizeName,
                prizeAmount: prizeAmount,
                invoiceJsonSummary: invoiceJsonSummary,
                invoiceJsonData: invoiceJsonData,
                invoiceJsonDetail: invoiceJsonDetail,
                invoiceJsonAward: invoiceJsonAward,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> modified = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                required OriginStatus originStatus,
                Value<String?> userNote = const Value.absent(),
                required DateTime issuedAt,
                required double totalAmount,
                Value<String?> invoiceNumber = const Value.absent(),
                Value<String?> randomNumber = const Value.absent(),
                Value<String?> carrierName = const Value.absent(),
                Value<String?> carrierType = const Value.absent(),
                Value<String?> carrierId2 = const Value.absent(),
                Value<String?> sellerName = const Value.absent(),
                Value<String?> sellerTaxId = const Value.absent(),
                Value<String?> sellerAddress = const Value.absent(),
                Value<String?> sellerRemark = const Value.absent(),
                Value<String?> prizeName = const Value.absent(),
                Value<double?> prizeAmount = const Value.absent(),
                Value<String?> invoiceJsonSummary = const Value.absent(),
                Value<String?> invoiceJsonData = const Value.absent(),
                Value<String?> invoiceJsonDetail = const Value.absent(),
                Value<String?> invoiceJsonAward = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReceiptsCompanion.insert(
                modified: modified,
                uuid: uuid,
                originStatus: originStatus,
                userNote: userNote,
                issuedAt: issuedAt,
                totalAmount: totalAmount,
                invoiceNumber: invoiceNumber,
                randomNumber: randomNumber,
                carrierName: carrierName,
                carrierType: carrierType,
                carrierId2: carrierId2,
                sellerName: sellerName,
                sellerTaxId: sellerTaxId,
                sellerAddress: sellerAddress,
                sellerRemark: sellerRemark,
                prizeName: prizeName,
                prizeAmount: prizeAmount,
                invoiceJsonSummary: invoiceJsonSummary,
                invoiceJsonData: invoiceJsonData,
                invoiceJsonDetail: invoiceJsonDetail,
                invoiceJsonAward: invoiceJsonAward,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReceiptsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({receiptProductsRefs = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [
                if (receiptProductsRefs) db.receiptProducts,
              ],
              addJoins: null,
              getPrefetchedDataCallback: (items) async {
                return [
                  if (receiptProductsRefs)
                    await $_getPrefetchedData<
                      Receipt,
                      $ReceiptsTable,
                      ReceiptProduct
                    >(
                      currentTable: table,
                      referencedTable: $$ReceiptsTableReferences
                          ._receiptProductsRefsTable(db),
                      managerFromTypedResult: (p0) => $$ReceiptsTableReferences(
                        db,
                        table,
                        p0,
                      ).receiptProductsRefs,
                      referencedItemsForCurrentItem: (item, referencedItems) =>
                          referencedItems.where(
                            (e) => e.receiptUuid == item.uuid,
                          ),
                      typedResults: items,
                    ),
                ];
              },
            );
          },
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
      (Receipt, $$ReceiptsTableReferences),
      Receipt,
      PrefetchHooks Function({bool receiptProductsRefs})
    >;
typedef $$ReceiptProductsTableCreateCompanionBuilder =
    ReceiptProductsCompanion Function({
      Value<DateTime> modified,
      Value<String> uuid,
      required String receiptUuid,
      required int sequence,
      required String description,
      required double unitPrice,
      required double quantity,
      required double amount,
      Value<int> rowid,
    });
typedef $$ReceiptProductsTableUpdateCompanionBuilder =
    ReceiptProductsCompanion Function({
      Value<DateTime> modified,
      Value<String> uuid,
      Value<String> receiptUuid,
      Value<int> sequence,
      Value<String> description,
      Value<double> unitPrice,
      Value<double> quantity,
      Value<double> amount,
      Value<int> rowid,
    });

final class $$ReceiptProductsTableReferences
    extends
        BaseReferences<
          _$MyDriftDatabase,
          $ReceiptProductsTable,
          ReceiptProduct
        > {
  $$ReceiptProductsTableReferences(
    super.$_db,
    super.$_table,
    super.$_typedResult,
  );

  static $ReceiptsTable _receiptUuidTable(_$MyDriftDatabase db) =>
      db.receipts.createAlias('receipt_products__receipt_uuid__receipts__uuid');

  $$ReceiptsTableProcessedTableManager get receiptUuid {
    final $_column = $_itemColumn<String>('receipt_uuid')!;

    final manager = $$ReceiptsTableTableManager(
      $_db,
      $_db.receipts,
    ).filter((f) => f.uuid.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_receiptUuidTable($_db));
    if (item == null) return manager;
    return ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$ReceiptProductsTableFilterComposer
    extends Composer<_$MyDriftDatabase, $ReceiptProductsTable> {
  $$ReceiptProductsTableFilterComposer({
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

  ColumnFilters<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnFilters(column),
  );

  $$ReceiptsTableFilterComposer get receiptUuid {
    final $$ReceiptsTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptUuid,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableFilterComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReceiptProductsTableOrderingComposer
    extends Composer<_$MyDriftDatabase, $ReceiptProductsTable> {
  $$ReceiptProductsTableOrderingComposer({
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

  ColumnOrderings<int> get sequence => $composableBuilder(
    column: $table.sequence,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get unitPrice => $composableBuilder(
    column: $table.unitPrice,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get quantity => $composableBuilder(
    column: $table.quantity,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<double> get amount => $composableBuilder(
    column: $table.amount,
    builder: (column) => ColumnOrderings(column),
  );

  $$ReceiptsTableOrderingComposer get receiptUuid {
    final $$ReceiptsTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptUuid,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableOrderingComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReceiptProductsTableAnnotationComposer
    extends Composer<_$MyDriftDatabase, $ReceiptProductsTable> {
  $$ReceiptProductsTableAnnotationComposer({
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

  GeneratedColumn<int> get sequence =>
      $composableBuilder(column: $table.sequence, builder: (column) => column);

  GeneratedColumn<String> get description => $composableBuilder(
    column: $table.description,
    builder: (column) => column,
  );

  GeneratedColumn<double> get unitPrice =>
      $composableBuilder(column: $table.unitPrice, builder: (column) => column);

  GeneratedColumn<double> get quantity =>
      $composableBuilder(column: $table.quantity, builder: (column) => column);

  GeneratedColumn<double> get amount =>
      $composableBuilder(column: $table.amount, builder: (column) => column);

  $$ReceiptsTableAnnotationComposer get receiptUuid {
    final $$ReceiptsTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.receiptUuid,
      referencedTable: $db.receipts,
      getReferencedColumn: (t) => t.uuid,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => $$ReceiptsTableAnnotationComposer(
            $db: $db,
            $table: $db.receipts,
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$ReceiptProductsTableTableManager
    extends
        RootTableManager<
          _$MyDriftDatabase,
          $ReceiptProductsTable,
          ReceiptProduct,
          $$ReceiptProductsTableFilterComposer,
          $$ReceiptProductsTableOrderingComposer,
          $$ReceiptProductsTableAnnotationComposer,
          $$ReceiptProductsTableCreateCompanionBuilder,
          $$ReceiptProductsTableUpdateCompanionBuilder,
          (ReceiptProduct, $$ReceiptProductsTableReferences),
          ReceiptProduct,
          PrefetchHooks Function({bool receiptUuid})
        > {
  $$ReceiptProductsTableTableManager(
    _$MyDriftDatabase db,
    $ReceiptProductsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$ReceiptProductsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$ReceiptProductsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$ReceiptProductsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> modified = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<String> receiptUuid = const Value.absent(),
                Value<int> sequence = const Value.absent(),
                Value<String> description = const Value.absent(),
                Value<double> unitPrice = const Value.absent(),
                Value<double> quantity = const Value.absent(),
                Value<double> amount = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => ReceiptProductsCompanion(
                modified: modified,
                uuid: uuid,
                receiptUuid: receiptUuid,
                sequence: sequence,
                description: description,
                unitPrice: unitPrice,
                quantity: quantity,
                amount: amount,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> modified = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                required String receiptUuid,
                required int sequence,
                required String description,
                required double unitPrice,
                required double quantity,
                required double amount,
                Value<int> rowid = const Value.absent(),
              }) => ReceiptProductsCompanion.insert(
                modified: modified,
                uuid: uuid,
                receiptUuid: receiptUuid,
                sequence: sequence,
                description: description,
                unitPrice: unitPrice,
                quantity: quantity,
                amount: amount,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  $$ReceiptProductsTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({receiptUuid = false}) {
            return PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (receiptUuid) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.receiptUuid,
                                referencedTable:
                                    $$ReceiptProductsTableReferences
                                        ._receiptUuidTable(db),
                                referencedColumn:
                                    $$ReceiptProductsTableReferences
                                        ._receiptUuidTable(db)
                                        .uuid,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$ReceiptProductsTableProcessedTableManager =
    ProcessedTableManager<
      _$MyDriftDatabase,
      $ReceiptProductsTable,
      ReceiptProduct,
      $$ReceiptProductsTableFilterComposer,
      $$ReceiptProductsTableOrderingComposer,
      $$ReceiptProductsTableAnnotationComposer,
      $$ReceiptProductsTableCreateCompanionBuilder,
      $$ReceiptProductsTableUpdateCompanionBuilder,
      (ReceiptProduct, $$ReceiptProductsTableReferences),
      ReceiptProduct,
      PrefetchHooks Function({bool receiptUuid})
    >;
typedef $$DeletedUuidsTableCreateCompanionBuilder =
    DeletedUuidsCompanion Function({
      Value<DateTime> modified,
      required String uuid,
      Value<int> rowid,
    });
typedef $$DeletedUuidsTableUpdateCompanionBuilder =
    DeletedUuidsCompanion Function({
      Value<DateTime> modified,
      Value<String> uuid,
      Value<int> rowid,
    });

class $$DeletedUuidsTableFilterComposer
    extends Composer<_$MyDriftDatabase, $DeletedUuidsTable> {
  $$DeletedUuidsTableFilterComposer({
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
}

class $$DeletedUuidsTableOrderingComposer
    extends Composer<_$MyDriftDatabase, $DeletedUuidsTable> {
  $$DeletedUuidsTableOrderingComposer({
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
}

class $$DeletedUuidsTableAnnotationComposer
    extends Composer<_$MyDriftDatabase, $DeletedUuidsTable> {
  $$DeletedUuidsTableAnnotationComposer({
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
}

class $$DeletedUuidsTableTableManager
    extends
        RootTableManager<
          _$MyDriftDatabase,
          $DeletedUuidsTable,
          DeletedUuid,
          $$DeletedUuidsTableFilterComposer,
          $$DeletedUuidsTableOrderingComposer,
          $$DeletedUuidsTableAnnotationComposer,
          $$DeletedUuidsTableCreateCompanionBuilder,
          $$DeletedUuidsTableUpdateCompanionBuilder,
          (
            DeletedUuid,
            BaseReferences<_$MyDriftDatabase, $DeletedUuidsTable, DeletedUuid>,
          ),
          DeletedUuid,
          PrefetchHooks Function()
        > {
  $$DeletedUuidsTableTableManager(
    _$MyDriftDatabase db,
    $DeletedUuidsTable table,
  ) : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DeletedUuidsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DeletedUuidsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DeletedUuidsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<DateTime> modified = const Value.absent(),
                Value<String> uuid = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DeletedUuidsCompanion(
                modified: modified,
                uuid: uuid,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                Value<DateTime> modified = const Value.absent(),
                required String uuid,
                Value<int> rowid = const Value.absent(),
              }) => DeletedUuidsCompanion.insert(
                modified: modified,
                uuid: uuid,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DeletedUuidsTableProcessedTableManager =
    ProcessedTableManager<
      _$MyDriftDatabase,
      $DeletedUuidsTable,
      DeletedUuid,
      $$DeletedUuidsTableFilterComposer,
      $$DeletedUuidsTableOrderingComposer,
      $$DeletedUuidsTableAnnotationComposer,
      $$DeletedUuidsTableCreateCompanionBuilder,
      $$DeletedUuidsTableUpdateCompanionBuilder,
      (
        DeletedUuid,
        BaseReferences<_$MyDriftDatabase, $DeletedUuidsTable, DeletedUuid>,
      ),
      DeletedUuid,
      PrefetchHooks Function()
    >;

class $MyDriftDatabaseManager {
  final _$MyDriftDatabase _db;
  $MyDriftDatabaseManager(this._db);
  $$KeyValueStoresTableTableManager get keyValueStores =>
      $$KeyValueStoresTableTableManager(_db, _db.keyValueStores);
  $$ReceiptsTableTableManager get receipts =>
      $$ReceiptsTableTableManager(_db, _db.receipts);
  $$ReceiptProductsTableTableManager get receiptProducts =>
      $$ReceiptProductsTableTableManager(_db, _db.receiptProducts);
  $$DeletedUuidsTableTableManager get deletedUuids =>
      $$DeletedUuidsTableTableManager(_db, _db.deletedUuids);
}
