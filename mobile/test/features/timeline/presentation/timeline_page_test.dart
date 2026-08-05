import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/timeline/application/timeline_providers.dart';
import 'package:lifeos/features/timeline/domain/timeline_event.dart';
import 'package:lifeos/features/timeline/domain/timeline_repository.dart';
import 'package:lifeos/features/timeline/presentation/timeline_page.dart';

void main() {
  testWidgets('creates the first manual timeline event', (tester) async {
    final repository = _ReactiveTimelineRepository();
    addTearDown(repository.close);

    await tester.pumpWidget(
      ProviderScope(
        overrides: [timelineRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: TimelinePage()),
      ),
    );
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    expect(find.text('人生时间线'), findsOneWidget);
    expect(find.text('从一个重要时刻开始'), findsOneWidget);
    expect(find.text('足迹'), findsOneWidget);

    await tester.tap(find.text('记录第一个节点'));
    await tester.pumpAndSettle();
    final fields = find.byType(TextFormField);
    await tester.enterText(fields.at(0), '完成 LifeOS 时间线 MVP');
    await tester.enterText(fields.at(1), '为过去留下坐标，也更清楚下一步。');
    await tester.tap(find.widgetWithText(FilledButton, '保存'));
    await tester.pumpAndSettle();

    expect(repository.items.single.title, '完成 LifeOS 时间线 MVP');
    expect(repository.items.single.sourceType, TimelineSourceType.manual);
    expect(find.text('完成 LifeOS 时间线 MVP'), findsOneWidget);
    expect(find.text('里程碑'), findsOneWidget);
  });
}

final class _ReactiveTimelineRepository implements TimelineRepository {
  final List<TimelineEvent> items = [];
  final StreamController<List<TimelineEvent>> _changes =
      StreamController.broadcast();

  void close() => _changes.close();

  @override
  Future<TimelineEvent?> findById(String id) async {
    return items.where((event) => event.id == id).firstOrNull;
  }

  @override
  Future<void> save(TimelineEvent event) async {
    items.removeWhere((item) => item.id == event.id);
    items.add(event);
    _changes.add(List.unmodifiable(items));
  }

  @override
  Future<void> softDelete(String id, DateTime deletedAt) async {
    items.removeWhere((event) => event.id == id);
    _changes.add(List.unmodifiable(items));
  }

  @override
  Stream<List<TimelineEvent>> watchAll() async* {
    yield List.unmodifiable(items);
    yield* _changes.stream;
  }
}
