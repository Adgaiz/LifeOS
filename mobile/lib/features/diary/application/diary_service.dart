import 'package:lifeos/features/diary/domain/diary.dart';
import 'package:lifeos/features/diary/domain/diary_attachment_store.dart';
import 'package:lifeos/features/diary/domain/diary_repository.dart';
import 'package:uuid/uuid.dart';

final class DiaryService {
  DiaryService(
    this._repository,
    this._attachmentStore, {
    Uuid? uuid,
    DateTime Function()? now,
  }) : _uuid = uuid ?? const Uuid(),
       _now = now ?? DateTime.now;

  static const attachmentDeletionGracePeriod = Duration(days: 7);
  static const stagedImageLifetime = Duration(days: 1);

  final DiaryRepository _repository;
  final DiaryAttachmentStore _attachmentStore;
  final Uuid _uuid;
  final DateTime Function() _now;

  Future<StagedDiaryImage> stageImage(String sourcePath) {
    return _attachmentStore.stageImage(sourcePath, _uuid.v4());
  }

  Future<void> discardStagedImage(StagedDiaryImage image) {
    return _attachmentStore.discardStagedImage(image);
  }

  Future<void> save(
    DiaryInput input, {
    List<StagedDiaryImage> stagedImages = const [],
  }) async {
    final normalized = input.validateAndNormalize();
    final existing = input.id == null
        ? null
        : await _repository.findById(input.id!);
    if (input.id != null && existing == null) {
      throw StateError('Diary entry not found: ${input.id}');
    }
    final dateEntry = await _repository.findByDate(input.localDate);
    if (dateEntry != null && dateEntry.entry.id != input.id) {
      throw DiaryDateConflictException(input.localDate);
    }

    final existingAttachments = {
      for (final attachment in existing?.attachments ?? <DiaryAttachment>[])
        attachment.id: attachment,
    };
    final retainedIds = <String>[];
    for (final id in input.retainedAttachmentIds) {
      if (!retainedIds.contains(id)) {
        retainedIds.add(id);
      }
    }
    if (retainedIds.any((id) => !existingAttachments.containsKey(id))) {
      throw const DiaryValidationException('日记包含无效的图片附件');
    }
    if (retainedIds.length + stagedImages.length > diaryMaximumAttachments) {
      throw const DiaryValidationException('每篇日记最多添加 9 张图片');
    }

    final now = _now().toUtc();
    final diaryId = existing?.entry.id ?? _uuid.v4();
    final existingTags = {
      for (final tag in existing?.tags ?? <DiaryTag>[]) tag.normalizedName: tag,
    };
    final tags = <DiaryTag>[];
    for (var index = 0; index < normalized.tags.length; index++) {
      final value = normalized.tags[index];
      final previous = existingTags[value.normalizedName];
      tags.add(
        DiaryTag(
          id: previous?.id ?? _uuid.v4(),
          diaryId: diaryId,
          name: value.name,
          normalizedName: value.normalizedName,
          position: index,
          createdAt: previous?.createdAt ?? now,
          updatedAt: now,
          version: (previous?.version ?? 0) + 1,
        ),
      );
    }

    final promoted = <StagedDiaryImage>[];
    var databaseSaved = false;
    try {
      for (final staged in stagedImages) {
        promoted.add(await _attachmentStore.promoteImage(staged));
      }
      final attachments = <DiaryAttachment>[];
      for (final id in retainedIds) {
        final previous = existingAttachments[id]!;
        attachments.add(
          DiaryAttachment(
            id: previous.id,
            diaryId: diaryId,
            relativePath: previous.relativePath,
            thumbnailRelativePath: previous.thumbnailRelativePath,
            mediaType: previous.mediaType,
            sizeBytes: previous.sizeBytes,
            width: previous.width,
            height: previous.height,
            checksumSha256: previous.checksumSha256,
            position: attachments.length,
            createdAt: previous.createdAt,
            updatedAt: now,
            version: previous.version + 1,
          ),
        );
      }
      for (final image in promoted) {
        attachments.add(
          DiaryAttachment(
            id: image.id,
            diaryId: diaryId,
            relativePath: image.relativePath,
            thumbnailRelativePath: image.thumbnailRelativePath,
            mediaType: image.mediaType,
            sizeBytes: image.sizeBytes,
            width: image.width,
            height: image.height,
            checksumSha256: image.checksumSha256,
            position: attachments.length,
            createdAt: now,
            updatedAt: now,
            version: 1,
          ),
        );
      }
      await _repository.save(
        DiaryAggregate(
          entry: DiaryEntry(
            id: diaryId,
            localDate: input.localDate,
            markdown: normalized.markdown,
            createdAt: existing?.entry.createdAt ?? now,
            updatedAt: now,
            version: (existing?.entry.version ?? 0) + 1,
          ),
          tags: tags,
          attachments: attachments,
        ),
      );
      databaseSaved = true;
    } finally {
      if (databaseSaved) {
        for (final staged in stagedImages) {
          await _ignoreFailure(
            () => _attachmentStore.discardStagedImage(staged),
          );
        }
      } else {
        for (final image in promoted) {
          await _ignoreFailure(
            () => _attachmentStore.deleteStoredPaths(
              image.relativePath,
              image.thumbnailRelativePath,
            ),
          );
        }
      }
    }
  }

  Future<void> delete(String id) {
    return _repository.softDelete(id, _now().toUtc());
  }

  Future<String> resolveAbsolutePath(String relativePath) {
    return _attachmentStore.resolveAbsolutePath(relativePath);
  }

  Future<void> runMaintenance() async {
    final now = _now().toUtc();
    await _attachmentStore.deleteStagedFilesBefore(
      now.subtract(stagedImageLifetime),
    );
    final attachments = await _repository.findAttachmentsPendingFileDeletion(
      now.subtract(attachmentDeletionGracePeriod),
    );
    for (final attachment in attachments) {
      try {
        await _attachmentStore.deleteStoredPaths(
          attachment.relativePath,
          attachment.thumbnailRelativePath,
        );
        await _repository.markAttachmentFilesDeleted(attachment.id, now);
      } catch (_) {
        // Keep the metadata pending so a later maintenance run can retry.
      }
    }
  }

  Future<void> _ignoreFailure(Future<void> Function() operation) async {
    try {
      await operation();
    } catch (_) {
      // Stale staging files are removed by the next maintenance run.
    }
  }
}
