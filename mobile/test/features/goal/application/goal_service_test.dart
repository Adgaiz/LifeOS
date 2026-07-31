import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/goal/application/goal_service.dart';
import 'package:lifeos/features/goal/domain/goal.dart';
import 'package:lifeos/features/goal/domain/goal_repository.dart';

void main() {
  late _MemoryGoalRepository repository;
  late GoalService service;

  setUp(() {
    repository = _MemoryGoalRepository();
    service = GoalService(repository, now: () => DateTime.utc(2026, 7, 31, 8));
  });

  test('creates a 90 day goal and averages key result progress', () async {
    final start = CalendarDate(2026, 7, 31);
    await service.save(
      GoalInput(
        visionId: '00000000-0000-4000-8000-000000000021',
        title: '  恢复健康状态  ',
        startDate: start,
        endDate: start.addDays(89),
        keyResults: const [
          GoalKeyResultInput(title: '每周运动 3 次', progress: 20),
          GoalKeyResultInput(title: '晚上 23:30 前睡觉', progress: 40),
        ],
      ),
    );

    final aggregate = repository.aggregate!;
    expect(aggregate.goal.title, '恢复健康状态');
    expect(aggregate.goal.durationInDays, 90);
    expect(aggregate.goal.status, GoalStatus.active);
    expect(aggregate.progress, 30);
    expect(aggregate.keyResults, hasLength(2));
  });

  test('updates a key result progress within zero to one hundred', () async {
    final aggregate = _aggregate();
    repository.aggregate = aggregate;

    await service.updateKeyResultProgress(aggregate.keyResults.single.id, 73);

    expect(repository.progress, 73);
  });

  test('rejects a goal without key results', () {
    expect(
      () => service.save(
        GoalInput(
          title: '没有关键结果',
          startDate: CalendarDate(2026, 7, 31),
          endDate: CalendarDate(2026, 10, 28),
          keyResults: const [],
        ),
      ),
      throwsA(isA<GoalValidationException>()),
    );
  });
}

GoalAggregate _aggregate() {
  final now = DateTime.utc(2026, 7, 31);
  const goalId = '00000000-0000-4000-8000-000000000022';
  return GoalAggregate(
    goal: Goal(
      id: goalId,
      title: '学习 AI',
      startDate: CalendarDate(2026, 7, 31),
      endDate: CalendarDate(2026, 10, 28),
      status: GoalStatus.active,
      createdAt: now,
      updatedAt: now,
      version: 1,
    ),
    keyResults: [
      GoalKeyResult(
        id: '00000000-0000-4000-8000-000000000023',
        goalId: goalId,
        title: '完成一门课程',
        progress: 10,
        position: 0,
        createdAt: now,
        updatedAt: now,
        version: 1,
      ),
    ],
  );
}

final class _MemoryGoalRepository implements GoalRepository {
  GoalAggregate? aggregate;
  int? progress;

  @override
  Future<GoalAggregate?> findById(String id) async => aggregate;

  @override
  Future<void> save(GoalAggregate value) async => aggregate = value;

  @override
  Future<void> softDelete(String id, DateTime deletedAt) async {
    aggregate = null;
  }

  @override
  Future<void> updateKeyResultProgress(
    String keyResultId,
    int value,
    DateTime updatedAt,
  ) async {
    progress = value;
  }

  @override
  Future<void> updateStatus(
    String id,
    GoalStatus status,
    DateTime updatedAt,
  ) async {}

  @override
  Stream<List<GoalAggregate>> watchAll() {
    return Stream.value([?aggregate]);
  }
}
