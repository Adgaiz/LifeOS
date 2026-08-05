import 'package:lifeos/features/daily/domain/calendar_date.dart';

const timelineMaximumTitleLength = 80;
const timelineMaximumDescriptionLength = 2000;

enum TimelineEventType {
  beginning('新的开始'),
  milestone('里程碑'),
  turningPoint('重要转折'),
  memory('珍贵记忆');

  const TimelineEventType(this.label);

  final String label;

  static TimelineEventType fromStorage(String value) {
    return values.firstWhere(
      (type) => type.name == value,
      orElse: () => throw ArgumentError.value(
        value,
        'value',
        'Invalid timeline event type',
      ),
    );
  }
}

enum TimelineSourceType {
  manual,
  vision,
  goal,
  daily,
  diary,
  aiReview;

  static TimelineSourceType fromStorage(String value) {
    return values.firstWhere(
      (type) => type.name == value,
      orElse: () => throw ArgumentError.value(
        value,
        'value',
        'Invalid timeline source type',
      ),
    );
  }
}

final class TimelineEvent {
  const TimelineEvent({
    required this.id,
    required this.occurredOn,
    required this.type,
    required this.title,
    required this.description,
    required this.sourceType,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    this.sourceId,
  });

  final String id;
  final CalendarDate occurredOn;
  final TimelineEventType type;
  final String title;
  final String? description;
  final TimelineSourceType sourceType;
  final String? sourceId;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  bool get isManual => sourceType == TimelineSourceType.manual;
}

final class TimelineEventInput {
  const TimelineEventInput({
    required this.occurredOn,
    required this.type,
    required this.title,
    required this.description,
    this.id,
  });

  final String? id;
  final CalendarDate occurredOn;
  final TimelineEventType type;
  final String title;
  final String description;

  ({String title, String? description}) validateAndNormalize() {
    final normalizedTitle = title.trim();
    final normalizedDescription = description.trim();
    if (normalizedTitle.isEmpty ||
        normalizedTitle.length > timelineMaximumTitleLength) {
      throw const TimelineValidationException('事件标题需要 1 到 80 个字符');
    }
    if (normalizedDescription.length > timelineMaximumDescriptionLength) {
      throw const TimelineValidationException('事件说明最多 2000 个字符');
    }
    return (
      title: normalizedTitle,
      description: normalizedDescription.isEmpty ? null : normalizedDescription,
    );
  }
}

final class TimelineValidationException implements Exception {
  const TimelineValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
