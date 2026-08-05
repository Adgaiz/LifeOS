import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/ai/domain/ai_provider.dart';
import 'package:lifeos/features/ai/domain/ai_request.dart';
import 'package:lifeos/features/ai/domain/ai_response.dart';
import 'package:lifeos/features/ai/domain/ai_service.dart';
import 'package:lifeos/features/ai_companion/periodic_report/application/periodic_report_providers.dart';
import 'package:lifeos/features/ai_companion/periodic_report/application/periodic_report_service.dart';
import 'package:lifeos/features/ai_companion/periodic_report/domain/periodic_report.dart';
import 'package:lifeos/features/ai_companion/periodic_report/domain/periodic_report_repository.dart';
import 'package:lifeos/features/ai_companion/periodic_report/presentation/periodic_report_page.dart';
import 'package:lifeos/features/analytics/application/analytics_service.dart';
import 'package:lifeos/features/analytics/domain/analytics.dart';
import 'package:lifeos/features/analytics/domain/analytics_repository.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/daily/domain/daily_record.dart';

void main() {
  testWidgets('requires consent, generates report, and switches period', (
    tester,
  ) async {
    final now = DateTime.utc(2026, 8, 5, 12);
    final aiService = _PageAiService();
    final service = PeriodicReportService(
      AnalyticsService(_PageAnalyticsRepository(now), now: () => now),
      _PageReportRepository(),
      aiService,
      now: () => now,
    );

    await tester.pumpWidget(
      ProviderScope(
        overrides: [periodicReportServiceProvider.overrideWithValue(service)],
        child: const MaterialApp(home: PeriodicReportPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('AI 周期解读'), findsOneWidget);
    expect(find.text('授权并生成周报'), findsOneWidget);
    expect(aiService.requests, isEmpty);
    final disabledButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '授权并生成周报'),
    );
    expect(disabledButton.onPressed, isNull);

    await tester.tap(find.text('状态趋势'));
    await tester.pump();
    final enabledButton = tester.widget<FilledButton>(
      find.widgetWithText(FilledButton, '授权并生成周报'),
    );
    expect(enabledButton.onPressed, isNotNull);

    await tester.ensureVisible(find.text('授权并生成周报'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('授权并生成周报'));
    await tester.pumpAndSettle();

    expect(aiService.requests, hasLength(1));
    expect(find.text('这段时间发生了什么'), findsOneWidget);
    expect(find.text('你已经完成了一次温柔回顾。'), findsOneWidget);
    expect(find.text('已使用：状态趋势'), findsOneWidget);

    await tester.ensureVisible(find.text('月报'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('月报'));
    await tester.pumpAndSettle();

    expect(find.text('授权并生成月报'), findsOneWidget);
    expect(aiService.requests, hasLength(1));
  });
}

final class _PageAnalyticsRepository implements AnalyticsRepository {
  _PageAnalyticsRepository(this.now);

  final DateTime now;

  @override
  Future<AnalyticsSourceData> load(
    CalendarDate startDate,
    CalendarDate endDate,
  ) async {
    final date = CalendarDate.fromDateTime(now);
    return AnalyticsSourceData(
      dailyRecords: [
        DailyRecord(
          id: '00000000-0000-4000-8000-000000000721',
          localDate: date,
          timezone: '+08:00',
          sleepMinutes: 450,
          mood: MoodLevel.good,
          energy: EnergyLevel.steady,
          createdAt: now,
          updatedAt: now,
          version: 1,
        ),
      ],
      actions: const [],
      activeGoals: const [],
    );
  }
}

final class _PageReportRepository implements PeriodicReportRepository {
  final List<AiPeriodicReport> saved = [];

  @override
  Future<AiPeriodicReport?> findLatest(
    AnalyticsPeriod period,
    CalendarDate startDate,
    CalendarDate endDate,
  ) async {
    return saved
        .where(
          (report) =>
              report.period == period &&
              report.startDate == startDate &&
              report.endDate == endDate,
        )
        .firstOrNull;
  }

  @override
  Future<void> save(AiPeriodicReport report) async => saved.insert(0, report);
}

final class _PageAiService implements AiService {
  final List<AiRequest> requests = [];

  @override
  Future<AiResponse> generate(AiRequest request) async {
    requests.add(request);
    return const AiResponse(
      text: '## 这段时间发生了什么\n\n你已经完成了一次温柔回顾。',
      provider: AiProviderType.deepSeek,
      model: 'deepseek-chat',
    );
  }
}
