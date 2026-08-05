import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/database/app_database.dart';
import 'package:lifeos/features/action/data/drift_action_repository.dart';
import 'package:lifeos/features/action/domain/daily_action.dart';
import 'package:lifeos/features/analytics/data/drift_analytics_repository.dart';
import 'package:lifeos/features/daily/data/drift_daily_repository.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/daily/domain/daily_record.dart';
import 'package:lifeos/features/goal/data/drift_goal_repository.dart';
import 'package:lifeos/features/goal/domain/goal.dart';

void main() {
  late AppDatabase database;
  late DriftAnalyticsRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftAnalyticsRepository(database);
  });

  tearDown(() => database.close());

  test('loads only active records in the requested local date range', () async {
    final dailyRepository = DriftDailyRepository(database);
    final actionRepository = DriftActionRepository(database);
    final goalRepository = DriftGoalRepository(database);
    await dailyRepository.save(
      _daily('00000000-0000-4000-8000-000000000621', CalendarDate(2026, 8, 2)),
    );
    await dailyRepository.save(
      _daily('00000000-0000-4000-8000-000000000622', CalendarDate(2026, 7, 1)),
    );
    await actionRepository.add(_action('00000000-0000-4000-8000-000000000623'));
    await goalRepository.save(_goal(GoalStatus.active));
    await goalRepository.save(_goal(GoalStatus.archived, suffix: '2'));

    final source = await repository.load(
      CalendarDate(2026, 8, 1),
      CalendarDate(2026, 8, 5),
    );

    expect(source.dailyRecords.single.localDate, CalendarDate(2026, 8, 2));
    expect(source.actions.single.status, ActionStatus.completed);
    expect(source.activeGoals, hasLength(1));
    expect(source.activeGoals.single.progress, 50);
  });
}

DailyRecord _daily(String id, CalendarDate date) {
  final now = DateTime.utc(2026, 8, 2, 8);
  return DailyRecord(
    id: id,
    localDate: date,
    timezone: 'UTC+08:00',
    sleepMinutes: 480,
    mood: MoodLevel.good,
    energy: EnergyLevel.steady,
    weightGrams: 70000,
    exerciseMinutes: 30,
    createdAt: now,
    updatedAt: now,
    version: 1,
  );
}

DailyAction _action(String id) {
  final now = DateTime.utc(2026, 8, 2, 8);
  return DailyAction(
    id: id,
    localDate: CalendarDate(2026, 8, 2),
    title: '散步',
    category: ActionCategory.health,
    status: ActionStatus.completed,
    position: 0,
    createdAt: now,
    updatedAt: now,
    version: 1,
  );
}

GoalAggregate _goal(GoalStatus status, {String suffix = '1'}) {
  final now = DateTime.utc(2026, 8, 2, 8);
  final goalId = '00000000-0000-4000-8000-00000000063$suffix';
  return GoalAggregate(
    goal: Goal(
      id: goalId,
      title: '目标 $suffix',
      startDate: CalendarDate(2026, 8, 1),
      endDate: CalendarDate(2026, 10, 29),
      status: status,
      createdAt: now,
      updatedAt: now,
      version: 1,
    ),
    keyResults: [
      GoalKeyResult(
        id: '00000000-0000-4000-8000-00000000064$suffix',
        goalId: goalId,
        title: '关键结果',
        progress: 50,
        position: 0,
        createdAt: now,
        updatedAt: now,
        version: 1,
      ),
    ],
  );
}
