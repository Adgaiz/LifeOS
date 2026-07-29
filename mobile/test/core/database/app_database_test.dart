import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/database/app_database.dart';

void main() {
  late AppDatabase database;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
  });

  tearDown(() async {
    await database.close();
  });

  test('creates schema version two and stores metadata', () async {
    final updatedAt = DateTime.utc(2026, 7, 29);
    await database
        .into(database.appMetadata)
        .insert(
          AppMetadataCompanion.insert(
            metadataKey: 'schema_baseline',
            metadataValue: '1',
            updatedAt: updatedAt,
          ),
        );

    final record = await database.select(database.appMetadata).getSingle();

    expect(database.schemaVersion, 2);
    expect(record.metadataKey, 'schema_baseline');
    expect(record.metadataValue, '1');
    expect(record.updatedAt, updatedAt);
  });

  test('migrates schema version one without losing metadata', () async {
    await database.close();
    database = AppDatabase.forTesting(
      NativeDatabase.memory(
        setup: (sqlite) {
          sqlite
            ..execute('''
              CREATE TABLE app_metadata (
                metadata_key TEXT NOT NULL PRIMARY KEY,
                metadata_value TEXT NOT NULL,
                updated_at INTEGER NOT NULL
              )
            ''')
            ..execute(
              "INSERT INTO app_metadata VALUES ('schema_baseline', '1', 0)",
            )
            ..execute('PRAGMA user_version = 1');
        },
      ),
    );

    final metadata = await database.select(database.appMetadata).getSingle();
    final dailyTables = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name IN ('daily_records', 'daily_actions') ORDER BY name",
        )
        .get();

    expect(metadata.metadataValue, '1');
    expect(dailyTables.map((row) => row.read<String>('name')), [
      'daily_actions',
      'daily_records',
    ]);
  });
}
