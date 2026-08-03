import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/core/security/secure_store.dart';
import 'package:lifeos/features/ai/data/secure_ai_settings_repository.dart';
import 'package:lifeos/features/ai/domain/ai_provider.dart';
import 'package:lifeos/features/ai/domain/ai_settings_repository.dart';

void main() {
  test('saves provider settings under isolated secure storage keys', () async {
    final store = _MemorySecureStore();
    final repository = SecureAiSettingsRepository(store);

    await repository.saveSelectedProvider(AiProviderType.deepSeek);
    await repository.saveConfiguration(
      const AiProviderConfiguration(
        provider: AiProviderType.deepSeek,
        apiKey: 'sk-private-123456',
        model: 'deepseek-v4-flash',
      ),
    );

    expect(
      store.values[SecureAiSettingsRepository.selectedProviderStorageKey],
      'deepSeek',
    );
    expect(
      store.values[SecureAiSettingsRepository.apiKeyStorageKey(
        AiProviderType.deepSeek,
      )],
      'sk-private-123456',
    );
    expect(await repository.readSelectedProvider(), AiProviderType.deepSeek);
    expect(
      (await repository.readConfiguration(AiProviderType.deepSeek)).model,
      'deepseek-v4-flash',
    );
  });

  test('summary masks key and delete removes provider configuration', () async {
    final store = _MemorySecureStore();
    final repository = SecureAiSettingsRepository(store);
    await repository.saveConfiguration(
      const AiProviderConfiguration(
        provider: AiProviderType.openAi,
        apiKey: 'sk-do-not-expose-9876',
        model: 'gpt-5.6-sol',
      ),
    );

    final summary = await repository.readSummary(AiProviderType.openAi);

    expect(summary.isConfigured, isTrue);
    expect(summary.maskedApiKey, '••••9876');
    expect(summary.maskedApiKey, isNot(contains('do-not-expose')));

    await repository.deleteConfiguration(AiProviderType.openAi);
    final deleted = await repository.readSummary(AiProviderType.openAi);
    expect(deleted.isConfigured, isFalse);
    expect(deleted.model, AiProviderType.openAi.defaultModel);
  });
}

final class _MemorySecureStore implements SecureStore {
  final Map<String, String> values = {};

  @override
  Future<void> delete({required String key}) async => values.remove(key);

  @override
  Future<String?> read({required String key}) async => values[key];

  @override
  Future<void> write({required String key, required String value}) async {
    values[key] = value;
  }
}
