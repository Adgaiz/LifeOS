// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'app_database.dart';

// ignore_for_file: type=lint
class $AppMetadataTable extends AppMetadata
    with TableInfo<$AppMetadataTable, AppMetadataData> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $AppMetadataTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _metadataKeyMeta = const VerificationMeta(
    'metadataKey',
  );
  @override
  late final GeneratedColumn<String> metadataKey = GeneratedColumn<String>(
    'metadata_key',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 100,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _metadataValueMeta = const VerificationMeta(
    'metadataValue',
  );
  @override
  late final GeneratedColumn<String> metadataValue = GeneratedColumn<String>(
    'metadata_value',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 500),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($AppMetadataTable.$converterupdatedAt);
  @override
  List<GeneratedColumn> get $columns => [metadataKey, metadataValue, updatedAt];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'app_metadata';
  @override
  VerificationContext validateIntegrity(
    Insertable<AppMetadataData> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('metadata_key')) {
      context.handle(
        _metadataKeyMeta,
        metadataKey.isAcceptableOrUnknown(
          data['metadata_key']!,
          _metadataKeyMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_metadataKeyMeta);
    }
    if (data.containsKey('metadata_value')) {
      context.handle(
        _metadataValueMeta,
        metadataValue.isAcceptableOrUnknown(
          data['metadata_value']!,
          _metadataValueMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_metadataValueMeta);
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {metadataKey};
  @override
  AppMetadataData map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return AppMetadataData(
      metadataKey: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_key'],
      )!,
      metadataValue: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}metadata_value'],
      )!,
      updatedAt: $AppMetadataTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
    );
  }

  @override
  $AppMetadataTable createAlias(String alias) {
    return $AppMetadataTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $converterupdatedAt =
      const UtcDateTimeConverter();
}

class AppMetadataData extends DataClass implements Insertable<AppMetadataData> {
  final String metadataKey;
  final String metadataValue;
  final DateTime updatedAt;
  const AppMetadataData({
    required this.metadataKey,
    required this.metadataValue,
    required this.updatedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['metadata_key'] = Variable<String>(metadataKey);
    map['metadata_value'] = Variable<String>(metadataValue);
    {
      map['updated_at'] = Variable<int>(
        $AppMetadataTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    return map;
  }

  AppMetadataCompanion toCompanion(bool nullToAbsent) {
    return AppMetadataCompanion(
      metadataKey: Value(metadataKey),
      metadataValue: Value(metadataValue),
      updatedAt: Value(updatedAt),
    );
  }

  factory AppMetadataData.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return AppMetadataData(
      metadataKey: serializer.fromJson<String>(json['metadataKey']),
      metadataValue: serializer.fromJson<String>(json['metadataValue']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'metadataKey': serializer.toJson<String>(metadataKey),
      'metadataValue': serializer.toJson<String>(metadataValue),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
    };
  }

  AppMetadataData copyWith({
    String? metadataKey,
    String? metadataValue,
    DateTime? updatedAt,
  }) => AppMetadataData(
    metadataKey: metadataKey ?? this.metadataKey,
    metadataValue: metadataValue ?? this.metadataValue,
    updatedAt: updatedAt ?? this.updatedAt,
  );
  AppMetadataData copyWithCompanion(AppMetadataCompanion data) {
    return AppMetadataData(
      metadataKey: data.metadataKey.present
          ? data.metadataKey.value
          : this.metadataKey,
      metadataValue: data.metadataValue.present
          ? data.metadataValue.value
          : this.metadataValue,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('AppMetadataData(')
          ..write('metadataKey: $metadataKey, ')
          ..write('metadataValue: $metadataValue, ')
          ..write('updatedAt: $updatedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(metadataKey, metadataValue, updatedAt);
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is AppMetadataData &&
          other.metadataKey == this.metadataKey &&
          other.metadataValue == this.metadataValue &&
          other.updatedAt == this.updatedAt);
}

class AppMetadataCompanion extends UpdateCompanion<AppMetadataData> {
  final Value<String> metadataKey;
  final Value<String> metadataValue;
  final Value<DateTime> updatedAt;
  final Value<int> rowid;
  const AppMetadataCompanion({
    this.metadataKey = const Value.absent(),
    this.metadataValue = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  AppMetadataCompanion.insert({
    required String metadataKey,
    required String metadataValue,
    required DateTime updatedAt,
    this.rowid = const Value.absent(),
  }) : metadataKey = Value(metadataKey),
       metadataValue = Value(metadataValue),
       updatedAt = Value(updatedAt);
  static Insertable<AppMetadataData> custom({
    Expression<String>? metadataKey,
    Expression<String>? metadataValue,
    Expression<int>? updatedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (metadataKey != null) 'metadata_key': metadataKey,
      if (metadataValue != null) 'metadata_value': metadataValue,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  AppMetadataCompanion copyWith({
    Value<String>? metadataKey,
    Value<String>? metadataValue,
    Value<DateTime>? updatedAt,
    Value<int>? rowid,
  }) {
    return AppMetadataCompanion(
      metadataKey: metadataKey ?? this.metadataKey,
      metadataValue: metadataValue ?? this.metadataValue,
      updatedAt: updatedAt ?? this.updatedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (metadataKey.present) {
      map['metadata_key'] = Variable<String>(metadataKey.value);
    }
    if (metadataValue.present) {
      map['metadata_value'] = Variable<String>(metadataValue.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $AppMetadataTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('AppMetadataCompanion(')
          ..write('metadataKey: $metadataKey, ')
          ..write('metadataValue: $metadataValue, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyRecordsTable extends DailyRecords
    with TableInfo<$DailyRecordsTable, DailyRecordRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyRecordsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localDateMeta = const VerificationMeta(
    'localDate',
  );
  @override
  late final GeneratedColumn<String> localDate = GeneratedColumn<String>(
    'local_date',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _timezoneMeta = const VerificationMeta(
    'timezone',
  );
  @override
  late final GeneratedColumn<String> timezone = GeneratedColumn<String>(
    'timezone',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 64,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _sleepMinutesMeta = const VerificationMeta(
    'sleepMinutes',
  );
  @override
  late final GeneratedColumn<int> sleepMinutes = GeneratedColumn<int>(
    'sleep_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _moodMeta = const VerificationMeta('mood');
  @override
  late final GeneratedColumn<int> mood = GeneratedColumn<int>(
    'mood',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _energyMeta = const VerificationMeta('energy');
  @override
  late final GeneratedColumn<int> energy = GeneratedColumn<int>(
    'energy',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _weightGramsMeta = const VerificationMeta(
    'weightGrams',
  );
  @override
  late final GeneratedColumn<int> weightGrams = GeneratedColumn<int>(
    'weight_grams',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _exerciseMinutesMeta = const VerificationMeta(
    'exerciseMinutes',
  );
  @override
  late final GeneratedColumn<int> exerciseMinutes = GeneratedColumn<int>(
    'exercise_minutes',
    aliasedName,
    true,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($DailyRecordsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($DailyRecordsTable.$converterupdatedAt);
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> deletedAt =
      GeneratedColumn<int>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($DailyRecordsTable.$converterdeletedAtn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    localDate,
    timezone,
    sleepMinutes,
    mood,
    energy,
    weightGrams,
    exerciseMinutes,
    createdAt,
    updatedAt,
    version,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_records';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyRecordRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('local_date')) {
      context.handle(
        _localDateMeta,
        localDate.isAcceptableOrUnknown(data['local_date']!, _localDateMeta),
      );
    } else if (isInserting) {
      context.missing(_localDateMeta);
    }
    if (data.containsKey('timezone')) {
      context.handle(
        _timezoneMeta,
        timezone.isAcceptableOrUnknown(data['timezone']!, _timezoneMeta),
      );
    } else if (isInserting) {
      context.missing(_timezoneMeta);
    }
    if (data.containsKey('sleep_minutes')) {
      context.handle(
        _sleepMinutesMeta,
        sleepMinutes.isAcceptableOrUnknown(
          data['sleep_minutes']!,
          _sleepMinutesMeta,
        ),
      );
    }
    if (data.containsKey('mood')) {
      context.handle(
        _moodMeta,
        mood.isAcceptableOrUnknown(data['mood']!, _moodMeta),
      );
    }
    if (data.containsKey('energy')) {
      context.handle(
        _energyMeta,
        energy.isAcceptableOrUnknown(data['energy']!, _energyMeta),
      );
    }
    if (data.containsKey('weight_grams')) {
      context.handle(
        _weightGramsMeta,
        weightGrams.isAcceptableOrUnknown(
          data['weight_grams']!,
          _weightGramsMeta,
        ),
      );
    }
    if (data.containsKey('exercise_minutes')) {
      context.handle(
        _exerciseMinutesMeta,
        exerciseMinutes.isAcceptableOrUnknown(
          data['exercise_minutes']!,
          _exerciseMinutesMeta,
        ),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  List<Set<GeneratedColumn>> get uniqueKeys => [
    {localDate, timezone},
  ];
  @override
  DailyRecordRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyRecordRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      localDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_date'],
      )!,
      timezone: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}timezone'],
      )!,
      sleepMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}sleep_minutes'],
      ),
      mood: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}mood'],
      ),
      energy: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}energy'],
      ),
      weightGrams: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}weight_grams'],
      ),
      exerciseMinutes: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}exercise_minutes'],
      ),
      createdAt: $DailyRecordsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $DailyRecordsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: $DailyRecordsTable.$converterdeletedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
    );
  }

  @override
  $DailyRecordsTable createAlias(String alias) {
    return $DailyRecordsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime, int> $converterdeletedAt =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime?, int?> $converterdeletedAtn =
      NullAwareTypeConverter.wrap($converterdeletedAt);
}

class DailyRecordRow extends DataClass implements Insertable<DailyRecordRow> {
  final String id;
  final String localDate;
  final String timezone;
  final int? sleepMinutes;
  final int? mood;
  final int? energy;
  final int? weightGrams;
  final int? exerciseMinutes;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final DateTime? deletedAt;
  const DailyRecordRow({
    required this.id,
    required this.localDate,
    required this.timezone,
    this.sleepMinutes,
    this.mood,
    this.energy,
    this.weightGrams,
    this.exerciseMinutes,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['local_date'] = Variable<String>(localDate);
    map['timezone'] = Variable<String>(timezone);
    if (!nullToAbsent || sleepMinutes != null) {
      map['sleep_minutes'] = Variable<int>(sleepMinutes);
    }
    if (!nullToAbsent || mood != null) {
      map['mood'] = Variable<int>(mood);
    }
    if (!nullToAbsent || energy != null) {
      map['energy'] = Variable<int>(energy);
    }
    if (!nullToAbsent || weightGrams != null) {
      map['weight_grams'] = Variable<int>(weightGrams);
    }
    if (!nullToAbsent || exerciseMinutes != null) {
      map['exercise_minutes'] = Variable<int>(exerciseMinutes);
    }
    {
      map['created_at'] = Variable<int>(
        $DailyRecordsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $DailyRecordsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(
        $DailyRecordsTable.$converterdeletedAtn.toSql(deletedAt),
      );
    }
    return map;
  }

  DailyRecordsCompanion toCompanion(bool nullToAbsent) {
    return DailyRecordsCompanion(
      id: Value(id),
      localDate: Value(localDate),
      timezone: Value(timezone),
      sleepMinutes: sleepMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(sleepMinutes),
      mood: mood == null && nullToAbsent ? const Value.absent() : Value(mood),
      energy: energy == null && nullToAbsent
          ? const Value.absent()
          : Value(energy),
      weightGrams: weightGrams == null && nullToAbsent
          ? const Value.absent()
          : Value(weightGrams),
      exerciseMinutes: exerciseMinutes == null && nullToAbsent
          ? const Value.absent()
          : Value(exerciseMinutes),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory DailyRecordRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyRecordRow(
      id: serializer.fromJson<String>(json['id']),
      localDate: serializer.fromJson<String>(json['localDate']),
      timezone: serializer.fromJson<String>(json['timezone']),
      sleepMinutes: serializer.fromJson<int?>(json['sleepMinutes']),
      mood: serializer.fromJson<int?>(json['mood']),
      energy: serializer.fromJson<int?>(json['energy']),
      weightGrams: serializer.fromJson<int?>(json['weightGrams']),
      exerciseMinutes: serializer.fromJson<int?>(json['exerciseMinutes']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'localDate': serializer.toJson<String>(localDate),
      'timezone': serializer.toJson<String>(timezone),
      'sleepMinutes': serializer.toJson<int?>(sleepMinutes),
      'mood': serializer.toJson<int?>(mood),
      'energy': serializer.toJson<int?>(energy),
      'weightGrams': serializer.toJson<int?>(weightGrams),
      'exerciseMinutes': serializer.toJson<int?>(exerciseMinutes),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  DailyRecordRow copyWith({
    String? id,
    String? localDate,
    String? timezone,
    Value<int?> sleepMinutes = const Value.absent(),
    Value<int?> mood = const Value.absent(),
    Value<int?> energy = const Value.absent(),
    Value<int?> weightGrams = const Value.absent(),
    Value<int?> exerciseMinutes = const Value.absent(),
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => DailyRecordRow(
    id: id ?? this.id,
    localDate: localDate ?? this.localDate,
    timezone: timezone ?? this.timezone,
    sleepMinutes: sleepMinutes.present ? sleepMinutes.value : this.sleepMinutes,
    mood: mood.present ? mood.value : this.mood,
    energy: energy.present ? energy.value : this.energy,
    weightGrams: weightGrams.present ? weightGrams.value : this.weightGrams,
    exerciseMinutes: exerciseMinutes.present
        ? exerciseMinutes.value
        : this.exerciseMinutes,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  DailyRecordRow copyWithCompanion(DailyRecordsCompanion data) {
    return DailyRecordRow(
      id: data.id.present ? data.id.value : this.id,
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      timezone: data.timezone.present ? data.timezone.value : this.timezone,
      sleepMinutes: data.sleepMinutes.present
          ? data.sleepMinutes.value
          : this.sleepMinutes,
      mood: data.mood.present ? data.mood.value : this.mood,
      energy: data.energy.present ? data.energy.value : this.energy,
      weightGrams: data.weightGrams.present
          ? data.weightGrams.value
          : this.weightGrams,
      exerciseMinutes: data.exerciseMinutes.present
          ? data.exerciseMinutes.value
          : this.exerciseMinutes,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyRecordRow(')
          ..write('id: $id, ')
          ..write('localDate: $localDate, ')
          ..write('timezone: $timezone, ')
          ..write('sleepMinutes: $sleepMinutes, ')
          ..write('mood: $mood, ')
          ..write('energy: $energy, ')
          ..write('weightGrams: $weightGrams, ')
          ..write('exerciseMinutes: $exerciseMinutes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    localDate,
    timezone,
    sleepMinutes,
    mood,
    energy,
    weightGrams,
    exerciseMinutes,
    createdAt,
    updatedAt,
    version,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyRecordRow &&
          other.id == this.id &&
          other.localDate == this.localDate &&
          other.timezone == this.timezone &&
          other.sleepMinutes == this.sleepMinutes &&
          other.mood == this.mood &&
          other.energy == this.energy &&
          other.weightGrams == this.weightGrams &&
          other.exerciseMinutes == this.exerciseMinutes &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt);
}

class DailyRecordsCompanion extends UpdateCompanion<DailyRecordRow> {
  final Value<String> id;
  final Value<String> localDate;
  final Value<String> timezone;
  final Value<int?> sleepMinutes;
  final Value<int?> mood;
  final Value<int?> energy;
  final Value<int?> weightGrams;
  final Value<int?> exerciseMinutes;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> version;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const DailyRecordsCompanion({
    this.id = const Value.absent(),
    this.localDate = const Value.absent(),
    this.timezone = const Value.absent(),
    this.sleepMinutes = const Value.absent(),
    this.mood = const Value.absent(),
    this.energy = const Value.absent(),
    this.weightGrams = const Value.absent(),
    this.exerciseMinutes = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyRecordsCompanion.insert({
    required String id,
    required String localDate,
    required String timezone,
    this.sleepMinutes = const Value.absent(),
    this.mood = const Value.absent(),
    this.energy = const Value.absent(),
    this.weightGrams = const Value.absent(),
    this.exerciseMinutes = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       localDate = Value(localDate),
       timezone = Value(timezone),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DailyRecordRow> custom({
    Expression<String>? id,
    Expression<String>? localDate,
    Expression<String>? timezone,
    Expression<int>? sleepMinutes,
    Expression<int>? mood,
    Expression<int>? energy,
    Expression<int>? weightGrams,
    Expression<int>? exerciseMinutes,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? version,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localDate != null) 'local_date': localDate,
      if (timezone != null) 'timezone': timezone,
      if (sleepMinutes != null) 'sleep_minutes': sleepMinutes,
      if (mood != null) 'mood': mood,
      if (energy != null) 'energy': energy,
      if (weightGrams != null) 'weight_grams': weightGrams,
      if (exerciseMinutes != null) 'exercise_minutes': exerciseMinutes,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyRecordsCompanion copyWith({
    Value<String>? id,
    Value<String>? localDate,
    Value<String>? timezone,
    Value<int?>? sleepMinutes,
    Value<int?>? mood,
    Value<int?>? energy,
    Value<int?>? weightGrams,
    Value<int?>? exerciseMinutes,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? version,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return DailyRecordsCompanion(
      id: id ?? this.id,
      localDate: localDate ?? this.localDate,
      timezone: timezone ?? this.timezone,
      sleepMinutes: sleepMinutes ?? this.sleepMinutes,
      mood: mood ?? this.mood,
      energy: energy ?? this.energy,
      weightGrams: weightGrams ?? this.weightGrams,
      exerciseMinutes: exerciseMinutes ?? this.exerciseMinutes,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (localDate.present) {
      map['local_date'] = Variable<String>(localDate.value);
    }
    if (timezone.present) {
      map['timezone'] = Variable<String>(timezone.value);
    }
    if (sleepMinutes.present) {
      map['sleep_minutes'] = Variable<int>(sleepMinutes.value);
    }
    if (mood.present) {
      map['mood'] = Variable<int>(mood.value);
    }
    if (energy.present) {
      map['energy'] = Variable<int>(energy.value);
    }
    if (weightGrams.present) {
      map['weight_grams'] = Variable<int>(weightGrams.value);
    }
    if (exerciseMinutes.present) {
      map['exercise_minutes'] = Variable<int>(exerciseMinutes.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $DailyRecordsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $DailyRecordsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(
        $DailyRecordsTable.$converterdeletedAtn.toSql(deletedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyRecordsCompanion(')
          ..write('id: $id, ')
          ..write('localDate: $localDate, ')
          ..write('timezone: $timezone, ')
          ..write('sleepMinutes: $sleepMinutes, ')
          ..write('mood: $mood, ')
          ..write('energy: $energy, ')
          ..write('weightGrams: $weightGrams, ')
          ..write('exerciseMinutes: $exerciseMinutes, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class $DailyActionsTable extends DailyActions
    with TableInfo<$DailyActionsTable, DailyActionRow> {
  @override
  final GeneratedDatabase attachedDatabase;
  final String? _alias;
  $DailyActionsTable(this.attachedDatabase, [this._alias]);
  static const VerificationMeta _idMeta = const VerificationMeta('id');
  @override
  late final GeneratedColumn<String> id = GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _localDateMeta = const VerificationMeta(
    'localDate',
  );
  @override
  late final GeneratedColumn<String> localDate = GeneratedColumn<String>(
    'local_date',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 10,
      maxTextLength: 10,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _goalIdMeta = const VerificationMeta('goalId');
  @override
  late final GeneratedColumn<String> goalId = GeneratedColumn<String>(
    'goal_id',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 36,
      maxTextLength: 36,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _titleMeta = const VerificationMeta('title');
  @override
  late final GeneratedColumn<String> title = GeneratedColumn<String>(
    'title',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 80,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _minimumActionMeta = const VerificationMeta(
    'minimumAction',
  );
  @override
  late final GeneratedColumn<String> minimumAction = GeneratedColumn<String>(
    'minimum_action',
    aliasedName,
    true,
    additionalChecks: GeneratedColumn.checkTextLength(maxTextLength: 120),
    type: DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const VerificationMeta _categoryMeta = const VerificationMeta(
    'category',
  );
  @override
  late final GeneratedColumn<String> category = GeneratedColumn<String>(
    'category',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 24,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _statusMeta = const VerificationMeta('status');
  @override
  late final GeneratedColumn<String> status = GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    additionalChecks: GeneratedColumn.checkTextLength(
      minTextLength: 1,
      maxTextLength: 24,
    ),
    type: DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const VerificationMeta _positionMeta = const VerificationMeta(
    'position',
  );
  @override
  late final GeneratedColumn<int> position = GeneratedColumn<int>(
    'position',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(0),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> createdAt =
      GeneratedColumn<int>(
        'created_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($DailyActionsTable.$convertercreatedAt);
  @override
  late final GeneratedColumnWithTypeConverter<DateTime, int> updatedAt =
      GeneratedColumn<int>(
        'updated_at',
        aliasedName,
        false,
        type: DriftSqlType.int,
        requiredDuringInsert: true,
      ).withConverter<DateTime>($DailyActionsTable.$converterupdatedAt);
  static const VerificationMeta _versionMeta = const VerificationMeta(
    'version',
  );
  @override
  late final GeneratedColumn<int> version = GeneratedColumn<int>(
    'version',
    aliasedName,
    false,
    type: DriftSqlType.int,
    requiredDuringInsert: false,
    defaultValue: const Constant(1),
  );
  @override
  late final GeneratedColumnWithTypeConverter<DateTime?, int> deletedAt =
      GeneratedColumn<int>(
        'deleted_at',
        aliasedName,
        true,
        type: DriftSqlType.int,
        requiredDuringInsert: false,
      ).withConverter<DateTime?>($DailyActionsTable.$converterdeletedAtn);
  @override
  List<GeneratedColumn> get $columns => [
    id,
    localDate,
    goalId,
    title,
    minimumAction,
    category,
    status,
    position,
    createdAt,
    updatedAt,
    version,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'daily_actions';
  @override
  VerificationContext validateIntegrity(
    Insertable<DailyActionRow> instance, {
    bool isInserting = false,
  }) {
    final context = VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    } else if (isInserting) {
      context.missing(_idMeta);
    }
    if (data.containsKey('local_date')) {
      context.handle(
        _localDateMeta,
        localDate.isAcceptableOrUnknown(data['local_date']!, _localDateMeta),
      );
    } else if (isInserting) {
      context.missing(_localDateMeta);
    }
    if (data.containsKey('goal_id')) {
      context.handle(
        _goalIdMeta,
        goalId.isAcceptableOrUnknown(data['goal_id']!, _goalIdMeta),
      );
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    } else if (isInserting) {
      context.missing(_titleMeta);
    }
    if (data.containsKey('minimum_action')) {
      context.handle(
        _minimumActionMeta,
        minimumAction.isAcceptableOrUnknown(
          data['minimum_action']!,
          _minimumActionMeta,
        ),
      );
    }
    if (data.containsKey('category')) {
      context.handle(
        _categoryMeta,
        category.isAcceptableOrUnknown(data['category']!, _categoryMeta),
      );
    } else if (isInserting) {
      context.missing(_categoryMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    } else if (isInserting) {
      context.missing(_statusMeta);
    }
    if (data.containsKey('position')) {
      context.handle(
        _positionMeta,
        position.isAcceptableOrUnknown(data['position']!, _positionMeta),
      );
    }
    if (data.containsKey('version')) {
      context.handle(
        _versionMeta,
        version.isAcceptableOrUnknown(data['version']!, _versionMeta),
      );
    }
    return context;
  }

  @override
  Set<GeneratedColumn> get $primaryKey => {id};
  @override
  DailyActionRow map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return DailyActionRow(
      id: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      localDate: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}local_date'],
      )!,
      goalId: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}goal_id'],
      ),
      title: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}title'],
      )!,
      minimumAction: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}minimum_action'],
      ),
      category: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}category'],
      )!,
      status: attachedDatabase.typeMapping.read(
        DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      position: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}position'],
      )!,
      createdAt: $DailyActionsTable.$convertercreatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}created_at'],
        )!,
      ),
      updatedAt: $DailyActionsTable.$converterupdatedAt.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}updated_at'],
        )!,
      ),
      version: attachedDatabase.typeMapping.read(
        DriftSqlType.int,
        data['${effectivePrefix}version'],
      )!,
      deletedAt: $DailyActionsTable.$converterdeletedAtn.fromSql(
        attachedDatabase.typeMapping.read(
          DriftSqlType.int,
          data['${effectivePrefix}deleted_at'],
        ),
      ),
    );
  }

  @override
  $DailyActionsTable createAlias(String alias) {
    return $DailyActionsTable(attachedDatabase, alias);
  }

  static TypeConverter<DateTime, int> $convertercreatedAt =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime, int> $converterupdatedAt =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime, int> $converterdeletedAt =
      const UtcDateTimeConverter();
  static TypeConverter<DateTime?, int?> $converterdeletedAtn =
      NullAwareTypeConverter.wrap($converterdeletedAt);
}

class DailyActionRow extends DataClass implements Insertable<DailyActionRow> {
  final String id;
  final String localDate;
  final String? goalId;
  final String title;
  final String? minimumAction;
  final String category;
  final String status;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final DateTime? deletedAt;
  const DailyActionRow({
    required this.id,
    required this.localDate,
    this.goalId,
    required this.title,
    this.minimumAction,
    required this.category,
    required this.status,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    this.deletedAt,
  });
  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    map['id'] = Variable<String>(id);
    map['local_date'] = Variable<String>(localDate);
    if (!nullToAbsent || goalId != null) {
      map['goal_id'] = Variable<String>(goalId);
    }
    map['title'] = Variable<String>(title);
    if (!nullToAbsent || minimumAction != null) {
      map['minimum_action'] = Variable<String>(minimumAction);
    }
    map['category'] = Variable<String>(category);
    map['status'] = Variable<String>(status);
    map['position'] = Variable<int>(position);
    {
      map['created_at'] = Variable<int>(
        $DailyActionsTable.$convertercreatedAt.toSql(createdAt),
      );
    }
    {
      map['updated_at'] = Variable<int>(
        $DailyActionsTable.$converterupdatedAt.toSql(updatedAt),
      );
    }
    map['version'] = Variable<int>(version);
    if (!nullToAbsent || deletedAt != null) {
      map['deleted_at'] = Variable<int>(
        $DailyActionsTable.$converterdeletedAtn.toSql(deletedAt),
      );
    }
    return map;
  }

  DailyActionsCompanion toCompanion(bool nullToAbsent) {
    return DailyActionsCompanion(
      id: Value(id),
      localDate: Value(localDate),
      goalId: goalId == null && nullToAbsent
          ? const Value.absent()
          : Value(goalId),
      title: Value(title),
      minimumAction: minimumAction == null && nullToAbsent
          ? const Value.absent()
          : Value(minimumAction),
      category: Value(category),
      status: Value(status),
      position: Value(position),
      createdAt: Value(createdAt),
      updatedAt: Value(updatedAt),
      version: Value(version),
      deletedAt: deletedAt == null && nullToAbsent
          ? const Value.absent()
          : Value(deletedAt),
    );
  }

  factory DailyActionRow.fromJson(
    Map<String, dynamic> json, {
    ValueSerializer? serializer,
  }) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return DailyActionRow(
      id: serializer.fromJson<String>(json['id']),
      localDate: serializer.fromJson<String>(json['localDate']),
      goalId: serializer.fromJson<String?>(json['goalId']),
      title: serializer.fromJson<String>(json['title']),
      minimumAction: serializer.fromJson<String?>(json['minimumAction']),
      category: serializer.fromJson<String>(json['category']),
      status: serializer.fromJson<String>(json['status']),
      position: serializer.fromJson<int>(json['position']),
      createdAt: serializer.fromJson<DateTime>(json['createdAt']),
      updatedAt: serializer.fromJson<DateTime>(json['updatedAt']),
      version: serializer.fromJson<int>(json['version']),
      deletedAt: serializer.fromJson<DateTime?>(json['deletedAt']),
    );
  }
  @override
  Map<String, dynamic> toJson({ValueSerializer? serializer}) {
    serializer ??= driftRuntimeOptions.defaultSerializer;
    return <String, dynamic>{
      'id': serializer.toJson<String>(id),
      'localDate': serializer.toJson<String>(localDate),
      'goalId': serializer.toJson<String?>(goalId),
      'title': serializer.toJson<String>(title),
      'minimumAction': serializer.toJson<String?>(minimumAction),
      'category': serializer.toJson<String>(category),
      'status': serializer.toJson<String>(status),
      'position': serializer.toJson<int>(position),
      'createdAt': serializer.toJson<DateTime>(createdAt),
      'updatedAt': serializer.toJson<DateTime>(updatedAt),
      'version': serializer.toJson<int>(version),
      'deletedAt': serializer.toJson<DateTime?>(deletedAt),
    };
  }

  DailyActionRow copyWith({
    String? id,
    String? localDate,
    Value<String?> goalId = const Value.absent(),
    String? title,
    Value<String?> minimumAction = const Value.absent(),
    String? category,
    String? status,
    int? position,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? version,
    Value<DateTime?> deletedAt = const Value.absent(),
  }) => DailyActionRow(
    id: id ?? this.id,
    localDate: localDate ?? this.localDate,
    goalId: goalId.present ? goalId.value : this.goalId,
    title: title ?? this.title,
    minimumAction: minimumAction.present
        ? minimumAction.value
        : this.minimumAction,
    category: category ?? this.category,
    status: status ?? this.status,
    position: position ?? this.position,
    createdAt: createdAt ?? this.createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
    version: version ?? this.version,
    deletedAt: deletedAt.present ? deletedAt.value : this.deletedAt,
  );
  DailyActionRow copyWithCompanion(DailyActionsCompanion data) {
    return DailyActionRow(
      id: data.id.present ? data.id.value : this.id,
      localDate: data.localDate.present ? data.localDate.value : this.localDate,
      goalId: data.goalId.present ? data.goalId.value : this.goalId,
      title: data.title.present ? data.title.value : this.title,
      minimumAction: data.minimumAction.present
          ? data.minimumAction.value
          : this.minimumAction,
      category: data.category.present ? data.category.value : this.category,
      status: data.status.present ? data.status.value : this.status,
      position: data.position.present ? data.position.value : this.position,
      createdAt: data.createdAt.present ? data.createdAt.value : this.createdAt,
      updatedAt: data.updatedAt.present ? data.updatedAt.value : this.updatedAt,
      version: data.version.present ? data.version.value : this.version,
      deletedAt: data.deletedAt.present ? data.deletedAt.value : this.deletedAt,
    );
  }

  @override
  String toString() {
    return (StringBuffer('DailyActionRow(')
          ..write('id: $id, ')
          ..write('localDate: $localDate, ')
          ..write('goalId: $goalId, ')
          ..write('title: $title, ')
          ..write('minimumAction: $minimumAction, ')
          ..write('category: $category, ')
          ..write('status: $status, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt')
          ..write(')'))
        .toString();
  }

  @override
  int get hashCode => Object.hash(
    id,
    localDate,
    goalId,
    title,
    minimumAction,
    category,
    status,
    position,
    createdAt,
    updatedAt,
    version,
    deletedAt,
  );
  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      (other is DailyActionRow &&
          other.id == this.id &&
          other.localDate == this.localDate &&
          other.goalId == this.goalId &&
          other.title == this.title &&
          other.minimumAction == this.minimumAction &&
          other.category == this.category &&
          other.status == this.status &&
          other.position == this.position &&
          other.createdAt == this.createdAt &&
          other.updatedAt == this.updatedAt &&
          other.version == this.version &&
          other.deletedAt == this.deletedAt);
}

class DailyActionsCompanion extends UpdateCompanion<DailyActionRow> {
  final Value<String> id;
  final Value<String> localDate;
  final Value<String?> goalId;
  final Value<String> title;
  final Value<String?> minimumAction;
  final Value<String> category;
  final Value<String> status;
  final Value<int> position;
  final Value<DateTime> createdAt;
  final Value<DateTime> updatedAt;
  final Value<int> version;
  final Value<DateTime?> deletedAt;
  final Value<int> rowid;
  const DailyActionsCompanion({
    this.id = const Value.absent(),
    this.localDate = const Value.absent(),
    this.goalId = const Value.absent(),
    this.title = const Value.absent(),
    this.minimumAction = const Value.absent(),
    this.category = const Value.absent(),
    this.status = const Value.absent(),
    this.position = const Value.absent(),
    this.createdAt = const Value.absent(),
    this.updatedAt = const Value.absent(),
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  });
  DailyActionsCompanion.insert({
    required String id,
    required String localDate,
    this.goalId = const Value.absent(),
    required String title,
    this.minimumAction = const Value.absent(),
    required String category,
    required String status,
    this.position = const Value.absent(),
    required DateTime createdAt,
    required DateTime updatedAt,
    this.version = const Value.absent(),
    this.deletedAt = const Value.absent(),
    this.rowid = const Value.absent(),
  }) : id = Value(id),
       localDate = Value(localDate),
       title = Value(title),
       category = Value(category),
       status = Value(status),
       createdAt = Value(createdAt),
       updatedAt = Value(updatedAt);
  static Insertable<DailyActionRow> custom({
    Expression<String>? id,
    Expression<String>? localDate,
    Expression<String>? goalId,
    Expression<String>? title,
    Expression<String>? minimumAction,
    Expression<String>? category,
    Expression<String>? status,
    Expression<int>? position,
    Expression<int>? createdAt,
    Expression<int>? updatedAt,
    Expression<int>? version,
    Expression<int>? deletedAt,
    Expression<int>? rowid,
  }) {
    return RawValuesInsertable({
      if (id != null) 'id': id,
      if (localDate != null) 'local_date': localDate,
      if (goalId != null) 'goal_id': goalId,
      if (title != null) 'title': title,
      if (minimumAction != null) 'minimum_action': minimumAction,
      if (category != null) 'category': category,
      if (status != null) 'status': status,
      if (position != null) 'position': position,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (version != null) 'version': version,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  DailyActionsCompanion copyWith({
    Value<String>? id,
    Value<String>? localDate,
    Value<String?>? goalId,
    Value<String>? title,
    Value<String?>? minimumAction,
    Value<String>? category,
    Value<String>? status,
    Value<int>? position,
    Value<DateTime>? createdAt,
    Value<DateTime>? updatedAt,
    Value<int>? version,
    Value<DateTime?>? deletedAt,
    Value<int>? rowid,
  }) {
    return DailyActionsCompanion(
      id: id ?? this.id,
      localDate: localDate ?? this.localDate,
      goalId: goalId ?? this.goalId,
      title: title ?? this.title,
      minimumAction: minimumAction ?? this.minimumAction,
      category: category ?? this.category,
      status: status ?? this.status,
      position: position ?? this.position,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      version: version ?? this.version,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, Expression> toColumns(bool nullToAbsent) {
    final map = <String, Expression>{};
    if (id.present) {
      map['id'] = Variable<String>(id.value);
    }
    if (localDate.present) {
      map['local_date'] = Variable<String>(localDate.value);
    }
    if (goalId.present) {
      map['goal_id'] = Variable<String>(goalId.value);
    }
    if (title.present) {
      map['title'] = Variable<String>(title.value);
    }
    if (minimumAction.present) {
      map['minimum_action'] = Variable<String>(minimumAction.value);
    }
    if (category.present) {
      map['category'] = Variable<String>(category.value);
    }
    if (status.present) {
      map['status'] = Variable<String>(status.value);
    }
    if (position.present) {
      map['position'] = Variable<int>(position.value);
    }
    if (createdAt.present) {
      map['created_at'] = Variable<int>(
        $DailyActionsTable.$convertercreatedAt.toSql(createdAt.value),
      );
    }
    if (updatedAt.present) {
      map['updated_at'] = Variable<int>(
        $DailyActionsTable.$converterupdatedAt.toSql(updatedAt.value),
      );
    }
    if (version.present) {
      map['version'] = Variable<int>(version.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = Variable<int>(
        $DailyActionsTable.$converterdeletedAtn.toSql(deletedAt.value),
      );
    }
    if (rowid.present) {
      map['rowid'] = Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('DailyActionsCompanion(')
          ..write('id: $id, ')
          ..write('localDate: $localDate, ')
          ..write('goalId: $goalId, ')
          ..write('title: $title, ')
          ..write('minimumAction: $minimumAction, ')
          ..write('category: $category, ')
          ..write('status: $status, ')
          ..write('position: $position, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('version: $version, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AppMetadataTable appMetadata = $AppMetadataTable(this);
  late final $DailyRecordsTable dailyRecords = $DailyRecordsTable(this);
  late final $DailyActionsTable dailyActions = $DailyActionsTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [
    appMetadata,
    dailyRecords,
    dailyActions,
  ];
}

typedef $$AppMetadataTableCreateCompanionBuilder =
    AppMetadataCompanion Function({
      required String metadataKey,
      required String metadataValue,
      required DateTime updatedAt,
      Value<int> rowid,
    });
typedef $$AppMetadataTableUpdateCompanionBuilder =
    AppMetadataCompanion Function({
      Value<String> metadataKey,
      Value<String> metadataValue,
      Value<DateTime> updatedAt,
      Value<int> rowid,
    });

class $$AppMetadataTableFilterComposer
    extends Composer<_$AppDatabase, $AppMetadataTable> {
  $$AppMetadataTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get metadataKey => $composableBuilder(
    column: $table.metadataKey,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get metadataValue => $composableBuilder(
    column: $table.metadataValue,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$AppMetadataTableOrderingComposer
    extends Composer<_$AppDatabase, $AppMetadataTable> {
  $$AppMetadataTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get metadataKey => $composableBuilder(
    column: $table.metadataKey,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get metadataValue => $composableBuilder(
    column: $table.metadataValue,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$AppMetadataTableAnnotationComposer
    extends Composer<_$AppDatabase, $AppMetadataTable> {
  $$AppMetadataTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get metadataKey => $composableBuilder(
    column: $table.metadataKey,
    builder: (column) => column,
  );

  GeneratedColumn<String> get metadataValue => $composableBuilder(
    column: $table.metadataValue,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);
}

class $$AppMetadataTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $AppMetadataTable,
          AppMetadataData,
          $$AppMetadataTableFilterComposer,
          $$AppMetadataTableOrderingComposer,
          $$AppMetadataTableAnnotationComposer,
          $$AppMetadataTableCreateCompanionBuilder,
          $$AppMetadataTableUpdateCompanionBuilder,
          (
            AppMetadataData,
            BaseReferences<_$AppDatabase, $AppMetadataTable, AppMetadataData>,
          ),
          AppMetadataData,
          PrefetchHooks Function()
        > {
  $$AppMetadataTableTableManager(_$AppDatabase db, $AppMetadataTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$AppMetadataTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$AppMetadataTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$AppMetadataTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> metadataKey = const Value.absent(),
                Value<String> metadataValue = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => AppMetadataCompanion(
                metadataKey: metadataKey,
                metadataValue: metadataValue,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String metadataKey,
                required String metadataValue,
                required DateTime updatedAt,
                Value<int> rowid = const Value.absent(),
              }) => AppMetadataCompanion.insert(
                metadataKey: metadataKey,
                metadataValue: metadataValue,
                updatedAt: updatedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$AppMetadataTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $AppMetadataTable,
      AppMetadataData,
      $$AppMetadataTableFilterComposer,
      $$AppMetadataTableOrderingComposer,
      $$AppMetadataTableAnnotationComposer,
      $$AppMetadataTableCreateCompanionBuilder,
      $$AppMetadataTableUpdateCompanionBuilder,
      (
        AppMetadataData,
        BaseReferences<_$AppDatabase, $AppMetadataTable, AppMetadataData>,
      ),
      AppMetadataData,
      PrefetchHooks Function()
    >;
typedef $$DailyRecordsTableCreateCompanionBuilder =
    DailyRecordsCompanion Function({
      required String id,
      required String localDate,
      required String timezone,
      Value<int?> sleepMinutes,
      Value<int?> mood,
      Value<int?> energy,
      Value<int?> weightGrams,
      Value<int?> exerciseMinutes,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> version,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$DailyRecordsTableUpdateCompanionBuilder =
    DailyRecordsCompanion Function({
      Value<String> id,
      Value<String> localDate,
      Value<String> timezone,
      Value<int?> sleepMinutes,
      Value<int?> mood,
      Value<int?> energy,
      Value<int?> weightGrams,
      Value<int?> exerciseMinutes,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> version,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$DailyRecordsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyRecordsTable> {
  $$DailyRecordsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get sleepMinutes => $composableBuilder(
    column: $table.sleepMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get energy => $composableBuilder(
    column: $table.energy,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get weightGrams => $composableBuilder(
    column: $table.weightGrams,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get exerciseMinutes => $composableBuilder(
    column: $table.exerciseMinutes,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get deletedAt =>
      $composableBuilder(
        column: $table.deletedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$DailyRecordsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyRecordsTable> {
  $$DailyRecordsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get timezone => $composableBuilder(
    column: $table.timezone,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get sleepMinutes => $composableBuilder(
    column: $table.sleepMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get mood => $composableBuilder(
    column: $table.mood,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get energy => $composableBuilder(
    column: $table.energy,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get weightGrams => $composableBuilder(
    column: $table.weightGrams,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get exerciseMinutes => $composableBuilder(
    column: $table.exerciseMinutes,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyRecordsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyRecordsTable> {
  $$DailyRecordsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get localDate =>
      $composableBuilder(column: $table.localDate, builder: (column) => column);

  GeneratedColumn<String> get timezone =>
      $composableBuilder(column: $table.timezone, builder: (column) => column);

  GeneratedColumn<int> get sleepMinutes => $composableBuilder(
    column: $table.sleepMinutes,
    builder: (column) => column,
  );

  GeneratedColumn<int> get mood =>
      $composableBuilder(column: $table.mood, builder: (column) => column);

  GeneratedColumn<int> get energy =>
      $composableBuilder(column: $table.energy, builder: (column) => column);

  GeneratedColumn<int> get weightGrams => $composableBuilder(
    column: $table.weightGrams,
    builder: (column) => column,
  );

  GeneratedColumn<int> get exerciseMinutes => $composableBuilder(
    column: $table.exerciseMinutes,
    builder: (column) => column,
  );

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$DailyRecordsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyRecordsTable,
          DailyRecordRow,
          $$DailyRecordsTableFilterComposer,
          $$DailyRecordsTableOrderingComposer,
          $$DailyRecordsTableAnnotationComposer,
          $$DailyRecordsTableCreateCompanionBuilder,
          $$DailyRecordsTableUpdateCompanionBuilder,
          (
            DailyRecordRow,
            BaseReferences<_$AppDatabase, $DailyRecordsTable, DailyRecordRow>,
          ),
          DailyRecordRow,
          PrefetchHooks Function()
        > {
  $$DailyRecordsTableTableManager(_$AppDatabase db, $DailyRecordsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyRecordsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyRecordsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyRecordsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> localDate = const Value.absent(),
                Value<String> timezone = const Value.absent(),
                Value<int?> sleepMinutes = const Value.absent(),
                Value<int?> mood = const Value.absent(),
                Value<int?> energy = const Value.absent(),
                Value<int?> weightGrams = const Value.absent(),
                Value<int?> exerciseMinutes = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyRecordsCompanion(
                id: id,
                localDate: localDate,
                timezone: timezone,
                sleepMinutes: sleepMinutes,
                mood: mood,
                energy: energy,
                weightGrams: weightGrams,
                exerciseMinutes: exerciseMinutes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                version: version,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String localDate,
                required String timezone,
                Value<int?> sleepMinutes = const Value.absent(),
                Value<int?> mood = const Value.absent(),
                Value<int?> energy = const Value.absent(),
                Value<int?> weightGrams = const Value.absent(),
                Value<int?> exerciseMinutes = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> version = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyRecordsCompanion.insert(
                id: id,
                localDate: localDate,
                timezone: timezone,
                sleepMinutes: sleepMinutes,
                mood: mood,
                energy: energy,
                weightGrams: weightGrams,
                exerciseMinutes: exerciseMinutes,
                createdAt: createdAt,
                updatedAt: updatedAt,
                version: version,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyRecordsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyRecordsTable,
      DailyRecordRow,
      $$DailyRecordsTableFilterComposer,
      $$DailyRecordsTableOrderingComposer,
      $$DailyRecordsTableAnnotationComposer,
      $$DailyRecordsTableCreateCompanionBuilder,
      $$DailyRecordsTableUpdateCompanionBuilder,
      (
        DailyRecordRow,
        BaseReferences<_$AppDatabase, $DailyRecordsTable, DailyRecordRow>,
      ),
      DailyRecordRow,
      PrefetchHooks Function()
    >;
typedef $$DailyActionsTableCreateCompanionBuilder =
    DailyActionsCompanion Function({
      required String id,
      required String localDate,
      Value<String?> goalId,
      required String title,
      Value<String?> minimumAction,
      required String category,
      required String status,
      Value<int> position,
      required DateTime createdAt,
      required DateTime updatedAt,
      Value<int> version,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });
typedef $$DailyActionsTableUpdateCompanionBuilder =
    DailyActionsCompanion Function({
      Value<String> id,
      Value<String> localDate,
      Value<String?> goalId,
      Value<String> title,
      Value<String?> minimumAction,
      Value<String> category,
      Value<String> status,
      Value<int> position,
      Value<DateTime> createdAt,
      Value<DateTime> updatedAt,
      Value<int> version,
      Value<DateTime?> deletedAt,
      Value<int> rowid,
    });

class $$DailyActionsTableFilterComposer
    extends Composer<_$AppDatabase, $DailyActionsTable> {
  $$DailyActionsTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get goalId => $composableBuilder(
    column: $table.goalId,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get minimumAction => $composableBuilder(
    column: $table.minimumAction,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnFilters(column),
  );

  ColumnFilters<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get createdAt =>
      $composableBuilder(
        column: $table.createdAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnWithTypeConverterFilters<DateTime, DateTime, int> get updatedAt =>
      $composableBuilder(
        column: $table.updatedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );

  ColumnFilters<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnFilters(column),
  );

  ColumnWithTypeConverterFilters<DateTime?, DateTime, int> get deletedAt =>
      $composableBuilder(
        column: $table.deletedAt,
        builder: (column) => ColumnWithTypeConverterFilters(column),
      );
}

class $$DailyActionsTableOrderingComposer
    extends Composer<_$AppDatabase, $DailyActionsTable> {
  $$DailyActionsTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get localDate => $composableBuilder(
    column: $table.localDate,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get goalId => $composableBuilder(
    column: $table.goalId,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get minimumAction => $composableBuilder(
    column: $table.minimumAction,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get category => $composableBuilder(
    column: $table.category,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get position => $composableBuilder(
    column: $table.position,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get version => $composableBuilder(
    column: $table.version,
    builder: (column) => ColumnOrderings(column),
  );

  ColumnOrderings<int> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => ColumnOrderings(column),
  );
}

class $$DailyActionsTableAnnotationComposer
    extends Composer<_$AppDatabase, $DailyActionsTable> {
  $$DailyActionsTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  GeneratedColumn<String> get localDate =>
      $composableBuilder(column: $table.localDate, builder: (column) => column);

  GeneratedColumn<String> get goalId =>
      $composableBuilder(column: $table.goalId, builder: (column) => column);

  GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  GeneratedColumn<String> get minimumAction => $composableBuilder(
    column: $table.minimumAction,
    builder: (column) => column,
  );

  GeneratedColumn<String> get category =>
      $composableBuilder(column: $table.category, builder: (column) => column);

  GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  GeneratedColumn<int> get position =>
      $composableBuilder(column: $table.position, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime, int> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  GeneratedColumn<int> get version =>
      $composableBuilder(column: $table.version, builder: (column) => column);

  GeneratedColumnWithTypeConverter<DateTime?, int> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$DailyActionsTableTableManager
    extends
        RootTableManager<
          _$AppDatabase,
          $DailyActionsTable,
          DailyActionRow,
          $$DailyActionsTableFilterComposer,
          $$DailyActionsTableOrderingComposer,
          $$DailyActionsTableAnnotationComposer,
          $$DailyActionsTableCreateCompanionBuilder,
          $$DailyActionsTableUpdateCompanionBuilder,
          (
            DailyActionRow,
            BaseReferences<_$AppDatabase, $DailyActionsTable, DailyActionRow>,
          ),
          DailyActionRow,
          PrefetchHooks Function()
        > {
  $$DailyActionsTableTableManager(_$AppDatabase db, $DailyActionsTable table)
    : super(
        TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              $$DailyActionsTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              $$DailyActionsTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              $$DailyActionsTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                Value<String> id = const Value.absent(),
                Value<String> localDate = const Value.absent(),
                Value<String?> goalId = const Value.absent(),
                Value<String> title = const Value.absent(),
                Value<String?> minimumAction = const Value.absent(),
                Value<String> category = const Value.absent(),
                Value<String> status = const Value.absent(),
                Value<int> position = const Value.absent(),
                Value<DateTime> createdAt = const Value.absent(),
                Value<DateTime> updatedAt = const Value.absent(),
                Value<int> version = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyActionsCompanion(
                id: id,
                localDate: localDate,
                goalId: goalId,
                title: title,
                minimumAction: minimumAction,
                category: category,
                status: status,
                position: position,
                createdAt: createdAt,
                updatedAt: updatedAt,
                version: version,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                required String id,
                required String localDate,
                Value<String?> goalId = const Value.absent(),
                required String title,
                Value<String?> minimumAction = const Value.absent(),
                required String category,
                required String status,
                Value<int> position = const Value.absent(),
                required DateTime createdAt,
                required DateTime updatedAt,
                Value<int> version = const Value.absent(),
                Value<DateTime?> deletedAt = const Value.absent(),
                Value<int> rowid = const Value.absent(),
              }) => DailyActionsCompanion.insert(
                id: id,
                localDate: localDate,
                goalId: goalId,
                title: title,
                minimumAction: minimumAction,
                category: category,
                status: status,
                position: position,
                createdAt: createdAt,
                updatedAt: updatedAt,
                version: version,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$DailyActionsTableProcessedTableManager =
    ProcessedTableManager<
      _$AppDatabase,
      $DailyActionsTable,
      DailyActionRow,
      $$DailyActionsTableFilterComposer,
      $$DailyActionsTableOrderingComposer,
      $$DailyActionsTableAnnotationComposer,
      $$DailyActionsTableCreateCompanionBuilder,
      $$DailyActionsTableUpdateCompanionBuilder,
      (
        DailyActionRow,
        BaseReferences<_$AppDatabase, $DailyActionsTable, DailyActionRow>,
      ),
      DailyActionRow,
      PrefetchHooks Function()
    >;

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AppMetadataTableTableManager get appMetadata =>
      $$AppMetadataTableTableManager(_db, _db.appMetadata);
  $$DailyRecordsTableTableManager get dailyRecords =>
      $$DailyRecordsTableTableManager(_db, _db.dailyRecords);
  $$DailyActionsTableTableManager get dailyActions =>
      $$DailyActionsTableTableManager(_db, _db.dailyActions);
}
