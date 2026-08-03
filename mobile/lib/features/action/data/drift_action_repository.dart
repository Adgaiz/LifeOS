import 'package:drift/drift.dart';
import 'package:lifeos/core/database/app_database.dart' as db;
import 'package:lifeos/features/action/domain/action_repository.dart';
import 'package:lifeos/features/action/domain/daily_action.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';

final class DriftActionRepository implements ActionRepository {
  const DriftActionRepository(this._database);

  final db.AppDatabase _database;

  @override
  Future<List<DailyAction>> findByDate(CalendarDate date) async {
    final query = _database.select(_database.dailyActions)
      ..where(
        (table) =>
            table.localDate.equals(date.toIso8601String()) &
            table.deletedAt.isNull(),
      )
      ..orderBy([
        (table) => OrderingTerm.asc(table.position),
        (table) => OrderingTerm.asc(table.createdAt),
      ]);
    return (await query.get()).map(_toDomain).toList(growable: false);
  }

  @override
  Stream<List<DailyAction>> watchByDate(CalendarDate date) {
    final query = _database.select(_database.dailyActions)
      ..where(
        (table) =>
            table.localDate.equals(date.toIso8601String()) &
            table.deletedAt.isNull(),
      )
      ..orderBy([
        (table) => OrderingTerm.asc(table.position),
        (table) => OrderingTerm.asc(table.createdAt),
      ]);
    return query.watch().map(
      (rows) => rows.map(_toDomain).toList(growable: false),
    );
  }

  @override
  Future<void> add(DailyAction action) async {
    await _database
        .into(_database.dailyActions)
        .insert(
          db.DailyActionsCompanion.insert(
            id: action.id,
            localDate: action.localDate.toIso8601String(),
            goalId: Value(action.goalId),
            title: action.title,
            minimumAction: Value(action.minimumAction),
            category: action.category.name,
            status: action.status.name,
            position: Value(action.position),
            createdAt: action.createdAt,
            updatedAt: action.updatedAt,
            version: Value(action.version),
          ),
        );
  }

  @override
  Future<void> updateStatus(
    String id,
    ActionStatus status,
    DateTime updatedAt,
  ) async {
    final affected = await _database.customUpdate(
      'UPDATE daily_actions '
      'SET status = ?, updated_at = ?, version = version + 1 '
      'WHERE id = ? AND deleted_at IS NULL',
      variables: [
        Variable<String>(status.name),
        Variable<int>(updatedAt.toUtc().millisecondsSinceEpoch),
        Variable<String>(id),
      ],
      updates: {_database.dailyActions},
    );
    if (affected != 1) {
      throw StateError('Daily action not found: $id');
    }
  }

  @override
  Future<void> softDelete(String id, DateTime deletedAt) async {
    final timestamp = deletedAt.toUtc().millisecondsSinceEpoch;
    final affected = await _database.customUpdate(
      'UPDATE daily_actions '
      'SET deleted_at = ?, updated_at = ?, version = version + 1 '
      'WHERE id = ? AND deleted_at IS NULL',
      variables: [
        Variable<int>(timestamp),
        Variable<int>(timestamp),
        Variable<String>(id),
      ],
      updates: {_database.dailyActions},
    );
    if (affected != 1) {
      throw StateError('Daily action not found: $id');
    }
  }

  DailyAction _toDomain(db.DailyActionRow row) {
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
