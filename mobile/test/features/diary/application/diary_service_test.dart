import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/diary/application/diary_service.dart';
import 'package:lifeos/features/diary/domain/diary.dart';
import 'package:lifeos/features/diary/domain/diary_attachment_store.dart';
import 'package:lifeos/features/diary/domain/diary_repository.dart';

void main() {
  late _MemoryDiaryRepository repository;
  late _MemoryAttachmentStore attachmentStore;
  late DiaryService service;

  setUp(() {
    repository = _MemoryDiaryRepository();
    attachmentStore = _MemoryAttachmentStore();
    service = DiaryService(
      repository,
      attachmentStore,
      now: () => DateTime.utc(2026, 7, 31, 8),
    );
  });

  test('creates one daily entry and normalizes duplicate tags', () async {
    await service.save(
      DiaryInput(
        localDate: CalendarDate(2026, 7, 31),
        markdown: '  **今天**完成了第一次记录。  ',
        tags: const [' 成长 ', '生活', '成长'],
        retainedAttachmentIds: const [],
      ),
    );

    final saved = repository.items.single;
    expect(saved.entry.markdown, '**今天**完成了第一次记录。');
    expect(saved.entry.localDate, CalendarDate(2026, 7, 31));
    expect(saved.tags.map((tag) => tag.name), ['成长', '生活']);
    expect(saved.entry.version, 1);
  });

  test('rejects a second active entry on the same date', () async {
    repository.items.add(_aggregate());

    await expectLater(
      service.save(
        DiaryInput(
          localDate: CalendarDate(2026, 7, 31),
          markdown: '另一篇日记',
          tags: const [],
          retainedAttachmentIds: const [],
        ),
      ),
      throwsA(isA<DiaryDateConflictException>()),
    );
  });

  test('promotes staged images and persists their metadata', () async {
    const staged = StagedDiaryImage(
      id: '00000000-0000-4000-8000-000000000031',
      relativePath: 'diary/pending/image.jpg',
      thumbnailRelativePath: 'diary/pending/image_thumbnail.jpg',
      mediaType: 'image/jpeg',
      sizeBytes: 1024,
      width: 1200,
      height: 800,
      checksumSha256:
          'aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa',
    );

    await service.save(
      DiaryInput(
        localDate: CalendarDate(2026, 7, 31),
        markdown: '带图片的日记',
        tags: const [],
        retainedAttachmentIds: const [],
      ),
      stagedImages: const [staged],
    );

    final attachment = repository.items.single.attachments.single;
    expect(attachment.relativePath, 'diary/attachments/image.jpg');
    expect(attachment.position, 0);
    expect(attachmentStore.discarded, contains(staged.id));
  });
}

DiaryAggregate _aggregate() {
  final now = DateTime.utc(2026, 7, 31);
  return DiaryAggregate(
    entry: DiaryEntry(
      id: '00000000-0000-4000-8000-000000000030',
      localDate: CalendarDate(2026, 7, 31),
      markdown: '已有日记',
      createdAt: now,
      updatedAt: now,
      version: 1,
    ),
    tags: const [],
    attachments: const [],
  );
}

final class _MemoryDiaryRepository implements DiaryRepository {
  final List<DiaryAggregate> items = [];

  @override
  Future<DiaryAggregate?> findByDate(CalendarDate date) async {
    return items.where((item) => item.entry.localDate == date).firstOrNull;
  }

  @override
  Future<DiaryAggregate?> findById(String id) async {
    return items.where((item) => item.entry.id == id).firstOrNull;
  }

  @override
  Future<List<DiaryAttachment>> findAttachmentsPendingFileDeletion(
    DateTime deletedBefore,
  ) async => const [];

  @override
  Future<void> markAttachmentFilesDeleted(
    String id,
    DateTime deletedAt,
  ) async {}

  @override
  Future<void> save(DiaryAggregate aggregate) async {
    items.removeWhere((item) => item.entry.id == aggregate.entry.id);
    items.add(aggregate);
  }

  @override
  Future<void> softDelete(String id, DateTime deletedAt) async {
    items.removeWhere((item) => item.entry.id == id);
  }

  @override
  Stream<List<DiaryAggregate>> watchAll() => Stream.value(items);
}

final class _MemoryAttachmentStore implements DiaryAttachmentStore {
  final List<String> discarded = [];

  @override
  Future<void> deleteStagedFilesBefore(DateTime cutoff) async {}

  @override
  Future<void> deleteStoredPaths(
    String relativePath,
    String thumbnailRelativePath,
  ) async {}

  @override
  Future<void> discardStagedImage(StagedDiaryImage image) async {
    discarded.add(image.id);
  }

  @override
  Future<StagedDiaryImage> promoteImage(StagedDiaryImage image) async {
    return StagedDiaryImage(
      id: image.id,
      relativePath: 'diary/attachments/image.jpg',
      thumbnailRelativePath: 'diary/attachments/image_thumbnail.jpg',
      mediaType: image.mediaType,
      sizeBytes: image.sizeBytes,
      width: image.width,
      height: image.height,
      checksumSha256: image.checksumSha256,
    );
  }

  @override
  Future<String> resolveAbsolutePath(String relativePath) async => relativePath;

  @override
  Future<StagedDiaryImage> stageImage(String sourcePath, String id) {
    throw UnimplementedError();
  }
}
