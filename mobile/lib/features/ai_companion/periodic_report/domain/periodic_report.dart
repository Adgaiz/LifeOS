import 'package:lifeos/features/ai/domain/ai_provider.dart';
import 'package:lifeos/features/analytics/domain/analytics.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';

const periodicReportPromptVersion = 1;

enum PeriodicReportContextType {
  wellbeing('状态趋势'),
  health('健康趋势'),
  actions('行动完成'),
  goals('目标进度');

  const PeriodicReportContextType(this.label);

  final String label;

  static PeriodicReportContextType fromStorage(String value) {
    return values.firstWhere(
      (type) => type.name == value,
      orElse: () => throw ArgumentError.value(
        value,
        'value',
        'Invalid periodic report context type',
      ),
    );
  }
}

final class PeriodicReportContext {
  const PeriodicReportContext(this.analytics);

  final AnalyticsReport analytics;

  Set<PeriodicReportContextType> get availableTypes => {
    if (analytics.averageSleepMinutes != null ||
        analytics.averageMood != null ||
        analytics.averageEnergy != null)
      PeriodicReportContextType.wellbeing,
    if (analytics.latestWeightGrams != null ||
        analytics.days.any((day) => day.exerciseMinutes != null))
      PeriodicReportContextType.health,
    if (analytics.actionCount > 0) PeriodicReportContextType.actions,
    if (analytics.activeGoalCount > 0) PeriodicReportContextType.goals,
  };
}

final class PeriodicReportSelection {
  PeriodicReportSelection(Set<PeriodicReportContextType> includedTypes)
    : includedTypes = Set.unmodifiable(includedTypes);

  final Set<PeriodicReportContextType> includedTypes;

  void validate(PeriodicReportContext context) {
    if (includedTypes.isEmpty) {
      throw const PeriodicReportException('请至少选择一类本次发送的聚合指标');
    }
    if (!context.availableTypes.containsAll(includedTypes)) {
      throw const PeriodicReportException('选择的统计数据已经变化，请刷新后重试');
    }
  }
}

final class AiPeriodicReport {
  AiPeriodicReport({
    required this.id,
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.content,
    required this.provider,
    required this.model,
    required Set<PeriodicReportContextType> contextTypes,
    required this.promptVersion,
    required this.createdAt,
    required this.version,
    this.requestId,
    this.inputTokens,
    this.outputTokens,
  }) : contextTypes = Set.unmodifiable(contextTypes);

  final String id;
  final AnalyticsPeriod period;
  final CalendarDate startDate;
  final CalendarDate endDate;
  final String content;
  final AiProviderType provider;
  final String model;
  final Set<PeriodicReportContextType> contextTypes;
  final int promptVersion;
  final String? requestId;
  final int? inputTokens;
  final int? outputTokens;
  final DateTime createdAt;
  final int version;
}

final class PeriodicReportPageData {
  const PeriodicReportPageData({required this.context, this.latestReport});

  final PeriodicReportContext context;
  final AiPeriodicReport? latestReport;
}

final class PeriodicReportException implements Exception {
  const PeriodicReportException(this.message);

  final String message;

  @override
  String toString() => message;
}
