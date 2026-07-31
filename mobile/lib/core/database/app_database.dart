import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';

part 'app_database.g.dart';

final class UtcDateTimeConverter extends TypeConverter<DateTime, int> {
  const UtcDateTimeConverter();

  @override
  DateTime fromSql(int fromDb) {
    return DateTime.fromMillisecondsSinceEpoch(fromDb, isUtc: true);
  }

  @override
  int toSql(DateTime value) => value.toUtc().millisecondsSinceEpoch;
}

class AppMetadata extends Table {
  TextColumn get metadataKey => text().withLength(min: 1, max: 100)();

  TextColumn get metadataValue => text().withLength(max: 500)();

  IntColumn get updatedAt => integer().map(const UtcDateTimeConverter())();

  @override
  Set<Column<Object>> get primaryKey => {metadataKey};
}

@DataClassName('DailyRecordRow')
class DailyRecords extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();

  TextColumn get localDate => text().withLength(min: 10, max: 10)();

  TextColumn get timezone => text().withLength(min: 1, max: 64)();

  IntColumn get sleepMinutes => integer().nullable()();

  IntColumn get mood => integer().nullable()();

  IntColumn get energy => integer().nullable()();

  IntColumn get weightGrams => integer().nullable()();

  IntColumn get exerciseMinutes => integer().nullable()();

  IntColumn get createdAt => integer().map(const UtcDateTimeConverter())();

  IntColumn get updatedAt => integer().map(const UtcDateTimeConverter())();

  IntColumn get version => integer().withDefault(const Constant(1))();

  IntColumn get deletedAt =>
      integer().map(const UtcDateTimeConverter()).nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};

  @override
  List<Set<Column<Object>>> get uniqueKeys => [
    {localDate, timezone},
  ];
}

@DataClassName('DailyActionRow')
class DailyActions extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();

  TextColumn get localDate => text().withLength(min: 10, max: 10)();

  TextColumn get goalId => text().withLength(min: 36, max: 36).nullable()();

  TextColumn get title => text().withLength(min: 1, max: 80)();

  TextColumn get minimumAction => text().withLength(max: 120).nullable()();

  TextColumn get category => text().withLength(min: 1, max: 24)();

  TextColumn get status => text().withLength(min: 1, max: 24)();

  IntColumn get position => integer().withDefault(const Constant(0))();

  IntColumn get createdAt => integer().map(const UtcDateTimeConverter())();

  IntColumn get updatedAt => integer().map(const UtcDateTimeConverter())();

  IntColumn get version => integer().withDefault(const Constant(1))();

  IntColumn get deletedAt =>
      integer().map(const UtcDateTimeConverter()).nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('VisionRow')
class Visions extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();

  TextColumn get title => text().withLength(min: 1, max: 80)();

  TextColumn get content => text().withLength(min: 1, max: 5000)();

  TextColumn get status => text().withLength(min: 1, max: 16)();

  IntColumn get createdAt => integer().map(const UtcDateTimeConverter())();

  IntColumn get updatedAt => integer().map(const UtcDateTimeConverter())();

  IntColumn get version => integer().withDefault(const Constant(1))();

  IntColumn get deletedAt =>
      integer().map(const UtcDateTimeConverter()).nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('GoalRow')
class Goals extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();

  TextColumn get visionId => text().withLength(min: 36, max: 36).nullable()();

  TextColumn get title => text().withLength(min: 1, max: 80)();

  TextColumn get description => text().withLength(max: 2000).nullable()();

  TextColumn get startDate => text().withLength(min: 10, max: 10)();

  TextColumn get endDate => text().withLength(min: 10, max: 10)();

  TextColumn get status => text().withLength(min: 1, max: 16)();

  IntColumn get createdAt => integer().map(const UtcDateTimeConverter())();

  IntColumn get updatedAt => integer().map(const UtcDateTimeConverter())();

  IntColumn get version => integer().withDefault(const Constant(1))();

  IntColumn get deletedAt =>
      integer().map(const UtcDateTimeConverter()).nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('GoalKeyResultRow')
class GoalKeyResults extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();

  TextColumn get goalId => text().references(Goals, #id)();

  TextColumn get title => text().withLength(min: 1, max: 120)();

  IntColumn get progress => integer()
      .check(const CustomExpression<bool>('progress BETWEEN 0 AND 100'))
      .withDefault(const Constant(0))();

  IntColumn get position => integer().withDefault(const Constant(0))();

  IntColumn get createdAt => integer().map(const UtcDateTimeConverter())();

  IntColumn get updatedAt => integer().map(const UtcDateTimeConverter())();

  IntColumn get version => integer().withDefault(const Constant(1))();

  IntColumn get deletedAt =>
      integer().map(const UtcDateTimeConverter()).nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('DiaryEntryRow')
class DiaryEntries extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();

  TextColumn get localDate => text().withLength(min: 10, max: 10)();

  TextColumn get markdown => text().withLength(min: 1, max: 50000)();

  IntColumn get createdAt => integer().map(const UtcDateTimeConverter())();

  IntColumn get updatedAt => integer().map(const UtcDateTimeConverter())();

  IntColumn get version => integer().withDefault(const Constant(1))();

  IntColumn get deletedAt =>
      integer().map(const UtcDateTimeConverter()).nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('DiaryTagRow')
class DiaryTags extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();

  TextColumn get diaryId => text().references(DiaryEntries, #id)();

  TextColumn get name => text().withLength(min: 1, max: 20)();

  TextColumn get normalizedName => text().withLength(min: 1, max: 20)();

  IntColumn get position => integer().withDefault(const Constant(0))();

  IntColumn get createdAt => integer().map(const UtcDateTimeConverter())();

  IntColumn get updatedAt => integer().map(const UtcDateTimeConverter())();

  IntColumn get version => integer().withDefault(const Constant(1))();

  IntColumn get deletedAt =>
      integer().map(const UtcDateTimeConverter()).nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DataClassName('DiaryAttachmentRow')
class DiaryAttachments extends Table {
  TextColumn get id => text().withLength(min: 36, max: 36)();

  TextColumn get diaryId => text().references(DiaryEntries, #id)();

  TextColumn get relativePath => text().withLength(min: 1, max: 500)();

  TextColumn get thumbnailRelativePath => text().withLength(min: 1, max: 500)();

  TextColumn get mediaType => text().withLength(min: 1, max: 100)();

  IntColumn get sizeBytes =>
      integer().check(const CustomExpression<bool>('size_bytes > 0'))();

  IntColumn get width =>
      integer().check(const CustomExpression<bool>('width > 0'))();

  IntColumn get height =>
      integer().check(const CustomExpression<bool>('height > 0'))();

  TextColumn get checksumSha256 => text().withLength(min: 64, max: 64)();

  IntColumn get position => integer().withDefault(const Constant(0))();

  IntColumn get createdAt => integer().map(const UtcDateTimeConverter())();

  IntColumn get updatedAt => integer().map(const UtcDateTimeConverter())();

  IntColumn get version => integer().withDefault(const Constant(1))();

  IntColumn get deletedAt =>
      integer().map(const UtcDateTimeConverter()).nullable()();

  IntColumn get filesDeletedAt =>
      integer().map(const UtcDateTimeConverter()).nullable()();

  @override
  Set<Column<Object>> get primaryKey => {id};
}

@DriftDatabase(
  tables: [
    AppMetadata,
    DailyRecords,
    DailyActions,
    Visions,
    Goals,
    GoalKeyResults,
    DiaryEntries,
    DiaryTags,
    DiaryAttachments,
  ],
)
final class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'lifeos'));

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 5;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) async {
      await migrator.createAll();
      await _createDiaryIndexes();
    },
    onUpgrade: (migrator, from, to) async {
      if (from < 2) {
        await migrator.createTable(dailyRecords);
        await migrator.createTable(dailyActions);
      }
      if (from < 3) {
        await migrator.createTable(visions);
      }
      if (from < 4) {
        await migrator.createTable(goals);
        await migrator.createTable(goalKeyResults);
      }
      if (from < 5) {
        await migrator.createTable(diaryEntries);
        await migrator.createTable(diaryTags);
        await migrator.createTable(diaryAttachments);
        await _createDiaryIndexes();
      }
    },
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );

  Future<void> _createDiaryIndexes() {
    return customStatement(
      'CREATE UNIQUE INDEX IF NOT EXISTS diary_entries_active_date_unique '
      'ON diary_entries(local_date) WHERE deleted_at IS NULL',
    );
  }
}
