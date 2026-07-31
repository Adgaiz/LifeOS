import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/daily/application/daily_providers.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/goal/application/goal_providers.dart';
import 'package:lifeos/features/goal/domain/goal.dart';
import 'package:lifeos/features/goal/domain/goal_repository.dart';
import 'package:lifeos/features/goal/presentation/goal_page.dart';
import 'package:lifeos/features/vision/application/vision_providers.dart';
import 'package:lifeos/features/vision/domain/vision.dart';
import 'package:lifeos/features/vision/domain/vision_repository.dart';

void main() {
  testWidgets('creates the first goal with the default 90 day period', (
    tester,
  ) async {
    final goalRepository = _ReactiveGoalRepository();
    final visionRepository = _EmptyVisionRepository();
    addTearDown(goalRepository.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentDateTimeProvider.overrideWithValue(DateTime(2026, 7, 31)),
          goalRepositoryProvider.overrideWithValue(goalRepository),
          visionRepositoryProvider.overrideWithValue(visionRepository),
        ],
        child: const MaterialApp(home: GoalPage()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('90 天目标'), findsOneWidget);
    expect(find.text('把方向变成一个阶段'), findsOneWidget);

    await tester.tap(find.text('创建第一个目标'));
    await tester.pumpAndSettle();

    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '建立稳定的运动习惯');
    await tester.enterText(fields.at(2), '每周完成三次力量训练');
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    final saved = goalRepository.items.single;
    expect(saved.goal.title, '建立稳定的运动习惯');
    expect(saved.goal.startDate, CalendarDate(2026, 7, 31));
    expect(saved.goal.endDate, CalendarDate(2026, 10, 28));
    expect(saved.goal.durationInDays, 90);
    expect(saved.keyResults.single.title, '每周完成三次力量训练');
    expect(saved.keyResults.single.progress, 0);
    expect(find.text('建立稳定的运动习惯'), findsOneWidget);
    expect(find.text('0%'), findsOneWidget);
  });
}

final class _ReactiveGoalRepository implements GoalRepository {
  final List<GoalAggregate> items = [];
  final StreamController<List<GoalAggregate>> _changes =
      StreamController.broadcast();

  void close() => _changes.close();

  @override
  Future<GoalAggregate?> findById(String id) async {
    return items.where((item) => item.goal.id == id).firstOrNull;
  }

  @override
  Future<void> save(GoalAggregate aggregate) async {
    items.removeWhere((item) => item.goal.id == aggregate.goal.id);
    items.add(aggregate);
    _changes.add(List.unmodifiable(items));
  }

  @override
  Future<void> softDelete(String id, DateTime deletedAt) async {
    items.removeWhere((item) => item.goal.id == id);
    _changes.add(List.unmodifiable(items));
  }

  @override
  Future<void> updateKeyResultProgress(
    String keyResultId,
    int progress,
    DateTime updatedAt,
  ) async {}

  @override
  Future<void> updateStatus(
    String id,
    GoalStatus status,
    DateTime updatedAt,
  ) async {}

  @override
  Stream<List<GoalAggregate>> watchAll() async* {
    yield List.unmodifiable(items);
    yield* _changes.stream;
  }
}

final class _EmptyVisionRepository implements VisionRepository {
  @override
  Future<Vision?> findById(String id) async => null;

  @override
  Future<void> save(Vision vision) async {}

  @override
  Future<void> softDelete(String id, DateTime deletedAt) async {}

  @override
  Future<void> updateStatus(
    String id,
    VisionStatus status,
    DateTime updatedAt,
  ) async {}

  @override
  Stream<List<Vision>> watchAll() => Stream.value(const []);
}
