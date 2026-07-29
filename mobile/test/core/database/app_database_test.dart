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

  test('creates schema version one and stores metadata', () async {
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

    expect(database.schemaVersion, 1);
    expect(record.metadataKey, 'schema_baseline');
    expect(record.metadataValue, '1');
    expect(record.updatedAt, updatedAt);
  });
}
