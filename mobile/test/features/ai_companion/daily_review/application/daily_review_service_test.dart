import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/action/domain/action_repository.dart';
import 'package:lifeos/features/action/domain/daily_action.dart';
import 'package:lifeos/features/ai/domain/ai_provider.dart';
import 'package:lifeos/features/ai/domain/ai_request.dart';
import 'package:lifeos/features/ai/domain/ai_response.dart';
import 'package:lifeos/features/ai/domain/ai_service.dart';
import 'package:lifeos/features/ai_companion/daily_review/application/daily_review_service.dart';
import 'package:lifeos/features/ai_companion/daily_review/domain/daily_review.dart';
import 'package:lifeos/features/ai_companion/daily_review/domain/daily_review_repository.dart';
import 'package:lifeos/features/daily/domain/calendar_date.dart';
import 'package:lifeos/features/daily/domain/daily_record.dart';
import 'package:lifeos/features/daily/domain/daily_repository.dart';
import 'package:lifeos/features/diary/domain/diary.dart';
import 'package:lifeos/features/diary/domain/diary_repository.dart';

void main() {
  final date = CalendarDate(2026, 8, 3);
  final now = DateTime.utc(2026, 8, 3, 13);
  late _MemoryReviewRepository reviewRepository;
  late _RecordingAiService aiService;
  late DailyReviewService service;

  setUp(() {
    reviewRepository = _MemoryReviewRepository();
    aiService = _RecordingAiService();
    service = DailyReviewService(
      _DailyRepository(_record(date, now)),
      _ActionRepository([_action(date, now)]),
      _DiaryRepository(_diary(date, now, '# 今天\n\n认真完成了一件事。')),
      reviewRepository,
      aiService,
      now: () => now,
    );
  });

  test('loads all local context without calling AI', () async {
    final data = await service.load(date, '+08:00');

    expect(data.context.dailyRecord?.mood, MoodLevel.good);
    expect(data.context.actions.single.title, '完成 LifeOS 开发');
    expect(data.context.diary?.entry.markdown, contains('认真完成'));
    expect(aiService.request, isNull);
  });

  test('sends only explicitly selected context and persists result', () async {
    final data = await service.load(date, '+08:00');

    final review = await service.generate(
      data.context,
      DailyReviewSelection({
        DailyReviewContextType.dailyStatus,
        DailyReviewContextType.actions,
      }),
    );

    final prompt = aiService.request!.messages.single.text;
    expect(prompt, contains('"daily_status"'));
    expect(prompt, contains('"actions"'));
    expect(prompt, isNot(contains('"diary"')));
    expect(aiService.request?.reasoningMode, AiReasoningMode.disabled);
    expect(aiService.request?.maxOutputTokens, 1200);
    expect(aiService.request?.systemInstruction, contains('## 明日最小建议'));
    expect(review.contextTypes, {
      DailyReviewContextType.dailyStatus,
      DailyReviewContextType.actions,
    });
    expect(reviewRepository.saved.single.content, contains('今日总结'));
    expect(review.createdAt, now);
  });

  test('selected diary is bounded and never includes image paths', () async {
    final longDiary =
        '${List.filled(7000, '成长').join()}'
        'private-image-path.jpg';
    service = DailyReviewService(
      _DailyRepository(null),
      _ActionRepository(const []),
      _DiaryRepository(_diary(date, now, longDiary)),
      reviewRepository,
      aiService,
      now: () => now,
    );
    final data = await service.load(date, '+08:00');

    await service.generate(
      data.context,
      DailyReviewSelection({DailyReviewContextType.diary}),
    );

    final prompt = aiService.request!.messages.single.text;
    expect(prompt, contains('"was_truncated":true'));
    expect(prompt, contains('"images_included":false'));
    expect(prompt, isNot(contains('private-image-path.jpg')));
  });

  test('empty authorization is rejected before calling AI', () async {
    final data = await service.load(date, '+08:00');

    expect(
      () => service.generate(data.context, DailyReviewSelection({})),
      throwsA(isA<DailyReviewException>()),
    );
    expect(aiService.request, isNull);
  });
}

DailyRecord _record(CalendarDate date, DateTime now) => DailyRecord(
  id: '00000000-0000-4000-8000-000000000101',
  localDate: date,
  timezone: '+08:00',
  sleepMinutes: 450,
  mood: MoodLevel.good,
  energy: EnergyLevel.steady,
  weightGrams: 65000,
  exerciseMinutes: 30,
  createdAt: now,
  updatedAt: now,
  version: 1,
);

DailyAction _action(CalendarDate date, DateTime now) => DailyAction(
  id: '00000000-0000-4000-8000-000000000102',
  localDate: date,
  title: '完成 LifeOS 开发',
  minimumAction: '先写一个测试',
  category: ActionCategory.work,
  status: ActionStatus.completed,
  position: 0,
  createdAt: now,
  updatedAt: now,
  version: 1,
);

DiaryAggregate _diary(CalendarDate date, DateTime now, String markdown) {
  return DiaryAggregate(
    entry: DiaryEntry(
      id: '00000000-0000-4000-8000-000000000103',
      localDate: date,
      markdown: markdown,
      createdAt: now,
      updatedAt: now,
      version: 1,
    ),
    tags: const [],
    attachments: const [],
  );
}

final class _DailyRepository implements DailyRepository {
  const _DailyRepository(this.record);

  final DailyRecord? record;

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

  final DiaryAggregate? diary;

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
  Stream<List<DiaryAggregate>> watchAll() => Stream.value([?diary]);
}

final class _MemoryReviewRepository implements DailyReviewRepository {
  final List<AiDailyReview> saved = [];

  @override
  Future<AiDailyReview?> findLatest(CalendarDate date) async {
    return saved.where((review) => review.localDate == date).firstOrNull;
  }

  @override
  Future<void> save(AiDailyReview review) async => saved.insert(0, review);
}

final class _RecordingAiService implements AiService {
  AiRequest? request;

  @override
  Future<AiResponse> generate(AiRequest value) async {
    request = value;
    return const AiResponse(
      text: '## 今日总结\n\n今天稳稳地向前走了一步。',
      provider: AiProviderType.deepSeek,
      model: 'deepseek-v4-flash',
      requestId: 'request-1',
      inputTokens: 100,
      outputTokens: 50,
    );
  }
}
