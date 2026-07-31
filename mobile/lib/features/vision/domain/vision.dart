enum VisionStatus {
  active('进行中'),
  archived('已归档');

  const VisionStatus(this.label);

  final String label;

  static VisionStatus fromStorage(String value) => values.firstWhere(
    (status) => status.name == value,
    orElse: () =>
        throw ArgumentError.value(value, 'value', 'Invalid vision status'),
  );
}

final class Vision {
  const Vision({
    required this.id,
    required this.title,
    required this.content,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  final String id;
  final String title;
  final String content;
  final VisionStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
}

final class VisionInput {
  const VisionInput({required this.title, required this.content, this.id});

  final String? id;
  final String title;
  final String content;

  ({String title, String content}) validateAndNormalize() {
    final normalizedTitle = title.trim();
    final normalizedContent = content.trim();
    if (normalizedTitle.isEmpty || normalizedTitle.length > 80) {
      throw const VisionValidationException('愿景标题需要 1 到 80 个字符');
    }
    if (normalizedContent.isEmpty || normalizedContent.length > 5000) {
      throw const VisionValidationException('愿景内容需要 1 到 5000 个字符');
    }
    return (title: normalizedTitle, content: normalizedContent);
  }
}

final class VisionValidationException implements Exception {
  const VisionValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
