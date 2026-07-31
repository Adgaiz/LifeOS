import 'package:drift/drift.dart';
import 'package:lifeos/core/database/app_database.dart' as db;
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/goal/domain/goal.dart';
import 'package:lifeos/features/goal/domain/goal_repository.dart';

final class DriftGoalRepository implements GoalRepository {
  const DriftGoalRepository(this._database);

  final db.AppDatabase _database;

  @override
  Stream<List<GoalAggregate>> watchAll() {
    final query = _database.select(_database.goals)
      ..where((table) => table.deletedAt.isNull())
      ..orderBy([(table) => OrderingTerm.desc(table.updatedAt)]);
    return query.watch().asyncMap((rows) async {
      final aggregates = <GoalAggregate>[];
      for (final row in rows) {
        aggregates.add(
          GoalAggregate(
            goal: _goalToDomain(row),
            keyResults: await _findKeyResults(row.id),
          ),
        );
      }
      return List.unmodifiable(aggregates);
    });
  }

  @override
  Future<GoalAggregate?> findById(String id) async {
    final query = _database.select(_database.goals)
      ..where((table) => table.id.equals(id) & table.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    if (row == null) {
      return null;
    }
    return GoalAggregate(
      goal: _goalToDomain(row),
      keyResults: await _findKeyResults(id),
    );
  }

  @override
  Future<void> save(GoalAggregate aggregate) async {
    await _database.transaction(() async {
      await _database
          .into(_database.goals)
          .insertOnConflictUpdate(
            db.GoalsCompanion.insert(
              id: aggregate.goal.id,
              visionId: Value(aggregate.goal.visionId),
              title: aggregate.goal.title,
              description: Value(aggregate.goal.description),
              startDate: aggregate.goal.startDate.toIso8601String(),
              endDate: aggregate.goal.endDate.toIso8601String(),
              status: aggregate.goal.status.name,
              createdAt: aggregate.goal.createdAt,
              updatedAt: aggregate.goal.updatedAt,
              version: Value(aggregate.goal.version),
            ),
          );

      final existingRows =
          await (_database.select(_database.goalKeyResults)..where(
                (table) =>
                    table.goalId.equals(aggregate.goal.id) &
                    table.deletedAt.isNull(),
              ))
              .get();
      final retainedIds = aggregate.keyResults
          .map((keyResult) => keyResult.id)
          .toSet();
      for (final keyResult in aggregate.keyResults) {
        await _database
            .into(_database.goalKeyResults)
            .insertOnConflictUpdate(
              db.GoalKeyResultsCompanion.insert(
                id: keyResult.id,
                goalId: keyResult.goalId,
                title: keyResult.title,
                progress: Value(keyResult.progress),
                position: Value(keyResult.position),
                createdAt: keyResult.createdAt,
                updatedAt: keyResult.updatedAt,
                version: Value(keyResult.version),
              ),
            );
      }
      for (final removed in existingRows.where(
        (row) => !retainedIds.contains(row.id),
      )) {
        final timestamp = aggregate.goal.updatedAt.millisecondsSinceEpoch;
        await _database.customUpdate(
          'UPDATE goal_key_results '
          'SET deleted_at = ?, updated_at = ?, version = version + 1 '
          'WHERE id = ? AND deleted_at IS NULL',
          variables: [
            Variable<int>(timestamp),
            Variable<int>(timestamp),
            Variable<String>(removed.id),
          ],
          updates: {_database.goalKeyResults},
        );
      }
    });
  }

  @override
  Future<void> updateStatus(
    String id,
    GoalStatus status,
    DateTime updatedAt,
  ) async {
    final affected = await _database.customUpdate(
      'UPDATE goals '
      'SET status = ?, updated_at = ?, version = version + 1 '
      'WHERE id = ? AND deleted_at IS NULL',
      variables: [
        Variable<String>(status.name),
        Variable<int>(updatedAt.millisecondsSinceEpoch),
        Variable<String>(id),
      ],
      updates: {_database.goals},
    );
    if (affected != 1) {
      throw StateError('Goal not found: $id');
    }
  }

  @override
  Future<void> updateKeyResultProgress(
    String keyResultId,
    int progress,
    DateTime updatedAt,
  ) async {
    await _database.transaction(() async {
      final timestamp = updatedAt.millisecondsSinceEpoch;
      final affected = await _database.customUpdate(
        'UPDATE goal_key_results '
        'SET progress = ?, updated_at = ?, version = version + 1 '
        'WHERE id = ? AND deleted_at IS NULL',
        variables: [
          Variable<int>(progress),
          Variable<int>(timestamp),
          Variable<String>(keyResultId),
        ],
        updates: {_database.goalKeyResults},
      );
      if (affected != 1) {
        throw StateError('Goal key result not found: $keyResultId');
      }
      final parentAffected = await _database.customUpdate(
        'UPDATE goals '
        'SET updated_at = ?, version = version + 1 '
        'WHERE id = (SELECT goal_id FROM goal_key_results WHERE id = ?) '
        'AND deleted_at IS NULL',
        variables: [Variable<int>(timestamp), Variable<String>(keyResultId)],
        updates: {_database.goals},
      );
      if (parentAffected != 1) {
        throw StateError('Goal not found for key result: $keyResultId');
      }
    });
  }

  @override
  Future<void> softDelete(String id, DateTime deletedAt) async {
    await _database.transaction(() async {
      final timestamp = deletedAt.millisecondsSinceEpoch;
      final affected = await _database.customUpdate(
        'UPDATE goals '
        'SET deleted_at = ?, updated_at = ?, version = version + 1 '
        'WHERE id = ? AND deleted_at IS NULL',
        variables: [
          Variable<int>(timestamp),
          Variable<int>(timestamp),
          Variable<String>(id),
        ],
        updates: {_database.goals},
      );
      if (affected != 1) {
        throw StateError('Goal not found: $id');
      }
      await _database.customUpdate(
        'UPDATE goal_key_results '
        'SET deleted_at = ?, updated_at = ?, version = version + 1 '
        'WHERE goal_id = ? AND deleted_at IS NULL',
        variables: [
          Variable<int>(timestamp),
          Variable<int>(timestamp),
          Variable<String>(id),
        ],
        updates: {_database.goalKeyResults},
      );
    });
  }

  Future<List<GoalKeyResult>> _findKeyResults(String goalId) async {
    final query = _database.select(_database.goalKeyResults)
      ..where((table) => table.goalId.equals(goalId) & table.deletedAt.isNull())
      ..orderBy([(table) => OrderingTerm.asc(table.position)]);
    final rows = await query.get();
    return rows.map(_keyResultToDomain).toList(growable: false);
  }

  Goal _goalToDomain(db.GoalRow row) {
    return Goal(
      id: row.id,
      visionId: row.visionId,
      title: row.title,
      description: row.description,
      startDate: CalendarDate.parse(row.startDate),
      endDate: CalendarDate.parse(row.endDate),
      status: GoalStatus.fromStorage(row.status),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      version: row.version,
    );
  }

  GoalKeyResult _keyResultToDomain(db.GoalKeyResultRow row) {
    return GoalKeyResult(
      id: row.id,
      goalId: row.goalId,
      title: row.title,
      progress: row.progress,
      position: row.position,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      version: row.version,
    );
  }
}
