import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/database/app_database.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/goal/data/drift_goal_repository.dart';
import 'package:lifeos/features/goal/domain/goal.dart';

void main() {
  late AppDatabase database;
  late DriftGoalRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftGoalRepository(database);
  });

  tearDown(() => database.close());

  test('persists progress, status and soft deletion atomically', () async {
    final now = DateTime.utc(2026, 7, 31, 8);
    const goalId = '00000000-0000-4000-8000-000000000024';
    const keyResultId = '00000000-0000-4000-8000-000000000025';
    await repository.save(
      GoalAggregate(
        goal: Goal(
          id: goalId,
          title: '恢复健康状态',
          startDate: CalendarDate(2026, 7, 31),
          endDate: CalendarDate(2026, 10, 28),
          status: GoalStatus.active,
          createdAt: now,
          updatedAt: now,
          version: 1,
        ),
        keyResults: [
          GoalKeyResult(
            id: keyResultId,
            goalId: goalId,
            title: '每周运动 3 次',
            progress: 10,
            position: 0,
            createdAt: now,
            updatedAt: now,
            version: 1,
          ),
        ],
      ),
    );

    await repository.updateKeyResultProgress(keyResultId, 65, now);
    var aggregate = await repository.findById(goalId);
    expect(aggregate?.keyResults.single.progress, 65);
    expect(aggregate?.keyResults.single.version, 2);
    expect(aggregate?.goal.version, 2);

    await repository.updateStatus(goalId, GoalStatus.completed, now);
    aggregate = await repository.findById(goalId);
    expect(aggregate?.goal.status, GoalStatus.completed);

    await repository.softDelete(goalId, now);
    expect(await repository.findById(goalId), isNull);
    expect(await repository.watchAll().first, isEmpty);
  });

  test('rejects out of range progress and rolls back the goal', () async {
    final now = DateTime.utc(2026, 7, 31, 8);
    const goalId = '00000000-0000-4000-8000-000000000026';

    await expectLater(
      repository.save(
        GoalAggregate(
          goal: Goal(
            id: goalId,
            title: '测试存储约束',
            startDate: CalendarDate(2026, 7, 31),
            endDate: CalendarDate(2026, 10, 28),
            status: GoalStatus.active,
            createdAt: now,
            updatedAt: now,
            version: 1,
          ),
          keyResults: [
            GoalKeyResult(
              id: '00000000-0000-4000-8000-000000000027',
              goalId: goalId,
              title: '非法进度不会落库',
              progress: 101,
              position: 0,
              createdAt: now,
              updatedAt: now,
              version: 1,
            ),
          ],
        ),
      ),
      throwsA(anything),
    );
    expect(await repository.findById(goalId), isNull);
  });
}
