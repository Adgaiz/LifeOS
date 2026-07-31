import 'package:lifeos/features/daily/domain/calendar_date.dart';

enum GoalStatus {
  active('进行中'),
  completed('已完成'),
  archived('已归档');

  const GoalStatus(this.label);

  final String label;

  static GoalStatus fromStorage(String value) => values.firstWhere(
    (status) => status.name == value,
    orElse: () =>
        throw ArgumentError.value(value, 'value', 'Invalid goal status'),
  );
}

final class Goal {
  const Goal({
    required this.id,
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
    this.visionId,
    this.description,
  });

  final String id;
  final String? visionId;
  final String title;
  final String? description;
  final CalendarDate startDate;
  final CalendarDate endDate;
  final GoalStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;

  int get durationInDays => startDate.daysUntil(endDate) + 1;
}

final class GoalKeyResult {
  const GoalKeyResult({
    required this.id,
    required this.goalId,
    required this.title,
    required this.progress,
    required this.position,
    required this.createdAt,
    required this.updatedAt,
    required this.version,
  });

  final String id;
  final String goalId;
  final String title;
  final int progress;
  final int position;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int version;
}

final class GoalAggregate {
  const GoalAggregate({required this.goal, required this.keyResults});

  final Goal goal;
  final List<GoalKeyResult> keyResults;

  double get progress {
    if (keyResults.isEmpty) {
      return 0;
    }
    final total = keyResults.fold<int>(
      0,
      (sum, keyResult) => sum + keyResult.progress,
    );
    return total / keyResults.length;
  }
}

final class GoalKeyResultInput {
  const GoalKeyResultInput({required this.title, this.id, this.progress = 0});

  final String? id;
  final String title;
  final int progress;
}

final class GoalInput {
  const GoalInput({
    required this.title,
    required this.startDate,
    required this.endDate,
    required this.keyResults,
    this.id,
    this.visionId,
    this.description,
  });

  final String? id;
  final String? visionId;
  final String title;
  final String? description;
  final CalendarDate startDate;
  final CalendarDate endDate;
  final List<GoalKeyResultInput> keyResults;

  ({String title, String? description, List<GoalKeyResultInput> keyResults})
  validateAndNormalize() {
    final normalizedTitle = title.trim();
    final normalizedDescription = description?.trim();
    if (normalizedTitle.isEmpty || normalizedTitle.length > 80) {
      throw const GoalValidationException('目标标题需要 1 到 80 个字符');
    }
    if (normalizedDescription != null && normalizedDescription.length > 2000) {
      throw const GoalValidationException('目标说明不能超过 2000 个字符');
    }
    if (endDate.compareTo(startDate) < 0) {
      throw const GoalValidationException('结束日期不能早于开始日期');
    }
    if (keyResults.isEmpty) {
      throw const GoalValidationException('请至少添加一个关键结果');
    }
    final normalizedKeyResults = <GoalKeyResultInput>[];
    for (final keyResult in keyResults) {
      final normalizedKeyResultTitle = keyResult.title.trim();
      if (normalizedKeyResultTitle.isEmpty ||
          normalizedKeyResultTitle.length > 120) {
        throw const GoalValidationException('关键结果需要 1 到 120 个字符');
      }
      if (keyResult.progress < 0 || keyResult.progress > 100) {
        throw const GoalValidationException('关键结果进度需要在 0 到 100 之间');
      }
      normalizedKeyResults.add(
        GoalKeyResultInput(
          id: keyResult.id,
          title: normalizedKeyResultTitle,
          progress: keyResult.progress,
        ),
      );
    }
    return (
      title: normalizedTitle,
      description: normalizedDescription?.isEmpty ?? true
          ? null
          : normalizedDescription,
      keyResults: normalizedKeyResults,
    );
  }
}

final class GoalValidationException implements Exception {
  const GoalValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
