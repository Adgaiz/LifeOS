import 'package:drift/drift.dart';
import 'package:lifeos/core/database/app_database.dart' as db;
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/diary/domain/diary.dart';
import 'package:lifeos/features/diary/domain/diary_repository.dart';

final class DriftDiaryRepository implements DiaryRepository {
  const DriftDiaryRepository(this._database);

  final db.AppDatabase _database;

  @override
  Stream<List<DiaryAggregate>> watchAll() {
    final query = _database.select(_database.diaryEntries)
      ..where((table) => table.deletedAt.isNull())
      ..orderBy([
        (table) => OrderingTerm.desc(table.localDate),
        (table) => OrderingTerm.desc(table.updatedAt),
      ]);
    return query.watch().asyncMap((rows) async {
      final entries = <DiaryAggregate>[];
      for (final row in rows) {
        entries.add(await _aggregate(row));
      }
      return List.unmodifiable(entries);
    });
  }

  @override
  Future<DiaryAggregate?> findById(String id) async {
    final query = _database.select(_database.diaryEntries)
      ..where((table) => table.id.equals(id) & table.deletedAt.isNull());
    final row = await query.getSingleOrNull();
    return row == null ? null : _aggregate(row);
  }

  @override
  Future<DiaryAggregate?> findByDate(CalendarDate date) async {
    final query = _database.select(_database.diaryEntries)
      ..where(
        (table) =>
            table.localDate.equals(date.toIso8601String()) &
            table.deletedAt.isNull(),
      );
    final row = await query.getSingleOrNull();
    return row == null ? null : _aggregate(row);
  }

  @override
  Future<void> save(DiaryAggregate aggregate) async {
    await _database.transaction(() async {
      final conflicting =
          await (_database.select(_database.diaryEntries)..where(
                (table) =>
                    table.localDate.equals(
                      aggregate.entry.localDate.toIso8601String(),
                    ) &
                    table.id.equals(aggregate.entry.id).not() &
                    table.deletedAt.isNull(),
              ))
              .getSingleOrNull();
      if (conflicting != null) {
        throw DiaryDateConflictException(aggregate.entry.localDate);
      }
      await _database
          .into(_database.diaryEntries)
          .insertOnConflictUpdate(
            db.DiaryEntriesCompanion.insert(
              id: aggregate.entry.id,
              localDate: aggregate.entry.localDate.toIso8601String(),
              markdown: aggregate.entry.markdown,
              createdAt: aggregate.entry.createdAt,
              updatedAt: aggregate.entry.updatedAt,
              version: Value(aggregate.entry.version),
            ),
          );
      await _saveTags(aggregate);
      await _saveAttachments(aggregate);
    });
  }

  Future<void> _saveTags(DiaryAggregate aggregate) async {
    final currentRows =
        await (_database.select(_database.diaryTags)..where(
              (table) =>
                  table.diaryId.equals(aggregate.entry.id) &
                  table.deletedAt.isNull(),
            ))
            .get();
    final retainedIds = aggregate.tags.map((tag) => tag.id).toSet();
    for (final tag in aggregate.tags) {
      await _database
          .into(_database.diaryTags)
          .insertOnConflictUpdate(
            db.DiaryTagsCompanion.insert(
              id: tag.id,
              diaryId: tag.diaryId,
              name: tag.name,
              normalizedName: tag.normalizedName,
              position: Value(tag.position),
              createdAt: tag.createdAt,
              updatedAt: tag.updatedAt,
              version: Value(tag.version),
            ),
          );
    }
    for (final removed in currentRows.where(
      (row) => !retainedIds.contains(row.id),
    )) {
      await _softDeleteOwnedRow(
        table: 'diary_tags',
        id: removed.id,
        deletedAt: aggregate.entry.updatedAt,
        updates: {_database.diaryTags},
      );
    }
  }

  Future<void> _saveAttachments(DiaryAggregate aggregate) async {
    final currentRows =
        await (_database.select(_database.diaryAttachments)..where(
              (table) =>
                  table.diaryId.equals(aggregate.entry.id) &
                  table.deletedAt.isNull(),
            ))
            .get();
    final retainedIds = aggregate.attachments
        .map((attachment) => attachment.id)
        .toSet();
    for (final attachment in aggregate.attachments) {
      await _database
          .into(_database.diaryAttachments)
          .insertOnConflictUpdate(
            db.DiaryAttachmentsCompanion.insert(
              id: attachment.id,
              diaryId: attachment.diaryId,
              relativePath: attachment.relativePath,
              thumbnailRelativePath: attachment.thumbnailRelativePath,
              mediaType: attachment.mediaType,
              sizeBytes: attachment.sizeBytes,
              width: attachment.width,
              height: attachment.height,
              checksumSha256: attachment.checksumSha256,
              position: Value(attachment.position),
              createdAt: attachment.createdAt,
              updatedAt: attachment.updatedAt,
              version: Value(attachment.version),
            ),
          );
    }
    for (final removed in currentRows.where(
      (row) => !retainedIds.contains(row.id),
    )) {
      await _softDeleteOwnedRow(
        table: 'diary_attachments',
        id: removed.id,
        deletedAt: aggregate.entry.updatedAt,
        updates: {_database.diaryAttachments},
      );
    }
  }

  Future<void> _softDeleteOwnedRow({
    required String table,
    required String id,
    required DateTime deletedAt,
    required Set<ResultSetImplementation> updates,
  }) async {
    final timestamp = deletedAt.millisecondsSinceEpoch;
    await _database.customUpdate(
      'UPDATE $table '
      'SET deleted_at = ?, updated_at = ?, version = version + 1 '
      'WHERE id = ? AND deleted_at IS NULL',
      variables: [
        Variable<int>(timestamp),
        Variable<int>(timestamp),
        Variable<String>(id),
      ],
      updates: updates,
    );
  }

  @override
  Future<void> softDelete(String id, DateTime deletedAt) async {
    await _database.transaction(() async {
      final timestamp = deletedAt.millisecondsSinceEpoch;
      final affected = await _database.customUpdate(
        'UPDATE diary_entries '
        'SET deleted_at = ?, updated_at = ?, version = version + 1 '
        'WHERE id = ? AND deleted_at IS NULL',
        variables: [
          Variable<int>(timestamp),
          Variable<int>(timestamp),
          Variable<String>(id),
        ],
        updates: {_database.diaryEntries},
      );
      if (affected != 1) {
        throw StateError('Diary entry not found: $id');
      }
      await _database.customUpdate(
        'UPDATE diary_tags '
        'SET deleted_at = ?, updated_at = ?, version = version + 1 '
        'WHERE diary_id = ? AND deleted_at IS NULL',
        variables: [
          Variable<int>(timestamp),
          Variable<int>(timestamp),
          Variable<String>(id),
        ],
        updates: {_database.diaryTags},
      );
      await _database.customUpdate(
        'UPDATE diary_attachments '
        'SET deleted_at = ?, updated_at = ?, version = version + 1 '
        'WHERE diary_id = ? AND deleted_at IS NULL',
        variables: [
          Variable<int>(timestamp),
          Variable<int>(timestamp),
          Variable<String>(id),
        ],
        updates: {_database.diaryAttachments},
      );
    });
  }

  @override
  Future<List<DiaryAttachment>> findAttachmentsPendingFileDeletion(
    DateTime deletedBefore,
  ) async {
    final query = _database.select(_database.diaryAttachments)
      ..where(
        (table) =>
            table.deletedAt.isNotNull() &
            table.deletedAt.isSmallerOrEqualValue(
              deletedBefore.millisecondsSinceEpoch,
            ) &
            table.filesDeletedAt.isNull(),
      );
    final rows = await query.get();
    return rows.map(_attachmentToDomain).toList(growable: false);
  }

  @override
  Future<void> markAttachmentFilesDeleted(String id, DateTime deletedAt) async {
    final timestamp = deletedAt.millisecondsSinceEpoch;
    final affected = await _database.customUpdate(
      'UPDATE diary_attachments '
      'SET files_deleted_at = ?, updated_at = ?, version = version + 1 '
      'WHERE id = ? AND deleted_at IS NOT NULL AND files_deleted_at IS NULL',
      variables: [
        Variable<int>(timestamp),
        Variable<int>(timestamp),
        Variable<String>(id),
      ],
      updates: {_database.diaryAttachments},
    );
    if (affected != 1) {
      throw StateError('Diary attachment not found: $id');
    }
  }

  Future<DiaryAggregate> _aggregate(db.DiaryEntryRow row) async {
    return DiaryAggregate(
      entry: _entryToDomain(row),
      tags: await _findTags(row.id),
      attachments: await _findAttachments(row.id),
    );
  }

  Future<List<DiaryTag>> _findTags(String diaryId) async {
    final query = _database.select(_database.diaryTags)
      ..where(
        (table) => table.diaryId.equals(diaryId) & table.deletedAt.isNull(),
      )
      ..orderBy([(table) => OrderingTerm.asc(table.position)]);
    return (await query.get()).map(_tagToDomain).toList(growable: false);
  }

  Future<List<DiaryAttachment>> _findAttachments(String diaryId) async {
    final query = _database.select(_database.diaryAttachments)
      ..where(
        (table) => table.diaryId.equals(diaryId) & table.deletedAt.isNull(),
      )
      ..orderBy([(table) => OrderingTerm.asc(table.position)]);
    return (await query.get()).map(_attachmentToDomain).toList(growable: false);
  }

  DiaryEntry _entryToDomain(db.DiaryEntryRow row) {
    return DiaryEntry(
      id: row.id,
      localDate: CalendarDate.parse(row.localDate),
      markdown: row.markdown,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      version: row.version,
    );
  }

  DiaryTag _tagToDomain(db.DiaryTagRow row) {
    return DiaryTag(
      id: row.id,
      diaryId: row.diaryId,
      name: row.name,
      normalizedName: row.normalizedName,
      position: row.position,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      version: row.version,
    );
  }

  DiaryAttachment _attachmentToDomain(db.DiaryAttachmentRow row) {
    return DiaryAttachment(
      id: row.id,
      diaryId: row.diaryId,
      relativePath: row.relativePath,
      thumbnailRelativePath: row.thumbnailRelativePath,
      mediaType: row.mediaType,
      sizeBytes: row.sizeBytes,
      width: row.width,
      height: row.height,
      checksumSha256: row.checksumSha256,
      position: row.position,
      createdAt: row.createdAt,
      updatedAt: row.updatedAt,
      version: row.version,
      deletedAt: row.deletedAt,
      filesDeletedAt: row.filesDeletedAt,
    );
  }
}
