import 'package:lifeos/features/daily/domain/calendar_date.dart';

const diaryMaximumMarkdownLength = 50000;
const diaryMaximumTags = 10;
const diaryMaximumTagLength = 20;
const diaryMaximumAttachments = 9;

final class DiaryEntry {
  const DiaryEntry({
    required this.id,
    required this.localDate,
    required this.markdown,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  final String id;
  final CalendarDate localDate;
  final String markdown;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
}

final class DiaryTag {
  const DiaryTag({
    required this.id,
    required this.diaryId,
    required this.name,
    required this.normalizedName,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  final String id;
  final String diaryId;
  final String name;
  final String normalizedName;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
}

final class DiaryAttachment {
  const DiaryAttachment({
    required this.id,
    required this.diaryId,
    required this.relativePath,
    required this.thumbnailRelativePath,
    required this.mediaType,
    required this.sizeBytes,
    required this.width,
    required this.height,
    required this.checksumSha256,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    this.deletedAt,
    this.filesDeletedAt,
  });

  final String id;
  final String diaryId;
  final String relativePath;
  final String thumbnailRelativePath;
  final String mediaType;
  final int sizeBytes;
  final int width;
  final int height;
  final String checksumSha256;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
  final DateTime? deletedAt;
  final DateTime? filesDeletedAt;
}

final class DiaryAggregate {
  const DiaryAggregate({
    required this.entry,
    required this.tags,
    required this.attachments,
  });

  final DiaryEntry entry;
  final List<DiaryTag> tags;
  final List<DiaryAttachment> attachments;
}

final class DiaryInput {
  const DiaryInput({
    required this.localDate,
    required this.markdown,
    required this.tags,
    required this.retainedAttachmentIds,
    this.id,
  });

  final String? id;
  final CalendarDate localDate;
  final String markdown;
  final List<String> tags;
  final List<String> retainedAttachmentIds;

  ({String markdown, List<({String name, String normalizedName})> tags})
  validateAndNormalize() {
    final normalizedMarkdown = markdown.trim();
    if (normalizedMarkdown.isEmpty ||
        normalizedMarkdown.length > diaryMaximumMarkdownLength) {
      throw const DiaryValidationException('日记正文需要 1 到 50000 个字符');
    }
    if (tags.length > diaryMaximumTags) {
      throw const DiaryValidationException('每篇日记最多添加 10 个标签');
    }
    final normalizedTags = <({String name, String normalizedName})>[];
    final seen = <String>{};
    for (final tag in tags) {
      final name = tag.trim();
      if (name.isEmpty || name.length > diaryMaximumTagLength) {
        throw const DiaryValidationException('标签需要 1 到 20 个字符');
      }
      final normalizedName = name.toLowerCase();
      if (seen.add(normalizedName)) {
        normalizedTags.add((name: name, normalizedName: normalizedName));
      }
    }
    return (markdown: normalizedMarkdown, tags: normalizedTags);
  }
}

final class StagedDiaryImage {
  const StagedDiaryImage({
    required this.id,
    required this.relativePath,
    required this.thumbnailRelativePath,
    required this.mediaType,
    required this.sizeBytes,
    required this.width,
    required this.height,
    required this.checksumSha256,
  });

  final String id;
  final String relativePath;
  final String thumbnailRelativePath;
  final String mediaType;
  final int sizeBytes;
  final int width;
  final int height;
  final String checksumSha256;
}

final class DiaryValidationException implements Exception {
  const DiaryValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}

final class DiaryDateConflictException implements Exception {
  const DiaryDateConflictException(this.date);

  final CalendarDate date;

  @override
  String toString() => '这一天已经有一篇日记';
}

final class DiaryImageException implements Exception {
  const DiaryImageException(this.message);

  final String message;

  @override
  String toString() => message;
}
