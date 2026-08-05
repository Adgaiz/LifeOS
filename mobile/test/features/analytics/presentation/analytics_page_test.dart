import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/action/domain/daily_action.dart';
import 'package:lifeos/features/analytics/application/analytics_providers.dart';
import 'package:lifeos/features/analytics/domain/analytics.dart';
import 'package:lifeos/features/analytics/domain/analytics_repository.dart';
import 'package:lifeos/features/analytics/presentation/analytics_page.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/daily/domain/daily_record.dart';

void main() {
  testWidgets('shows local metrics and switches the report period', (
    tester,
  ) async {
    final today = CalendarDate.fromDateTime(DateTime.now());
    final now = DateTime.now().toUtc();
    final repository = _StaticAnalyticsRepository(
      AnalyticsSourceData(
        dailyRecords: [
          DailyRecord(
            id: '00000000-0000-4000-8000-000000000651',
            localDate: today,
            timezone: 'UTC+08:00',
            sleepMinutes: 480,
            mood: MoodLevel.good,
            energy: EnergyLevel.steady,
            weightGrams: 70000,
            exerciseMinutes: 30,
            createdAt: now,
            updatedAt: now,
            version: 1,
          ),
        ],
        actions: [
          DailyAction(
            id: '00000000-0000-4000-8000-000000000652',
            localDate: today,
            title: '完成今天的最低行动',
            category: ActionCategory.life,
            status: ActionStatus.completed,
            position: 0,
            createdAt: now,
            updatedAt: now,
            version: 1,
          ),
        ],
        activeGoals: const [
          AnalyticsGoalSource(id: 'goal', keyResultProgress: [60]),
        ],
      ),
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [analyticsRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: AnalyticsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('成长趋势'), findsOneWidget);
    expect(find.text('1/7'), findsOneWidget);
    expect(find.text('100%'), findsOneWidget);
    expect(find.text('平均 8.0 小时'), findsOneWidget);
    expect(find.text('最新 70.0 kg'), findsOneWidget);
    expect(find.text('AI 周期解读'), findsOneWidget);
    expect(find.text('生成 AI 周报'), findsOneWidget);

    await tester.tap(find.text('近 30 天'));
    await tester.pumpAndSettle();

    expect(find.text('1/30'), findsOneWidget);
    expect(find.text('生成 AI 月报'), findsOneWidget);
    expect(repository.calls, 2);
  });
}

final class _StaticAnalyticsRepository implements AnalyticsRepository {
  _StaticAnalyticsRepository(this.source);

  final AnalyticsSourceData source;
  int calls = 0;

  @override
  Future<AnalyticsSourceData> load(
    CalendarDate startDate,
    CalendarDate endDate,
  ) async {
    calls++;
    return source;
  }
}
