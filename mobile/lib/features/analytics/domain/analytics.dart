import 'package:lifeos/features/action/domain/daily_action.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/daily/domain/daily_record.dart';

enum AnalyticsPeriod {
  sevenDays(7, '近 7 天'),
  thirtyDays(30, '近 30 天');

  const AnalyticsPeriod(this.dayCount, this.label);

  final int dayCount;
  final String label;
}

final class AnalyticsGoalSource {
  const AnalyticsGoalSource({
    required this.id,
    required this.keyResultProgress,
  });

  final String id;
  final List<int> keyResultProgress;

  double get progress {
    if (keyResultProgress.isEmpty) return 0;
    return keyResultProgress.reduce((sum, value) => sum + value) /
        keyResultProgress.length;
  }
}

final class AnalyticsSourceData {
  const AnalyticsSourceData({
    required this.dailyRecords,
    required this.actions,
    required this.activeGoals,
  });

  final List<DailyRecord> dailyRecords;
  final List<DailyAction> actions;
  final List<AnalyticsGoalSource> activeGoals;
}

final class AnalyticsDay {
  const AnalyticsDay({
    required this.date,
    required this.actionCount,
    required this.completedActionCount,
    this.sleepMinutes,
    this.mood,
    this.energy,
    this.weightGrams,
    this.exerciseMinutes,
  });

  final CalendarDate date;
  final int? sleepMinutes;
  final double? mood;
  final double? energy;
  final int? weightGrams;
  final int? exerciseMinutes;
  final int actionCount;
  final int completedActionCount;
}

final class AnalyticsReport {
  const AnalyticsReport({
    required this.period,
    required this.startDate,
    required this.endDate,
    required this.days,
    required this.recordDays,
    required this.actionCount,
    required this.completedActionCount,
    required this.partialActionCount,
    required this.exerciseDays,
    required this.totalExerciseMinutes,
    required this.activeGoalCount,
    this.averageSleepMinutes,
    this.averageMood,
    this.averageEnergy,
    this.latestWeightGrams,
    this.weightChangeGrams,
    this.activeGoalAverageProgress,
  });

  final AnalyticsPeriod period;
  final CalendarDate startDate;
  final CalendarDate endDate;
  final List<AnalyticsDay> days;
  final int recordDays;
  final int actionCount;
  final int completedActionCount;
  final int partialActionCount;
  final int exerciseDays;
  final int totalExerciseMinutes;
  final int activeGoalCount;
  final double? averageSleepMinutes;
  final double? averageMood;
  final double? averageEnergy;
  final int? latestWeightGrams;
  final int? weightChangeGrams;
  final double? activeGoalAverageProgress;

  double get checkInRate => recordDays / period.dayCount * 100;

  double? get actionCompletionRate =>
      actionCount == 0 ? null : completedActionCount / actionCount * 100;

  bool get hasPeriodData => recordDays > 0 || actionCount > 0;
}
