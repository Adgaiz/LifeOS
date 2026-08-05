import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/database/app_database.dart';
import 'package:lifeos/features/ai/domain/ai_provider.dart';
import 'package:lifeos/features/ai_companion/periodic_report/data/drift_periodic_report_repository.dart';
import 'package:lifeos/features/ai_companion/periodic_report/domain/periodic_report.dart';
import 'package:lifeos/features/analytics/domain/analytics.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';

void main() {
  late AppDatabase database;
  late DriftPeriodicReportRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftPeriodicReportRepository(database);
  });

  tearDown(() => database.close());

  test('returns latest immutable report for the exact period range', () async {
    final startDate = CalendarDate(2026, 7, 30);
    final endDate = CalendarDate(2026, 8, 5);
    await repository.save(
      _report(
        id: '00000000-0000-4000-8000-000000000711',
        startDate: startDate,
        endDate: endDate,
        createdAt: DateTime.utc(2026, 8, 5, 10),
        content: '第一次周报',
      ),
    );
    await repository.save(
      _report(
        id: '00000000-0000-4000-8000-000000000712',
        startDate: startDate,
        endDate: endDate,
        createdAt: DateTime.utc(2026, 8, 5, 12),
        content: '第二次周报',
      ),
    );
    await repository.save(
      _report(
        id: '00000000-0000-4000-8000-000000000713',
        startDate: CalendarDate(2026, 7, 29),
        endDate: CalendarDate(2026, 8, 4),
        createdAt: DateTime.utc(2026, 8, 5, 13),
        content: '旧周期周报',
      ),
    );

    final latest = await repository.findLatest(
      AnalyticsPeriod.sevenDays,
      startDate,
      endDate,
    );
    final rows = await database.select(database.aiPeriodicReports).get();

    expect(rows, hasLength(3));
    expect(latest?.content, '第二次周报');
    expect(latest?.provider, AiProviderType.deepSeek);
    expect(latest?.model, 'deepseek-chat');
    expect(latest?.contextTypes, {
      PeriodicReportContextType.wellbeing,
      PeriodicReportContextType.actions,
    });
    expect(latest?.promptVersion, periodicReportPromptVersion);
    expect(latest?.requestId, 'periodic-request-id');
    expect(rows.first.contextTypes, 'wellbeing,actions');
  });
}

AiPeriodicReport _report({
  required String id,
  required CalendarDate startDate,
  required CalendarDate endDate,
  required DateTime createdAt,
  required String content,
}) {
  return AiPeriodicReport(
    id: id,
    period: AnalyticsPeriod.sevenDays,
    startDate: startDate,
    endDate: endDate,
    content: content,
    provider: AiProviderType.deepSeek,
    model: 'deepseek-chat',
    contextTypes: {
      PeriodicReportContextType.actions,
      PeriodicReportContextType.wellbeing,
    },
    promptVersion: periodicReportPromptVersion,
    requestId: 'periodic-request-id',
    inputTokens: 220,
    outputTokens: 160,
    createdAt: createdAt,
    version: 1,
  );
}
