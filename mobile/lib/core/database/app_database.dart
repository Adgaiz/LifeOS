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

@DriftDatabase(tables: [AppMetadata])
final class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(driftDatabase(name: 'lifeos'));

  AppDatabase.forTesting(super.e);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (migrator) => migrator.createAll(),
    beforeOpen: (details) async {
      await customStatement('PRAGMA foreign_keys = ON');
    },
  );
}
