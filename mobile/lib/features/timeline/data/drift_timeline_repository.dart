import 'package:drift/drift.dart';
import 'package:lifeos/core/database/app_database.dart' as db;
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/timeline/domain/timeline_event.dart';
import 'package:lifeos/features/timeline/domain/timeline_repository.dart';

final class DriftTimelineRepository implements TimelineRepository {
  const DriftTimelineRepository(this._database);

  final db.AppDatabase _database;

  @override
  Stream<List<TimelineEvent>> watchAll() {
    final query = _database.select(_database.timelineEvents)
      ..where((table) => table.deletedAt.isNull())
      ..orderBy([
        (table) => OrderingTerm.desc(table.occurredOn),
        (table) => OrderingTerm.desc(table.createdAt),
      ]);
    return query.watch().map(
      (rows) => rows.map(_toDomain).toList(growable: false),
    );
  }

  @override
  Future<TimelineEvent?> findById(String id) async {
    final query = _database.select(_database.timelineEvents)
      ..where((table) => table.id.equals(id) & table.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> save(TimelineEvent event) async {
    await _database
        .into(_database.timelineEvents)
        .insertOnConflictUpdate(
          db.TimelineEventsCompanion.insert(
            id: event.id,
            occurredOn: event.occurredOn.toIso8601String(),
            eventType: event.type.name,
            title: event.title,
            description: Value(event.description),
            sourceType: event.sourceType.name,
            sourceId: Value(event.sourceId),
            createdAt: event.createdAt,
            updatedAt: event.updatedAt,
            version: Value(event.version),
          ),
        );
  }

  @override
  Future<void> softDelete(String id, DateTime deletedAt) async {
    final timestamp = deletedAt.toUtc().millisecondsSinceEpoch;
    final affected = await _database.customUpdate(
      'UPDATE timeline_events '
      'SET deleted_at = ?, updated_at = ?, version = version + 1 '
      'WHERE id = ? AND deleted_at IS NULL',
      variables: [
        Variable<int>(timestamp),
        Variable<int>(timestamp),
        Variable<String>(id),
      ],
      updates: {_database.timelineEvents},
    );
    if (affected != 1) {
      throw StateError('Timeline event not found: $id');
    }
  }

  TimelineEvent _toDomain(db.TimelineEventRow row) {
    return TimelineEvent(
      id: row.id,
      occurredOn: CalendarDate.parse(row.occurredOn),
      type: TimelineEventType.fromStorage(row.eventType),
      title: row.title,
      description: row.description,
      sourceType: TimelineSourceType.fromStorage(row.sourceType),
      sourceId: row.sourceId,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      version: row.version,
    );
  }
}
