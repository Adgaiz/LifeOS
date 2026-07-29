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

abstract class _$AppDatabase extends GeneratedDatabase {
  _$AppDatabase(QueryExecutor e) : super(e);
  $AppDatabaseManager get managers => $AppDatabaseManager(this);
  late final $AppMetadataTable appMetadata = $AppMetadataTable(this);
  @override
  Iterable<TableInfo<Table, Object?>> get allTables =>
      allSchemaEntities.whereType<TableInfo<Table, Object?>>();
  @override
  List<DatabaseSchemaEntity> get allSchemaEntities => [appMetadata];
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

class $AppDatabaseManager {
  final _$AppDatabase _db;
  $AppDatabaseManager(this._db);
  $$AppMetadataTableTableManager get appMetadata =>
      $$AppMetadataTableTableManager(_db, _db.appMetadata);
}
