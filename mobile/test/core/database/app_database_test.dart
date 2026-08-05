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

  test('creates schema version nine and stores metadata', () async {
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

    expect(database.schemaVersion, 9);
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
               'diary_tags', 'diary_attachments', 'ai_daily_reviews',
               'ai_friend_exchanges', 'timeline_events',
               'ai_periodic_reports'
             )
             ORDER BY name''',
    ).get();

    expect(metadata.metadataValue, '1');
    expect(businessTables.map((row) => row.read<String>('name')), [
      'ai_daily_reviews',
      'ai_friend_exchanges',
      'ai_periodic_reports',
      'daily_actions',
      'daily_records',
      'diary_attachments',
      'diary_entries',
      'diary_tags',
      'goal_key_results',
      'goals',
      'timeline_events',
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

  test('migrates schema version five by adding AI daily reviews', () async {
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
            ..execute('PRAGMA user_version = 5');
        },
      ),
    );

    final table = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name = 'ai_daily_reviews'",
        )
        .getSingle();
    final index = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND name = 'ai_daily_reviews_date_created_index'",
        )
        .getSingle();

    expect(table.read<String>('name'), 'ai_daily_reviews');
    expect(index.read<String>('name'), 'ai_daily_reviews_date_created_index');
  });

  test('migrates schema version six by adding AI Friend exchanges', () async {
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
            ..execute('PRAGMA user_version = 6');
        },
      ),
    );

    final table = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name = 'ai_friend_exchanges'",
        )
        .getSingle();
    final index = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND name = 'ai_friend_exchanges_created_index'",
        )
        .getSingle();

    expect(table.read<String>('name'), 'ai_friend_exchanges');
    expect(index.read<String>('name'), 'ai_friend_exchanges_created_index');
  });

  test('migrates schema version seven by adding Timeline indexes', () async {
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
            ..execute('PRAGMA user_version = 7');
        },
      ),
    );

    final table = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name = 'timeline_events'",
        )
        .getSingle();
    final indexes = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND name LIKE 'timeline_events_%' ORDER BY name",
        )
        .get();

    expect(table.read<String>('name'), 'timeline_events');
    expect(indexes.map((row) => row.read<String>('name')), [
      'timeline_events_occurred_index',
      'timeline_events_system_source_unique',
    ]);
  });

  test('migrates schema version eight by adding AI periodic reports', () async {
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
            ..execute('PRAGMA user_version = 8');
        },
      ),
    );

    final table = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'table' "
          "AND name = 'ai_periodic_reports'",
        )
        .getSingle();
    final index = await database
        .customSelect(
          "SELECT name FROM sqlite_master WHERE type = 'index' "
          "AND name = 'ai_periodic_reports_period_index'",
        )
        .getSingle();

    expect(table.read<String>('name'), 'ai_periodic_reports');
    expect(index.read<String>('name'), 'ai_periodic_reports_period_index');
  });
}
