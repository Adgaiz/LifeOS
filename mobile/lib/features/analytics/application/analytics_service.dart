import 'package:lifeos/features/action/domain/daily_action.dart';
import 'package:lifeos/features/analytics/domain/analytics.dart';
import 'package:lifeos/features/analytics/domain/analytics_repository.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/daily/domain/daily_record.dart';

final class AnalyticsService {
  AnalyticsService(this._repository, {DateTime Function()? now})
    : _now = now ?? DateTime.now;

  final AnalyticsRepository _repository;
  final DateTime Function() _now;

  Future<AnalyticsReport> buildReport(AnalyticsPeriod period) async {
    final endDate = CalendarDate.fromDateTime(_now());
    final startDate = endDate.addDays(-(period.dayCount - 1));
    final source = await _repository.load(startDate, endDate);
    final recordsByDate = _latestRecordPerDate(source.dailyRecords);
    final actionsByDate = <CalendarDate, List<DailyAction>>{};
    for (final action in source.actions) {
      actionsByDate.putIfAbsent(action.localDate, () => []).add(action);
    }

    final days = <AnalyticsDay>[];
    for (var offset = 0; offset < period.dayCount; offset++) {
      final date = startDate.addDays(offset);
      final record = recordsByDate[date];
      final actions = actionsByDate[date] ?? const <DailyAction>[];
      days.add(
        AnalyticsDay(
          date: date,
          sleepMinutes: record?.sleepMinutes,
          mood: record?.mood?.value.toDouble(),
          energy: record?.energy?.value.toDouble(),
          weightGrams: record?.weightGrams,
          exerciseMinutes: record?.exerciseMinutes,
          actionCount: actions.length,
          completedActionCount: actions
              .where((action) => action.status == ActionStatus.completed)
              .length,
        ),
      );
    }

    final allActions = source.actions;
    final weights = days
        .where((day) => day.weightGrams != null)
        .toList(growable: false);
    final goalProgress = source.activeGoals
        .map((goal) => goal.progress)
        .toList(growable: false);

    return AnalyticsReport(
      period: period,
      startDate: startDate,
      endDate: endDate,
      days: List.unmodifiable(days),
      recordDays: recordsByDate.length,
      actionCount: allActions.length,
      completedActionCount: allActions
          .where((action) => action.status == ActionStatus.completed)
          .length,
      partialActionCount: allActions
          .where((action) => action.status == ActionStatus.partial)
          .length,
      exerciseDays: days.where((day) => (day.exerciseMinutes ?? 0) > 0).length,
      totalExerciseMinutes: days.fold(
        0,
        (sum, day) => sum + (day.exerciseMinutes ?? 0),
      ),
      activeGoalCount: source.activeGoals.length,
      averageSleepMinutes: _average(
        days.map((day) => day.sleepMinutes?.toDouble()),
      ),
      averageMood: _average(days.map((day) => day.mood)),
      averageEnergy: _average(days.map((day) => day.energy)),
      latestWeightGrams: weights.isEmpty ? null : weights.last.weightGrams,
      weightChangeGrams: weights.length < 2
          ? null
          : weights.last.weightGrams! - weights.first.weightGrams!,
      activeGoalAverageProgress: _average(goalProgress),
    );
  }

  Map<CalendarDate, DailyRecord> _latestRecordPerDate(
    List<DailyRecord> records,
  ) {
    final result = <CalendarDate, DailyRecord>{};
    for (final record in records) {
      final existing = result[record.localDate];
      if (existing == null || record.updatedAt.isAfter(existing.updatedAt)) {
        result[record.localDate] = record;
      }
    }
    return result;
  }

  double? _average(Iterable<double?> values) {
    final available = values.whereType<double>().toList(growable: false);
    if (available.isEmpty) return null;
    return available.reduce((sum, value) => sum + value) / available.length;
  }
}
