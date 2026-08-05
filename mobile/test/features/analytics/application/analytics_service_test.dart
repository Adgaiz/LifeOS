import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/action/domain/daily_action.dart';
import 'package:lifeos/features/analytics/application/analytics_service.dart';
import 'package:lifeos/features/analytics/domain/analytics.dart';
import 'package:lifeos/features/analytics/domain/analytics_repository.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/daily/domain/daily_record.dart';

void main() {
  final now = DateTime(2026, 8, 5, 10);

  test('calculates a deterministic seven day report', () async {
    final repository = _MemoryAnalyticsRepository(
      AnalyticsSourceData(
        dailyRecords: [
          _record(
            id: '00000000-0000-4000-8000-000000000601',
            date: CalendarDate(2026, 8, 1),
            sleepMinutes: 420,
            mood: MoodLevel.steady,
            energy: EnergyLevel.low,
            weightGrams: 70000,
            exerciseMinutes: 30,
            updatedAt: DateTime.utc(2026, 8, 1, 12),
          ),
          _record(
            id: '00000000-0000-4000-8000-000000000602',
            date: CalendarDate(2026, 8, 2),
            sleepMinutes: 480,
            mood: MoodLevel.low,
            energy: EnergyLevel.low,
            weightGrams: 69500,
            exerciseMinutes: 60,
            updatedAt: DateTime.utc(2026, 8, 2, 8),
          ),
          _record(
            id: '00000000-0000-4000-8000-000000000603',
            date: CalendarDate(2026, 8, 2),
            sleepMinutes: 540,
            mood: MoodLevel.bright,
            energy: EnergyLevel.good,
            weightGrams: 69000,
            exerciseMinutes: 0,
            updatedAt: DateTime.utc(2026, 8, 2, 12),
          ),
        ],
        actions: [
          _action(
            '00000000-0000-4000-8000-000000000611',
            ActionStatus.completed,
          ),
          _action('00000000-0000-4000-8000-000000000612', ActionStatus.partial),
          _action('00000000-0000-4000-8000-000000000613', ActionStatus.pending),
        ],
        activeGoals: const [
          AnalyticsGoalSource(id: 'goal-1', keyResultProgress: [20, 40]),
          AnalyticsGoalSource(id: 'goal-2', keyResultProgress: [80]),
        ],
      ),
    );
    final service = AnalyticsService(repository, now: () => now);

    final report = await service.buildReport(AnalyticsPeriod.sevenDays);

    expect(repository.requestedStart, CalendarDate(2026, 7, 30));
    expect(repository.requestedEnd, CalendarDate(2026, 8, 5));
    expect(report.days, hasLength(7));
    expect(report.recordDays, 2);
    expect(report.averageSleepMinutes, 480);
    expect(report.averageMood, 4);
    expect(report.averageEnergy, 3);
    expect(report.exerciseDays, 1);
    expect(report.totalExerciseMinutes, 30);
    expect(report.latestWeightGrams, 69000);
    expect(report.weightChangeGrams, -1000);
    expect(report.actionCompletionRate, closeTo(100 / 3, 0.001));
    expect(report.partialActionCount, 1);
    expect(report.activeGoalAverageProgress, 55);
  });

  test(
    'returns null averages instead of treating missing values as zero',
    () async {
      final repository = _MemoryAnalyticsRepository(
        const AnalyticsSourceData(
          dailyRecords: [],
          actions: [],
          activeGoals: [],
        ),
      );
      final service = AnalyticsService(repository, now: () => now);

      final report = await service.buildReport(AnalyticsPeriod.thirtyDays);

      expect(report.startDate, CalendarDate(2026, 7, 7));
      expect(report.recordDays, 0);
      expect(report.checkInRate, 0);
      expect(report.averageSleepMinutes, isNull);
      expect(report.averageMood, isNull);
      expect(report.latestWeightGrams, isNull);
      expect(report.weightChangeGrams, isNull);
      expect(report.actionCompletionRate, isNull);
      expect(report.activeGoalAverageProgress, isNull);
    },
  );
}

DailyRecord _record({
  required String id,
  required CalendarDate date,
  required int sleepMinutes,
  required MoodLevel mood,
  required EnergyLevel energy,
  required int weightGrams,
  required int exerciseMinutes,
  required DateTime updatedAt,
}) {
  return DailyRecord(
    id: id,
    localDate: date,
    timezone: 'UTC+08:00',
    sleepMinutes: sleepMinutes,
    mood: mood,
    energy: energy,
    weightGrams: weightGrams,
    exerciseMinutes: exerciseMinutes,
    createdAt: updatedAt,
    updatedAt: updatedAt,
    version: 1,
  );
}

DailyAction _action(String id, ActionStatus status) {
  final now = DateTime.utc(2026, 8, 2, 8);
  return DailyAction(
    id: id,
    localDate: CalendarDate(2026, 8, 2),
    title: '行动',
    category: ActionCategory.life,
    status: status,
    position: 0,
    createdAt: now,
    updatedAt: now,
    version: 1,
  );
}

final class _MemoryAnalyticsRepository implements AnalyticsRepository {
  _MemoryAnalyticsRepository(this.source);

  final AnalyticsSourceData source;
  CalendarDate? requestedStart;
  CalendarDate? requestedEnd;

  @override
  Future<AnalyticsSourceData> load(
    CalendarDate startDate,
    CalendarDate endDate,
  ) async {
    requestedStart = startDate;
    requestedEnd = endDate;
    return source;
  }
}
