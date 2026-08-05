import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/database/app_database.dart';
import 'package:lifeos/features/ai/domain/ai_provider.dart';
import 'package:lifeos/features/ai_companion/friend/data/drift_ai_friend_repository.dart';
import 'package:lifeos/features/ai_companion/friend/domain/ai_friend.dart';

void main() {
  late AppDatabase database;
  late DriftAiFriendRepository repository;

  setUp(() {
    database = AppDatabase.forTesting(NativeDatabase.memory());
    repository = DriftAiFriendRepository(database);
  });

  tearDown(() => database.close());

  test('persists provider metadata and returns latest exchange', () async {
    await repository.save(
      _exchange(
        id: '00000000-0000-4000-8000-000000000401',
        createdAt: DateTime.utc(2026, 8, 5, 9),
        assistantMessage: '第一次回应',
      ),
    );
    await repository.save(
      _exchange(
        id: '00000000-0000-4000-8000-000000000402',
        createdAt: DateTime.utc(2026, 8, 5, 10),
        assistantMessage: '第二次回应',
      ),
    );

    final latest = await repository.findLatest();
    final rows = await database.select(database.aiFriendExchanges).get();

    expect(rows, hasLength(2));
    expect(latest?.assistantMessage, '第二次回应');
    expect(latest?.provider, AiProviderType.deepSeek);
    expect(latest?.safetyLevel, AiFriendSafetyLevel.standard);
    expect(latest?.requestId, 'request-id');
  });

  test('deletes sensitive exchange content from local database', () async {
    final exchange = _exchange(
      id: '00000000-0000-4000-8000-000000000403',
      createdAt: DateTime.utc(2026, 8, 5, 10),
      assistantMessage: '准备删除',
    );
    await repository.save(exchange);

    await repository.delete(exchange.id);

    expect(await repository.findLatest(), isNull);
    expect(await database.select(database.aiFriendExchanges).get(), isEmpty);
  });

  test('persists local crisis response without provider metadata', () async {
    final exchange = AiFriendExchange(
      id: '00000000-0000-4000-8000-000000000404',
      userMessage: '危机表达',
      assistantMessage: '本地安全回应',
      safetyLevel: AiFriendSafetyLevel.crisis,
      promptVersion: aiFriendPromptVersion,
      createdAt: DateTime.utc(2026, 8, 5, 10),
      version: 1,
    );

    await repository.save(exchange);
    final loaded = await repository.findLatest();

    expect(loaded?.isLocalSafetyResponse, isTrue);
    expect(loaded?.provider, isNull);
    expect(loaded?.model, isNull);
  });
}

AiFriendExchange _exchange({
  required String id,
  required DateTime createdAt,
  required String assistantMessage,
}) {
  return AiFriendExchange(
    id: id,
    userMessage: '今天有点累',
    assistantMessage: assistantMessage,
    safetyLevel: AiFriendSafetyLevel.standard,
    provider: AiProviderType.deepSeek,
    model: 'deepseek-v4-flash',
    promptVersion: aiFriendPromptVersion,
    requestId: 'request-id',
    inputTokens: 30,
    outputTokens: 20,
    createdAt: createdAt,
    version: 1,
  );
}
