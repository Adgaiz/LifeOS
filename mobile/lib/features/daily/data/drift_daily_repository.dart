import 'package:drift/drift.dart';
import 'package:lifeos/core/database/app_database.dart' as db;
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/daily/domain/daily_record.dart';
import 'package:lifeos/features/daily/domain/daily_repository.dart';

final class DriftDailyRepository implements DailyRepository {
  const DriftDailyRepository(this._database);

  final db.AppDatabase _database;

  @override
  Stream<DailyRecord?> watchByDate(CalendarDate date, String timezone) {
    final query = _database.select(_database.dailyRecords)
      ..where(
        (table) =>
            table.localDate.equals(date.toIso8601String()) &
            table.timezone.equals(timezone) &
            table.deletedAt.isNull(),
      );
    return query.watchSingleOrNull().map(_toDomainOrNull);
  }

  @override
  Future<DailyRecord?> findByDate(CalendarDate date, String timezone) async {
    final query = _database.select(_database.dailyRecords)
      ..where(
        (table) =>
            table.localDate.equals(date.toIso8601String()) &
            table.timezone.equals(timezone) &
            table.deletedAt.isNull(),
      );
    return _toDomainOrNull(await query.getSingleOrNull());
  }

  @override
  Future<void> save(DailyRecord record) async {
    await _database
        .into(_database.dailyRecords)
        .insertOnConflictUpdate(
          db.DailyRecordsCompanion.insert(
            id: record.id,
            localDate: record.localDate.toIso8601String(),
            timezone: record.timezone,
            sleepMinutes: Value(record.sleepMinutes),
            mood: Value(record.mood?.value),
            energy: Value(record.energy?.value),
            weightGrams: Value(record.weightGrams),
            exerciseMinutes: Value(record.exerciseMinutes),
            createdAt: record.createdAt,
            updatedAt: record.updatedAt,
            version: Value(record.version),
          ),
        );
  }

  DailyRecord? _toDomainOrNull(db.DailyRecordRow? row) {
    if (row == null) {
      return null;
    }
    return DailyRecord(
      id: row.id,
      localDate: CalendarDate.parse(row.localDate),
      timezone: row.timezone,
      sleepMinutes: row.sleepMinutes,
      mood: row.mood == null ? null : MoodLevel.fromValue(row.mood!),
      energy: row.energy == null ? null : EnergyLevel.fromValue(row.energy!),
      weightGrams: row.weightGrams,
      exerciseMinutes: row.exerciseMinutes,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      version: row.version,
    );
  }
}
