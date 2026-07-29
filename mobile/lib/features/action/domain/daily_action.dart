import 'package:lifeos/features/daily/domain/calendar_date.dart';

enum ActionCategory {
  health('健康'),
  study('学习'),
  work('工作'),
  life('生活'),
  relationship('关系');

  const ActionCategory(this.label);

  final String label;

  static ActionCategory fromStorage(String value) => values.firstWhere(
    (category) => category.name == value,
    orElse: () =>
        throw ArgumentError.value(value, 'value', 'Invalid action category'),
  );
}

enum ActionStatus {
  pending('未完成'),
  partial('部分完成'),
  completed('已完成');

  const ActionStatus(this.label);

  final String label;

  static ActionStatus fromStorage(String value) => values.firstWhere(
    (status) => status.name == value,
    orElse: () =>
        throw ArgumentError.value(value, 'value', 'Invalid action status'),
  );
}

final class DailyAction {
  const DailyAction({
    required this.id,
    required this.localDate,
    required this.title,
    required this.category,
    required this.status,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    this.goalId,
    this.minimumAction,
  });

  final String id;
  final CalendarDate localDate;
  final String? goalId;
  final String title;
  final String? minimumAction;
  final ActionCategory category;
  final ActionStatus status;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
}

final class ActionValidationException implements Exception {
  const ActionValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
