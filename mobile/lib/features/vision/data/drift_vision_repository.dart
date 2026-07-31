import 'package:drift/drift.dart';
import 'package:lifeos/core/database/app_database.dart' as db;
import 'package:lifeos/features/vision/domain/vision.dart';
import 'package:lifeos/features/vision/domain/vision_repository.dart';

final class DriftVisionRepository implements VisionRepository {
  const DriftVisionRepository(this._database);

  final db.AppDatabase _database;

  @override
  Stream<List<Vision>> watchAll() {
    final query = _database.select(_database.visions)
      ..where((table) => table.deletedAt.isNull())
      ..orderBy([
        (table) => OrderingTerm.asc(table.status),
        (table) => OrderingTerm.desc(table.updatedAt),
      ]);
    return query.watch().map(
      (rows) => rows.map(_toDomain).toList(growable: false),
    );
  }

  @override
  Future<Vision?> findById(String id) async {
    final query = _database.select(_database.visions)
      ..where((table) => table.id.equals(id) & table.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    return row == null ? null : _toDomain(row);
  }

  @override
  Future<void> save(Vision vision) async {
    await _database
        .into(_database.visions)
        .insertOnConflictUpdate(
          db.VisionsCompanion.insert(
            id: vision.id,
            title: vision.title,
            content: vision.content,
            status: vision.status.name,
            createdAt: vision.createdAt,
            updatedAt: vision.updatedAt,
            version: Value(vision.version),
          ),
        );
  }

  @override
  Future<void> updateStatus(
    String id,
    VisionStatus status,
    DateTime updatedAt,
  ) async {
    final affected = await _database.customUpdate(
      'UPDATE visions '
      'SET status = ?, updated_at = ?, version = version + 1 '
      'WHERE id = ? AND deleted_at IS NULL',
      variables: [
        Variable<String>(status.name),
        Variable<int>(updatedAt.toUtc().millisecondsSinceEpoch),
        Variable<String>(id),
      ],
      updates: {_database.visions},
    );
    if (affected != 1) {
      throw StateError('Vision not found: $id');
    }
  }

  @override
  Future<void> softDelete(String id, DateTime deletedAt) async {
    final timestamp = deletedAt.toUtc().millisecondsSinceEpoch;
    final affected = await _database.customUpdate(
      'UPDATE visions '
      'SET deleted_at = ?, updated_at = ?, version = version + 1 '
      'WHERE id = ? AND deleted_at IS NULL',
      variables: [
        Variable<int>(timestamp),
        Variable<int>(timestamp),
        Variable<String>(id),
      ],
      updates: {_database.visions},
    );
    if (affected != 1) {
      throw StateError('Vision not found: $id');
    }
  }

  Vision _toDomain(db.VisionRow row) {
    return Vision(
      id: row.id,
      title: row.title,
      content: row.content,
      status: VisionStatus.fromStorage(row.status),
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      version: row.version,
    );
  }
}
