import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/ai/application/ai_providers.dart';
import 'package:lifeos/features/ai/domain/ai_provider.dart';
import 'package:lifeos/features/ai/domain/ai_request.dart';
import 'package:lifeos/features/ai/domain/ai_response.dart';
import 'package:lifeos/features/ai/domain/ai_service.dart';
import 'package:lifeos/features/ai/domain/ai_settings_repository.dart';
import 'package:lifeos/features/ai/presentation/ai_settings_page.dart';

void main() {
  testWidgets('saves, masks, and deletes DeepSeek configuration', (
    tester,
  ) async {
    final repository = _MemorySettingsRepository();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [aiSettingsRepositoryProvider.overrideWithValue(repository)],
        child: const MaterialApp(home: AiSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('DeepSeek'), findsOneWidget);
    expect(find.text('尚未配置'), findsOneWidget);
    await tester.enterText(
      find.widgetWithText(TextFormField, 'API Key'),
      'sk-deepseek-private-5678',
    );
    await tester.tap(find.widgetWithText(FilledButton, '安全保存'));
    await tester.pumpAndSettle();

    expect(repository.configuration?.apiKey, 'sk-deepseek-private-5678');
    expect(find.text('已配置 ••••5678'), findsOneWidget);
    expect(find.text('sk-deepseek-private-5678'), findsNothing);

    final deleteButton = find.widgetWithText(TextButton, '删除本机配置');
    await tester.ensureVisible(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(deleteButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '删除'));
    await tester.pumpAndSettle();

    expect(repository.configuration, isNull);
    expect(find.text('尚未配置'), findsOneWidget);
  });

  testWidgets('connection test disables reasoning and reserves output tokens', (
    tester,
  ) async {
    final repository = _MemorySettingsRepository()
      ..configuration = const AiProviderConfiguration(
        provider: AiProviderType.deepSeek,
        apiKey: 'fake-key',
        model: 'deepseek-v4-flash',
      );
    final aiService = _RecordingAiService();
    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          aiSettingsRepositoryProvider.overrideWithValue(repository),
          aiServiceProvider.overrideWithValue(aiService),
        ],
        child: const MaterialApp(home: AiSettingsPage()),
      ),
    );
    await tester.pumpAndSettle();

    final testButton = find.widgetWithText(OutlinedButton, '保存并测试连接');
    await tester.ensureVisible(testButton);
    await tester.tap(testButton);
    await tester.pumpAndSettle();
    await tester.tap(find.widgetWithText(FilledButton, '开始测试'));
    await tester.pumpAndSettle();

    expect(aiService.request?.reasoningMode, AiReasoningMode.disabled);
    expect(aiService.request?.maxOutputTokens, 64);
    expect(find.text('DeepSeek 连接成功'), findsOneWidget);
  });
}

final class _RecordingAiService implements AiService {
  AiRequest? request;

  @override
  Future<AiResponse> generate(AiRequest value) async {
    request = value;
    return const AiResponse(
      text: '连接成功',
      provider: AiProviderType.deepSeek,
      model: 'deepseek-v4-flash',
    );
  }
}

final class _MemorySettingsRepository implements AiSettingsRepository {
  AiProviderType selected = AiProviderType.deepSeek;
  AiProviderConfiguration? configuration;

  @override
  Future<void> deleteConfiguration(AiProviderType provider) async {
    configuration = null;
  }

  @override
  Future<AiProviderConfiguration> readConfiguration(
    AiProviderType provider,
  ) async {
    return configuration ??
        AiProviderConfiguration(
          provider: provider,
          apiKey: '',
          model: provider.defaultModel,
        );
  }

  @override
  Future<AiProviderType> readSelectedProvider() async => selected;

  @override
  Future<AiProviderSummary> readSummary(AiProviderType provider) async {
    final value = await readConfiguration(provider);
    return AiProviderSummary(
      provider: provider,
      model: value.model,
      isConfigured: value.isConfigured,
      maskedApiKey: value.isConfigured ? '••••5678' : null,
    );
  }

  @override
  Future<void> saveConfiguration(AiProviderConfiguration value) async {
    configuration = value;
  }

  @override
  Future<void> saveSelectedProvider(AiProviderType provider) async {
    selected = provider;
  }
}
