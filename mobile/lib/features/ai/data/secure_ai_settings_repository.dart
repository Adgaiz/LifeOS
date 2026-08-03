import 'package:lifeos/core/security/secure_store.dart';
import 'package:lifeos/features/ai/domain/ai_provider.dart';
import 'package:lifeos/features/ai/domain/ai_settings_repository.dart';

final class SecureAiSettingsRepository implements AiSettingsRepository {
  SecureAiSettingsRepository(this._secureStore);

  static const selectedProviderStorageKey = 'ai.selected_provider';

  final SecureStore _secureStore;

  static String apiKeyStorageKey(AiProviderType provider) {
    return 'ai.${provider.name}.api_key';
  }

  static String modelStorageKey(AiProviderType provider) {
    return 'ai.${provider.name}.model';
  }

  @override
  Future<void> deleteConfiguration(AiProviderType provider) async {
    await _secureStore.delete(key: apiKeyStorageKey(provider));
    await _secureStore.delete(key: modelStorageKey(provider));
  }

  @override
  Future<AiProviderConfiguration> readConfiguration(
    AiProviderType provider,
  ) async {
    final apiKey = await _secureStore.read(key: apiKeyStorageKey(provider));
    final model = await _secureStore.read(key: modelStorageKey(provider));
    return AiProviderConfiguration(
      provider: provider,
      apiKey: apiKey?.trim() ?? '',
      model: _normalizedModel(model, provider),
    );
  }

  @override
  Future<AiProviderType> readSelectedProvider() async {
    final value = await _secureStore.read(key: selectedProviderStorageKey);
    return AiProviderType.fromStorage(value);
  }

  @override
  Future<AiProviderSummary> readSummary(AiProviderType provider) async {
    final configuration = await readConfiguration(provider);
    return AiProviderSummary(
      provider: provider,
      model: configuration.model,
      isConfigured: configuration.isConfigured,
      maskedApiKey: configuration.isConfigured
          ? _maskApiKey(configuration.apiKey)
          : null,
    );
  }

  @override
  Future<void> saveConfiguration(AiProviderConfiguration configuration) async {
    await _secureStore.write(
      key: apiKeyStorageKey(configuration.provider),
      value: configuration.apiKey,
    );
    await _secureStore.write(
      key: modelStorageKey(configuration.provider),
      value: configuration.model,
    );
  }

  @override
  Future<void> saveSelectedProvider(AiProviderType provider) {
    return _secureStore.write(
      key: selectedProviderStorageKey,
      value: provider.name,
    );
  }

  static String _normalizedModel(String? model, AiProviderType provider) {
    final value = model?.trim() ?? '';
    return value.isEmpty ? provider.defaultModel : value;
  }

  static String _maskApiKey(String apiKey) {
    final suffixLength = apiKey.length < 4 ? apiKey.length : 4;
    return '••••${apiKey.substring(apiKey.length - suffixLength)}';
  }
}
