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

  test('creates schema version five and stores metadata', () async {
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

    expect(database.schemaVersion, 5);
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
    final businessTables = await database.customSelect(
      '''SELECT name FROM sqlite_master WHERE type = 'table'
             AND name IN (
               'daily_records', 'daily_actions', 'visions',
               'goals', 'goal_key_results', 'diary_entries',
               'diary_tags', 'diary_attachments'
             )
             ORDER BY name''',
    ).get();

    expect(metadata.metadataValue, '1');
    expect(businessTables.map((row) => row.read<String>('name')), [
      'daily_actions',
      'daily_records',
      'diary_attachments',
      'diary_entries',
      'diary_tags',
      'goal_key_results',
      'goals',
      'visions',
    ]);
  });

  test('migrates schema version two by adding visions', () async {
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
            ..execute('PRAGMA user_version = 2');
        },
      ),
    );

    final table = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name = 'visions'",
        )
        .getSingle();

    expect(table.read<String>('name'), 'visions');
  });

  test('migrates schema version three by adding goals', () async {
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
            ..execute('PRAGMA user_version = 3');
        },
      ),
    );

    final tables = await database.customSelect(
      '''SELECT name FROM sqlite_master WHERE type = 'table'
             AND name IN ('goals', 'goal_key_results')
             ORDER BY name''',
    ).get();

    expect(tables.map((row) => row.read<String>('name')), [
      'goal_key_results',
      'goals',
    ]);
  });

  test(
    'migrates schema version four by adding diary tables and index',
    () async {
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
              ..execute('PRAGMA user_version = 4');
          },
        ),
      );

      final tables = await database.customSelect(
        '''SELECT name FROM sqlite_master WHERE type = 'table'
             AND name IN ('diary_entries', 'diary_tags', 'diary_attachments')
             ORDER BY name''',
      ).get();
      final index = await database
          .customSelect(
            "SELECT name FROM sqlite_master WHERE type = 'index' "
            "AND name = 'diary_entries_active_date_unique'",
          )
          .getSingle();

      expect(tables.map((row) => row.read<String>('name')), [
        'diary_attachments',
        'diary_entries',
        'diary_tags',
      ]);
      expect(index.read<String>('name'), 'diary_entries_active_date_unique');
    },
  );
}
