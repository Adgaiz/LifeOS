import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/database/app_database.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/diary/data/drift_diary_repository.dart';
import 'package:lifeos/features/diary/domain/diary.dart';

void main() {
  late AppDatabase database;
  late DriftDiaryRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftDiaryRepository(database);
  });

  tearDown(() => database.close());

  test(
    'persists tags and attachments then soft-deletes removed files',
    () async {
      final now = DateTime.utc(2026, 7, 31, 8);
      final aggregate = _aggregate(now);
      await repository.save(aggregate);

      var saved = await repository.findByDate(CalendarDate(2026, 7, 31));
      expect(saved?.entry.markdown, '# 今天\n记录人生。');
      expect(saved?.tags.single.name, '成长');
      expect(saved?.attachments.single.width, 1200);

      await repository.save(
        DiaryAggregate(
          entry: DiaryEntry(
            id: aggregate.entry.id,
            localDate: aggregate.entry.localDate,
            markdown: '更新后的日记',
            createdAt: now,
            updatedAt: now.add(const Duration(hours: 1)),
            version: 2,
          ),
          tags: const [],
          attachments: const [],
        ),
      );

      saved = await repository.findById(aggregate.entry.id);
      expect(saved?.tags, isEmpty);
      expect(saved?.attachments, isEmpty);
      final pending = await repository.findAttachmentsPendingFileDeletion(
        now.add(const Duration(days: 8)),
      );
      expect(pending.single.id, aggregate.attachments.single.id);

      await repository.markAttachmentFilesDeleted(
        pending.single.id,
        now.add(const Duration(days: 8)),
      );
      expect(
        await repository.findAttachmentsPendingFileDeletion(
          now.add(const Duration(days: 9)),
        ),
        isEmpty,
      );
    },
  );

  test('allows only one active entry per calendar date', () async {
    final now = DateTime.utc(2026, 7, 31, 8);
    await repository.save(_aggregate(now));
    final second = _aggregate(now, idSuffix: '35');

    await expectLater(
      repository.save(second),
      throwsA(isA<DiaryDateConflictException>()),
    );
    expect(await repository.watchAll().first, hasLength(1));
  });

  test('soft-deletes an entry and its owned data atomically', () async {
    final now = DateTime.utc(2026, 7, 31, 8);
    final aggregate = _aggregate(now);
    await repository.save(aggregate);

    await repository.softDelete(aggregate.entry.id, now);

    expect(await repository.findById(aggregate.entry.id), isNull);
    expect(await repository.watchAll().first, isEmpty);
    expect(
      await repository.findAttachmentsPendingFileDeletion(
        now.add(const Duration(days: 8)),
      ),
      hasLength(1),
    );
  });
}

DiaryAggregate _aggregate(DateTime now, {String idSuffix = '32'}) {
  final diaryId = '00000000-0000-4000-8000-0000000000$idSuffix';
  return DiaryAggregate(
    entry: DiaryEntry(
      id: diaryId,
      localDate: CalendarDate(2026, 7, 31),
      markdown: '# 今天\n记录人生。',
      createdAt: now,
      updatedAt: now,
      version: 1,
    ),
    tags: [
      DiaryTag(
        id: '00000000-0000-4000-8000-000000000033',
        diaryId: diaryId,
        name: '成长',
        normalizedName: '成长',
        position: 0,
        createdAt: now,
        updatedAt: now,
        version: 1,
      ),
    ],
    attachments: [
      DiaryAttachment(
        id: '00000000-0000-4000-8000-000000000034',
        diaryId: diaryId,
        relativePath: 'diary/attachments/photo.jpg',
        thumbnailRelativePath: 'diary/attachments/photo_thumbnail.jpg',
        mediaType: 'image/jpeg',
        sizeBytes: 1024,
        width: 1200,
        height: 800,
        checksumSha256:
            'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
        position: 0,
        createdAt: now,
        updatedAt: now,
        version: 1,
      ),
    ],
  );
}
