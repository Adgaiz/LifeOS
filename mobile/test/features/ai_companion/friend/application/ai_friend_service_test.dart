import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/ai/domain/ai_provider.dart';
import 'package:lifeos/features/ai/domain/ai_request.dart';
import 'package:lifeos/features/ai/domain/ai_response.dart';
import 'package:lifeos/features/ai/domain/ai_service.dart';
import 'package:lifeos/features/ai_companion/friend/application/ai_friend_service.dart';
import 'package:lifeos/features/ai_companion/friend/domain/ai_friend.dart';
import 'package:lifeos/features/ai_companion/friend/domain/ai_friend_repository.dart';
import 'package:lifeos/features/ai_companion/friend/domain/friend_safety_classifier.dart';

void main() {
  late _MemoryFriendRepository repository;
  late _RecordingAiService aiService;
  late AiFriendService service;
  final now = DateTime.utc(2026, 8, 5, 10);

  setUp(() {
    repository = _MemoryFriendRepository();
    aiService = _RecordingAiService();
    service = AiFriendService(repository, aiService, now: () => now);
  });

  test(
    'standard exchange sends only typed message and persists locally',
    () async {
      final exchange = await service.respond(
        '  今天有点累，想慢一点。  ',
        saveLocally: true,
      );

      expect(aiService.calls, 1);
      expect(aiService.request?.messages.single.text, contains('今天有点累'));
      expect(aiService.request?.messages.single.text, isNot(contains('日记')));
      expect(aiService.request?.reasoningMode, AiReasoningMode.disabled);
      expect(aiService.request?.maxOutputTokens, 600);
      expect(exchange.userMessage, '今天有点累，想慢一点。');
      expect(exchange.safetyLevel, AiFriendSafetyLevel.standard);
      expect(exchange.provider, AiProviderType.deepSeek);
      expect(repository.items.single.id, exchange.id);
    },
  );

  test('user can choose not to persist a provider exchange', () async {
    final exchange = await service.respond('我想找个人听我说说。', saveLocally: false);

    expect(exchange.assistantMessage, contains('听见'));
    expect(aiService.calls, 1);
    expect(repository.items, isEmpty);
  });

  test(
    'crisis signal uses local safety response without provider call',
    () async {
      final exchange = await service.respond('我不想活了，想伤害自己。', saveLocally: true);

      expect(aiService.calls, 0);
      expect(exchange.safetyLevel, AiFriendSafetyLevel.crisis);
      expect(exchange.provider, isNull);
      expect(exchange.model, isNull);
      expect(exchange.assistantMessage, contains('110 或 120'));
      expect(exchange.assistantMessage, contains('AI 不能替代现实中的紧急支持'));
      expect(repository.items.single.id, exchange.id);
    },
  );

  test('sensitive topic adds professional-boundary instruction', () async {
    final exchange = await service.respond(
      '医生说我可能有焦虑症，我很害怕。',
      saveLocally: false,
    );

    expect(exchange.safetyLevel, AiFriendSafetyLevel.sensitive);
    expect(aiService.request?.systemInstruction, contains('合格专业人士'));
  });

  test('empty and oversized messages are rejected before AI call', () async {
    await expectLater(
      () => service.respond('   ', saveLocally: true),
      throwsA(isA<AiFriendValidationException>()),
    );
    await expectLater(
      () => service.respond(
        List.filled(aiFriendMaximumMessageLength + 1, 'a').join(),
        saveLocally: true,
      ),
      throwsA(isA<AiFriendValidationException>()),
    );
    expect(aiService.calls, 0);
  });

  test('deletes a saved local exchange', () async {
    final exchange = await service.respond('留下一次记录。', saveLocally: true);

    await service.delete(exchange.id);

    expect(repository.items, isEmpty);
  });

  test('classifier prioritizes crisis over other sensitive topics', () {
    const classifier = FriendSafetyClassifier();

    expect(classifier.classify('医生也帮不了我，我想自杀'), AiFriendSafetyLevel.crisis);
    expect(classifier.classify('我想咨询一下投资的压力'), AiFriendSafetyLevel.sensitive);
    expect(classifier.classify('今天只是有点孤单'), AiFriendSafetyLevel.standard);
  });
}

final class _MemoryFriendRepository implements AiFriendRepository {
  final List<AiFriendExchange> items = [];

  @override
  Future<void> delete(String id) async {
    items.removeWhere((exchange) => exchange.id == id);
  }

  @override
  Future<AiFriendExchange?> findLatest() async => items.firstOrNull;

  @override
  Future<void> save(AiFriendExchange exchange) async {
    items.insert(0, exchange);
  }
}

final class _RecordingAiService implements AiService {
  int calls = 0;
  AiRequest? request;

  @override
  Future<AiResponse> generate(AiRequest value) async {
    calls++;
    request = value;
    return const AiResponse(
      text: '我听见你现在有些辛苦。愿意先给自己一点喘息的空间吗？',
      provider: AiProviderType.deepSeek,
      model: 'deepseek-v4-flash',
      requestId: 'friend-request-1',
      inputTokens: 40,
      outputTokens: 30,
    );
  }
}
