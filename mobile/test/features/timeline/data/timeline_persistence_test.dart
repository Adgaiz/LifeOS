import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/database/app_database.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/timeline/data/drift_timeline_repository.dart';
import 'package:lifeos/features/timeline/domain/timeline_event.dart';

void main() {
  late AppDatabase database;
  late DriftTimelineRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftTimelineRepository(database);
  });

  tearDown(() => database.close());

  test('persists timeline events ordered by occurrence date', () async {
    await repository.save(
      _event(
        id: '00000000-0000-4000-8000-000000000511',
        occurredOn: CalendarDate(2026, 7, 1),
        title: '七月节点',
      ),
    );
    await repository.save(
      _event(
        id: '00000000-0000-4000-8000-000000000512',
        occurredOn: CalendarDate(2026, 8, 1),
        title: '八月节点',
      ),
    );

    final events = await repository.watchAll().first;

    expect(events.map((event) => event.title), ['八月节点', '七月节点']);
    expect(events.first.sourceType, TimelineSourceType.manual);
    expect(events.first.type, TimelineEventType.milestone);
  });

  test('updates and soft-deletes a timeline event', () async {
    final original = _event(
      id: '00000000-0000-4000-8000-000000000513',
      occurredOn: CalendarDate(2026, 8, 1),
      title: '原始标题',
    );
    await repository.save(original);
    await repository.save(
      TimelineEvent(
        id: original.id,
        occurredOn: original.occurredOn,
        type: TimelineEventType.turningPoint,
        title: '更新标题',
        description: null,
        sourceType: original.sourceType,
        createdAt: original.createdAt,
        updatedAt: original.updatedAt.add(const Duration(minutes: 1)),
        version: 2,
      ),
    );

    final updated = await repository.findById(original.id);
    expect(updated?.title, '更新标题');
    expect(updated?.version, 2);

    await repository.softDelete(
      original.id,
      original.updatedAt.add(const Duration(minutes: 2)),
    );
    expect(await repository.findById(original.id), isNull);
    expect(await repository.watchAll().first, isEmpty);
  });
}

TimelineEvent _event({
  required String id,
  required CalendarDate occurredOn,
  required String title,
}) {
  final now = DateTime.utc(2026, 8, 5, 8);
  return TimelineEvent(
    id: id,
    occurredOn: occurredOn,
    type: TimelineEventType.milestone,
    title: title,
    description: '值得记住。',
    sourceType: TimelineSourceType.manual,
    createdAt: now,
    updatedAt: now,
    version: 1,
  );
}
