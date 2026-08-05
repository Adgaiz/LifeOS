import 'package:drift/drift.dart';
import 'package:lifeos/core/database/app_database.dart' as db;
import 'package:lifeos/features/action/domain/daily_action.dart';
import 'package:lifeos/features/analytics/domain/analytics.dart';
import 'package:lifeos/features/analytics/domain/analytics_repository.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/daily/domain/daily_record.dart';
import 'package:lifeos/features/goal/domain/goal.dart';

final class DriftAnalyticsRepository implements AnalyticsRepository {
  const DriftAnalyticsRepository(this._database);

  final db.AppDatabase _database;

  @override
  Future<AnalyticsSourceData> load(
    CalendarDate startDate,
    CalendarDate endDate,
  ) async {
    final start = startDate.toIso8601String();
    final end = endDate.toIso8601String();
    final dailyQuery = _database.select(_database.dailyRecords)
      ..where(
        (table) =>
            table.localDate.isBetweenValues(start, end) &
            table.deletedAt.isNull(),
      )
      ..orderBy([(table) => OrderingTerm.asc(table.localDate)]);
    final actionQuery = _database.select(_database.dailyActions)
      ..where(
        (table) =>
            table.localDate.isBetweenValues(start, end) &
            table.deletedAt.isNull(),
      )
      ..orderBy([(table) => OrderingTerm.asc(table.localDate)]);
    final goalQuery = _database.select(_database.goals)
      ..where(
        (table) =>
            table.status.equals(GoalStatus.active.name) &
            table.deletedAt.isNull(),
      );

    final dailyRows = await dailyQuery.get();
    final actionRows = await actionQuery.get();
    final goalRows = await goalQuery.get();
    final keyResultRows = goalRows.isEmpty
        ? const <db.GoalKeyResultRow>[]
        : await (_database.select(_database.goalKeyResults)..where(
                (table) =>
                    table.goalId.isIn(goalRows.map((goal) => goal.id)) &
                    table.deletedAt.isNull(),
              ))
              .get();
    final activeGoals = <AnalyticsGoalSource>[];
    for (final goal in goalRows) {
      activeGoals.add(
        AnalyticsGoalSource(
          id: goal.id,
          keyResultProgress: List.unmodifiable(
            keyResultRows
                .where((keyResult) => keyResult.goalId == goal.id)
                .map((keyResult) => keyResult.progress),
          ),
        ),
      );
    }

    return AnalyticsSourceData(
      dailyRecords: dailyRows.map(_dailyToDomain).toList(growable: false),
      actions: actionRows.map(_actionToDomain).toList(growable: false),
      activeGoals: List.unmodifiable(activeGoals),
    );
  }

  DailyRecord _dailyToDomain(db.DailyRecordRow row) {
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

  DailyAction _actionToDomain(db.DailyActionRow row) {
    return DailyAction(
      id: row.id,
      localDate: CalendarDate.parse(row.localDate),
      goalId: row.goalId,
      title: row.title,
      minimumAction: row.minimumAction,
      category: ActionCategory.fromStorage(row.category),
      status: ActionStatus.fromStorage(row.status),
      position: row.position,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      version: row.version,
    );
  }
}
