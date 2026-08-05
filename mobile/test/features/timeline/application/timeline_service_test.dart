import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/timeline/application/timeline_service.dart';
import 'package:lifeos/features/timeline/domain/timeline_event.dart';
import 'package:lifeos/features/timeline/domain/timeline_repository.dart';

void main() {
  late _MemoryTimelineRepository repository;
  late TimelineService service;
  final now = DateTime(2026, 8, 5, 10);

  setUp(() {
    repository = _MemoryTimelineRepository();
    service = TimelineService(repository, now: () => now);
  });

  test('creates and normalizes a manual timeline event', () async {
    await service.save(
      TimelineEventInput(
        occurredOn: CalendarDate(2026, 8, 1),
        type: TimelineEventType.milestone,
        title: '  完成 LifeOS 第一版  ',
        description: '  这是一个值得记住的开始。  ',
      ),
    );

    final event = repository.items.single;
    expect(event.title, '完成 LifeOS 第一版');
    expect(event.description, '这是一个值得记住的开始。');
    expect(event.sourceType, TimelineSourceType.manual);
    expect(event.sourceId, isNull);
    expect(event.version, 1);
  });

  test('updates a manual event while preserving its identity', () async {
    final existing = _event(version: 2);
    repository.items.add(existing);

    await service.save(
      TimelineEventInput(
        id: existing.id,
        occurredOn: CalendarDate(2026, 7, 31),
        type: TimelineEventType.turningPoint,
        title: '换了一个新方向',
        description: '',
      ),
    );

    final updated = repository.items.single;
    expect(updated.id, existing.id);
    expect(updated.createdAt, existing.createdAt);
    expect(updated.description, isNull);
    expect(updated.type, TimelineEventType.turningPoint);
    expect(updated.version, 3);
  });

  test('rejects future, empty, and oversized input', () async {
    await expectLater(
      () => service.save(
        TimelineEventInput(
          occurredOn: CalendarDate(2026, 8, 6),
          type: TimelineEventType.memory,
          title: '未来事件',
          description: '',
        ),
      ),
      throwsA(isA<TimelineValidationException>()),
    );
    await expectLater(
      () => service.save(
        TimelineEventInput(
          occurredOn: CalendarDate(2026, 8, 5),
          type: TimelineEventType.memory,
          title: ' ',
          description: '',
        ),
      ),
      throwsA(isA<TimelineValidationException>()),
    );
    await expectLater(
      () => service.save(
        TimelineEventInput(
          occurredOn: CalendarDate(2026, 8, 5),
          type: TimelineEventType.memory,
          title: '内容过长',
          description: List.filled(
            timelineMaximumDescriptionLength + 1,
            'a',
          ).join(),
        ),
      ),
      throwsA(isA<TimelineValidationException>()),
    );
    expect(repository.items, isEmpty);
  });

  test('soft-deletes a manual timeline event', () async {
    final existing = _event();
    repository.items.add(existing);

    await service.delete(existing.id);

    expect(repository.items, isEmpty);
  });

  test('does not manually change a system-sourced event', () async {
    final systemEvent = _event(
      sourceType: TimelineSourceType.goal,
      sourceId: '00000000-0000-4000-8000-000000000599',
    );
    repository.items.add(systemEvent);

    await expectLater(
      () => service.save(
        TimelineEventInput(
          id: systemEvent.id,
          occurredOn: systemEvent.occurredOn,
          type: systemEvent.type,
          title: '尝试改写',
          description: '',
        ),
      ),
      throwsStateError,
    );
    await expectLater(() => service.delete(systemEvent.id), throwsStateError);
    expect(repository.items.single.title, systemEvent.title);
  });
}

TimelineEvent _event({
  int version = 1,
  TimelineSourceType sourceType = TimelineSourceType.manual,
  String? sourceId,
}) {
  return TimelineEvent(
    id: '00000000-0000-4000-8000-000000000501',
    occurredOn: CalendarDate(2026, 8, 1),
    type: TimelineEventType.beginning,
    title: '重新开始跑步',
    description: '从一次轻松跑开始。',
    sourceType: sourceType,
    sourceId: sourceId,
    createdAt: DateTime.utc(2026, 8, 1, 8),
    updatedAt: DateTime.utc(2026, 8, 1, 8),
    version: version,
  );
}

final class _MemoryTimelineRepository implements TimelineRepository {
  final List<TimelineEvent> items = [];

  @override
  Future<TimelineEvent?> findById(String id) async {
    return items.where((event) => event.id == id).firstOrNull;
  }

  @override
  Future<void> save(TimelineEvent event) async {
    items.removeWhere((item) => item.id == event.id);
    items.add(event);
  }

  @override
  Future<void> softDelete(String id, DateTime deletedAt) async {
    items.removeWhere((event) => event.id == id);
  }

  @override
  Stream<List<TimelineEvent>> watchAll() => Stream.value(items);
}
