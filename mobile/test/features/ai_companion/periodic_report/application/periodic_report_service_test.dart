import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/action/domain/daily_action.dart';
import 'package:lifeos/features/ai/domain/ai_provider.dart';
import 'package:lifeos/features/ai/domain/ai_request.dart';
import 'package:lifeos/features/ai/domain/ai_response.dart';
import 'package:lifeos/features/ai/domain/ai_service.dart';
import 'package:lifeos/features/ai_companion/periodic_report/application/periodic_report_service.dart';
import 'package:lifeos/features/ai_companion/periodic_report/domain/periodic_report.dart';
import 'package:lifeos/features/ai_companion/periodic_report/domain/periodic_report_repository.dart';
import 'package:lifeos/features/analytics/application/analytics_service.dart';
import 'package:lifeos/features/analytics/domain/analytics.dart';
import 'package:lifeos/features/analytics/domain/analytics_repository.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/daily/domain/daily_record.dart';

void main() {
  final now = DateTime.utc(2026, 8, 5, 12);
  late _MutableAnalyticsRepository analyticsRepository;
  late _MemoryPeriodicReportRepository reportRepository;
  late _RecordingAiService aiService;
  late PeriodicReportService service;

  setUp(() {
    analyticsRepository = _MutableAnalyticsRepository(_source(now));
    reportRepository = _MemoryPeriodicReportRepository();
    aiService = _RecordingAiService();
    service = PeriodicReportService(
      AnalyticsService(analyticsRepository, now: () => now),
      reportRepository,
      aiService,
      now: () => now,
    );
  });

  test('loads local analytics and saved report without calling AI', () async {
    final data = await service.load(AnalyticsPeriod.sevenDays);

    expect(data.context.analytics.recordDays, 1);
    expect(
      data.context.availableTypes,
      PeriodicReportContextType.values.toSet(),
    );
    expect(data.latestReport, isNull);
    expect(aiService.requests, isEmpty);
  });

  test('sends only authorized aggregates and persists AI evidence', () async {
    final data = await service.load(AnalyticsPeriod.sevenDays);

    final report = await service.generate(
      data.context,
      PeriodicReportSelection({
        PeriodicReportContextType.actions,
        PeriodicReportContextType.wellbeing,
      }),
    );

    final request = aiService.requests.single;
    final prompt = request.messages.single.text;
    expect(
      prompt,
      contains('"authorized_context_types":["wellbeing","actions"]'),
    );
    expect(prompt, contains('"wellbeing_summary"'));
    expect(prompt, contains('"action_summary"'));
    expect(prompt, isNot(contains('"health_summary"')));
    expect(prompt, isNot(contains('"goal_summary"')));
    expect(prompt, isNot(contains('绝不应发送的行动标题')));
    expect(prompt, isNot(contains('goal-private-id')));
    expect(prompt, isNot(contains('"local_date"')));
    expect(prompt, isNot(contains('"diary"')));
    expect(request.reasoningMode, AiReasoningMode.disabled);
    expect(request.maxOutputTokens, 1800);
    expect(request.systemInstruction, contains('## 数据边界'));
    expect(report.provider, AiProviderType.deepSeek);
    expect(report.model, 'deepseek-chat');
    expect(report.contextTypes, {
      PeriodicReportContextType.wellbeing,
      PeriodicReportContextType.actions,
    });
    expect(report.requestId, 'periodic-request-1');
    expect(report.inputTokens, 220);
    expect(report.outputTokens, 160);
    expect(report.createdAt, now);
    expect(reportRepository.saved.single.id, report.id);
  });

  test('rejects empty authorization before the network call', () async {
    final data = await service.load(AnalyticsPeriod.sevenDays);

    expect(
      () => service.generate(data.context, PeriodicReportSelection({})),
      throwsA(isA<PeriodicReportException>()),
    );
    expect(aiService.requests, isEmpty);
    expect(reportRepository.saved, isEmpty);
  });

  test('rejects changed aggregates before the network call', () async {
    final data = await service.load(AnalyticsPeriod.sevenDays);
    analyticsRepository.source = _source(now, mood: MoodLevel.low);

    expect(
      () => service.generate(
        data.context,
        PeriodicReportSelection({PeriodicReportContextType.wellbeing}),
      ),
      throwsA(
        isA<PeriodicReportException>().having(
          (error) => error.message,
          'message',
          contains('发生了变化'),
        ),
      ),
    );
    expect(aiService.requests, isEmpty);
    expect(reportRepository.saved, isEmpty);
  });
}

AnalyticsSourceData _source(DateTime now, {MoodLevel mood = MoodLevel.good}) {
  final date = CalendarDate.fromDateTime(now);
  return AnalyticsSourceData(
    dailyRecords: [
      DailyRecord(
        id: '00000000-0000-4000-8000-000000000701',
        localDate: date,
        timezone: '+08:00',
        sleepMinutes: 450,
        mood: mood,
        energy: EnergyLevel.steady,
        weightGrams: 65000,
        exerciseMinutes: 30,
        createdAt: now,
        updatedAt: now,
        version: 1,
      ),
    ],
    actions: [
      DailyAction(
        id: '00000000-0000-4000-8000-000000000702',
        localDate: date,
        title: '绝不应发送的行动标题',
        minimumAction: '绝不应发送的最低行动',
        category: ActionCategory.work,
        status: ActionStatus.completed,
        position: 0,
        createdAt: now,
        updatedAt: now,
        version: 1,
      ),
    ],
    activeGoals: const [
      AnalyticsGoalSource(id: 'goal-private-id', keyResultProgress: [60, 80]),
    ],
  );
}

final class _MutableAnalyticsRepository implements AnalyticsRepository {
  _MutableAnalyticsRepository(this.source);

  AnalyticsSourceData source;

  @override
  Future<AnalyticsSourceData> load(
    CalendarDate startDate,
    CalendarDate endDate,
  ) async => source;
}

final class _MemoryPeriodicReportRepository
    implements PeriodicReportRepository {
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

final class _RecordingAiService implements AiService {
  final List<AiRequest> requests = [];

  @override
  Future<AiResponse> generate(AiRequest request) async {
    requests.add(request);
    return const AiResponse(
      text: '## 这段时间发生了什么\n\n你稳稳地向前走了一步。',
      provider: AiProviderType.deepSeek,
      model: 'deepseek-chat',
      requestId: 'periodic-request-1',
      inputTokens: 220,
      outputTokens: 160,
    );
  }
}
