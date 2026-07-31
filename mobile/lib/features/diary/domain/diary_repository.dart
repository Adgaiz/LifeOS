import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/diary/domain/diary.dart';

abstract interface class DiaryRepository {
  Stream<List<DiaryAggregate>> watchAll();

  Future<DiaryAggregate?> findById(String id);

  Future<DiaryAggregate?> findByDate(CalendarDate date);

  Future<void> save(DiaryAggregate aggregate);

  Future<void> softDelete(String id, DateTime deletedAt);

  Future<List<DiaryAttachment>> findAttachmentsPendingFileDeletion(
    DateTime deletedBefore,
  );

  Future<void> markAttachmentFilesDeleted(String id, DateTime deletedAt);
}
