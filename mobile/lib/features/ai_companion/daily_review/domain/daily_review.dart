import 'package:lifeos/features/action/domain/daily_action.dart';
import 'package:lifeos/features/ai/domain/ai_provider.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/daily/domain/daily_record.dart';
import 'package:lifeos/features/diary/domain/diary.dart';

const dailyReviewPromptVersion = 1;
const dailyReviewDiaryCharacterLimit = 12000;

enum DailyReviewContextType {
  dailyStatus('今日状态'),
  actions('今日任务'),
  diary('今日日记');

  const DailyReviewContextType(this.label);

  final String label;

  static DailyReviewContextType fromStorage(String value) {
    return values.firstWhere(
      (type) => type.name == value,
      orElse: () => throw ArgumentError.value(
        value,
        'value',
        'Invalid daily review context type',
      ),
    );
  }
}

final class DailyReviewContext {
  DailyReviewContext({
    required this.localDate,
    required List<DailyAction> actions,
    this.dailyRecord,
    this.diary,
  }) : actions = List.unmodifiable(actions);

  final CalendarDate localDate;
  final DailyRecord? dailyRecord;
  final List<DailyAction> actions;
  final DiaryAggregate? diary;

  Set<DailyReviewContextType> get availableTypes => {
    if (dailyRecord != null) DailyReviewContextType.dailyStatus,
    if (actions.isNotEmpty) DailyReviewContextType.actions,
    if (diary != null) DailyReviewContextType.diary,
  };
}

final class DailyReviewPageData {
  const DailyReviewPageData({required this.context, this.latestReview});

  final DailyReviewContext context;
  final AiDailyReview? latestReview;
}

final class DailyReviewSelection {
  DailyReviewSelection(Set<DailyReviewContextType> includedTypes)
    : includedTypes = Set.unmodifiable(includedTypes);

  final Set<DailyReviewContextType> includedTypes;

  void validate(DailyReviewContext context) {
    if (includedTypes.isEmpty) {
      throw const DailyReviewException('请至少选择一类本次发送的数据');
    }
    if (!context.availableTypes.containsAll(includedTypes)) {
      throw const DailyReviewException('选择的数据已经发生变化，请刷新后重试');
    }
  }
}

final class AiDailyReview {
  AiDailyReview({
    required this.id,
    required this.localDate,
    required this.content,
    required this.provider,
    required this.model,
    required Set<DailyReviewContextType> contextTypes,
    required this.promptVersion,
    required this.createdAt,
    required this.version,
    this.requestId,
    this.inputTokens,
    this.outputTokens,
  }) : contextTypes = Set.unmodifiable(contextTypes);

  final String id;
  final CalendarDate localDate;
  final String content;
  final AiProviderType provider;
  final String model;
  final Set<DailyReviewContextType> contextTypes;
  final int promptVersion;
  final String? requestId;
  final int? inputTokens;
  final int? outputTokens;
  final DateTime createdAt;
  final int version;
}

final class DailyReviewException implements Exception {
  const DailyReviewException(this.message);

  final String message;

  @override
  String toString() => message;
}
