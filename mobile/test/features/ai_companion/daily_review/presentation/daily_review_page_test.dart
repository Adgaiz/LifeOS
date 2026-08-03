import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/action/application/action_providers.dart';
import 'package:lifeos/features/action/domain/action_repository.dart';
import 'package:lifeos/features/action/domain/daily_action.dart';
import 'package:lifeos/features/ai/application/ai_providers.dart';
import 'package:lifeos/features/ai/domain/ai_provider.dart';
import 'package:lifeos/features/ai/domain/ai_request.dart';
import 'package:lifeos/features/ai/domain/ai_response.dart';
import 'package:lifeos/features/ai/domain/ai_service.dart';
import 'package:lifeos/features/ai_companion/daily_review/application/daily_review_providers.dart';
import 'package:lifeos/features/ai_companion/daily_review/domain/daily_review.dart';
import 'package:lifeos/features/ai_companion/daily_review/domain/daily_review_repository.dart';
import 'package:lifeos/features/ai_companion/daily_review/presentation/daily_review_page.dart';
import 'package:lifeos/features/daily/application/daily_providers.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/daily/domain/daily_record.dart';
import 'package:lifeos/features/daily/domain/daily_repository.dart';
import 'package:lifeos/features/diary/application/diary_providers.dart';
import 'package:lifeos/features/diary/domain/diary.dart';
import 'package:lifeos/features/diary/domain/diary_repository.dart';

void main() {
  testWidgets('requires explicit context selection and displays saved review', (
    tester,
  ) async {
    final now = DateTime(2026, 8, 3, 13);
    final date = CalendarDate.fromDateTime(now);
    final reviewRepository = _ReviewRepository();
    final aiService = _AiService();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          currentDateTimeProvider.overrideWithValue(now),
          dailyRepositoryProvider.overrideWithValue(
            _DailyRepository(_record(date, now.toUtc())),
          ),
          actionRepositoryProvider.overrideWithValue(
            _ActionRepository([_action(date, now.toUtc())]),
          ),
          diaryRepositoryProvider.overrideWithValue(
            _DiaryRepository(_diary(date, now.toUtc())),
          ),
          dailyReviewRepositoryProvider.overrideWithValue(reviewRepository),
          aiServiceProvider.overrideWithValue(aiService),
        ],
        child: const MaterialApp(home: DailyReviewPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('你决定 AI 这次能看到什么'), findsNothing);
    expect(find.textContaining('你决定 AI 这次能看到什么'), findsOneWidget);
    final generateButton = find.widgetWithText(FilledButton, '授权并生成复盘');
    expect(tester.widget<FilledButton>(generateButton).onPressed, isNull);

    await tester.tap(find.byType(Checkbox).at(0));
    await tester.tap(find.byType(Checkbox).at(1));
    await tester.pump();
    expect(tester.widget<FilledButton>(generateButton).onPressed, isNotNull);
    await tester.ensureVisible(generateButton);
    await tester.tap(generateButton);
    await tester.pumpAndSettle();

    expect(find.text('今天的复盘'), findsOneWidget);
    expect(find.text('做得好的地方'), findsOneWidget);
    expect(find.text('已使用：今日状态'), findsOneWidget);
    expect(find.text('已使用：今日任务'), findsOneWidget);
    expect(find.text('已使用：今日日记'), findsNothing);
    expect(reviewRepository.saved, hasLength(1));
    expect(aiService.request?.messages.single.text, isNot(contains('"diary"')));
  });
}

DailyRecord _record(CalendarDate date, DateTime now) => DailyRecord(
  id: '00000000-0000-4000-8000-000000000301',
  localDate: date,
  timezone: '+08:00',
  sleepMinutes: 450,
  mood: MoodLevel.good,
  energy: EnergyLevel.good,
  createdAt: now,
  updatedAt: now,
  version: 1,
);

DailyAction _action(CalendarDate date, DateTime now) => DailyAction(
  id: '00000000-0000-4000-8000-000000000302',
  localDate: date,
  title: '完成一项行动',
  category: ActionCategory.life,
  status: ActionStatus.completed,
  position: 0,
  createdAt: now,
  updatedAt: now,
  version: 1,
);

DiaryAggregate _diary(CalendarDate date, DateTime now) => DiaryAggregate(
  entry: DiaryEntry(
    id: '00000000-0000-4000-8000-000000000303',
    localDate: date,
    markdown: '这段日记没有被授权。',
    createdAt: now,
    updatedAt: now,
    version: 1,
  ),
  tags: const [],
  attachments: const [],
);

final class _DailyRepository implements DailyRepository {
  const _DailyRepository(this.record);

  final DailyRecord record;

  @override
  Future<DailyRecord?> findByDate(CalendarDate date, String timezone) async {
    return record;
  }

  @override
  Future<void> save(DailyRecord record) async {}

  @override
  Stream<DailyRecord?> watchByDate(CalendarDate date, String timezone) {
    return Stream.value(record);
  }
}

final class _ActionRepository implements ActionRepository {
  const _ActionRepository(this.actions);

  final List<DailyAction> actions;

  @override
  Future<void> add(DailyAction action) async {}

  @override
  Future<List<DailyAction>> findByDate(CalendarDate date) async => actions;

  @override
  Future<void> softDelete(String id, DateTime deletedAt) async {}

  @override
  Future<void> updateStatus(
    String id,
    ActionStatus status,
    DateTime updatedAt,
  ) async {}

  @override
  Stream<List<DailyAction>> watchByDate(CalendarDate date) {
    return Stream.value(actions);
  }
}

final class _DiaryRepository implements DiaryRepository {
  const _DiaryRepository(this.diary);

  final DiaryAggregate diary;

  @override
  Future<DiaryAggregate?> findByDate(CalendarDate date) async => diary;

  @override
  Future<DiaryAggregate?> findById(String id) async => diary;

  @override
  Future<List<DiaryAttachment>> findAttachmentsPendingFileDeletion(
    DateTime deletedBefore,
  ) async => const [];

  @override
  Future<void> markAttachmentFilesDeleted(
    String id,
    DateTime deletedAt,
  ) async {}

  @override
  Future<void> save(DiaryAggregate aggregate) async {}

  @override
  Future<void> softDelete(String id, DateTime deletedAt) async {}

  @override
  Stream<List<DiaryAggregate>> watchAll() => Stream.value([diary]);
}

final class _ReviewRepository implements DailyReviewRepository {
  final List<AiDailyReview> saved = [];

  @override
  Future<AiDailyReview?> findLatest(CalendarDate date) async {
    return saved.firstOrNull;
  }

  @override
  Future<void> save(AiDailyReview review) async => saved.insert(0, review);
}

final class _AiService implements AiService {
  AiRequest? request;

  @override
  Future<AiResponse> generate(AiRequest value) async {
    request = value;
    return const AiResponse(
      text: '## 今日总结\n今天完成了行动。\n\n## 做得好的地方\n愿意看见自己。',
      provider: AiProviderType.deepSeek,
      model: 'deepseek-v4-flash',
    );
  }
}
