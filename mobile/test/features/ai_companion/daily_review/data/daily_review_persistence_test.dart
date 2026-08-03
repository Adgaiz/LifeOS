import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/database/app_database.dart';
import 'package:lifeos/features/ai/domain/ai_provider.dart';
import 'package:lifeos/features/ai_companion/daily_review/data/drift_daily_review_repository.dart';
import 'package:lifeos/features/ai_companion/daily_review/domain/daily_review.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';

void main() {
  late AppDatabase database;
  late DriftDailyReviewRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftDailyReviewRepository(database);
  });

  tearDown(() => database.close());

  test('persists immutable daily review evidence and returns latest', () async {
    final date = CalendarDate(2026, 8, 3);
    await repository.save(
      _review(
        id: '00000000-0000-4000-8000-000000000201',
        date: date,
        createdAt: DateTime.utc(2026, 8, 3, 10),
        content: '第一次复盘',
      ),
    );
    await repository.save(
      _review(
        id: '00000000-0000-4000-8000-000000000202',
        date: date,
        createdAt: DateTime.utc(2026, 8, 3, 12),
        content: '第二次复盘',
      ),
    );

    final latest = await repository.findLatest(date);
    final rows = await database.select(database.aiDailyReviews).get();

    expect(rows, hasLength(2));
    expect(latest?.content, '第二次复盘');
    expect(latest?.provider, AiProviderType.deepSeek);
    expect(latest?.contextTypes, {
      DailyReviewContextType.dailyStatus,
      DailyReviewContextType.actions,
    });
    expect(latest?.promptVersion, dailyReviewPromptVersion);
    expect(latest?.requestId, 'request-id');
  });
}

AiDailyReview _review({
  required String id,
  required CalendarDate date,
  required DateTime createdAt,
  required String content,
}) {
  return AiDailyReview(
    id: id,
    localDate: date,
    content: content,
    provider: AiProviderType.deepSeek,
    model: 'deepseek-v4-flash',
    contextTypes: {
      DailyReviewContextType.dailyStatus,
      DailyReviewContextType.actions,
    },
    promptVersion: dailyReviewPromptVersion,
    requestId: 'request-id',
    inputTokens: 100,
    outputTokens: 50,
    createdAt: createdAt,
    version: 1,
  );
}
