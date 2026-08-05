import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/ai/application/ai_providers.dart';
import 'package:lifeos/features/ai/domain/ai_provider.dart';
import 'package:lifeos/features/ai/domain/ai_request.dart';
import 'package:lifeos/features/ai/domain/ai_response.dart';
import 'package:lifeos/features/ai/domain/ai_service.dart';
import 'package:lifeos/features/ai_companion/friend/application/ai_friend_providers.dart';
import 'package:lifeos/features/ai_companion/friend/domain/ai_friend.dart';
import 'package:lifeos/features/ai_companion/friend/domain/ai_friend_repository.dart';
import 'package:lifeos/features/ai_companion/friend/presentation/ai_friend_page.dart';

void main() {
  testWidgets('sends a single exchange, saves it, and supports deletion', (
    tester,
  ) async {
    final repository = _FriendRepository();
    final aiService = _AiService();
    await _pumpPage(tester, repository, aiService);

    expect(find.text('此刻，想说点什么？'), findsOneWidget);
    expect(find.textContaining('不会自动读取日记'), findsOneWidget);
    expect(find.text('保存这次交流到本机'), findsOneWidget);

    await tester.enterText(find.byType(TextField), '今天有点累，想被听见。');
    final sendButton = find.widgetWithText(FilledButton, '发送并听听回应');
    await tester.ensureVisible(sendButton);
    await tester.tap(sendButton);
    await tester.pumpAndSettle();

    expect(find.text('AI Friend 回应'), findsOneWidget);
    expect(find.textContaining('慢一点'), findsOneWidget);
    expect(repository.items, hasLength(1));
    expect(aiService.calls, 1);
    expect(aiService.request?.messages.single.text, isNot(contains('历史复盘')));

    final deleteButton = find.widgetWithText(TextButton, '删除本机记录');
    await tester.ensureVisible(deleteButton);
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();

    expect(repository.items, isEmpty);
    expect(find.text('此刻，想说点什么？'), findsOneWidget);
  });

  testWidgets('crisis text shows local safety response without AI call', (
    tester,
  ) async {
    final repository = _FriendRepository();
    final aiService = _AiService();
    await _pumpPage(tester, repository, aiService);

    await tester.enterText(find.byType(TextField), '我不想活了，想伤害自己。');
    final sendButton = find.widgetWithText(FilledButton, '发送并听听回应');
    await tester.ensureVisible(sendButton);
    await tester.tap(sendButton);
    await tester.pumpAndSettle();

    expect(find.text('安全回应'), findsOneWidget);
    expect(find.textContaining('110 或 120'), findsOneWidget);
    expect(find.textContaining('没有把原文发送给 AI Provider'), findsOneWidget);
    expect(aiService.calls, 0);
    expect(repository.items.single.safetyLevel, AiFriendSafetyLevel.crisis);
  });
}

Future<void> _pumpPage(
  WidgetTester tester,
  _FriendRepository repository,
  _AiService aiService,
) async {
  await tester.pumpWidget(
    ProviderScope(
      overrides: [
        aiFriendRepositoryProvider.overrideWithValue(repository),
        aiServiceProvider.overrideWithValue(aiService),
      ],
      child: const MaterialApp(home: AiFriendPage()),
    ),
  );
  await tester.pumpAndSettle();
}

final class _FriendRepository implements AiFriendRepository {
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

final class _AiService implements AiService {
  int calls = 0;
  AiRequest? request;

  @override
  Future<AiResponse> generate(AiRequest value) async {
    calls++;
    request = value;
    return const AiResponse(
      text: '我听见你今天有些累。允许自己慢一点，也是一种照顾。',
      provider: AiProviderType.deepSeek,
      model: 'deepseek-v4-flash',
    );
  }
}
