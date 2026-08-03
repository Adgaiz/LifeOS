import 'package:lifeos/features/ai/domain/ai_exception.dart';
import 'package:lifeos/features/ai/domain/ai_provider.dart';
import 'package:lifeos/features/ai/domain/ai_settings_repository.dart';

final class AiConfigurationService {
  AiConfigurationService(this._repository);

  final AiSettingsRepository _repository;

  Future<AiProviderType> readSelectedProvider() {
    return _repository.readSelectedProvider();
  }

  Future<AiProviderSummary> readSummary(AiProviderType provider) {
    return _repository.readSummary(provider);
  }

  Future<void> selectProvider(AiProviderType provider) {
    return _repository.saveSelectedProvider(provider);
  }

  Future<AiProviderSummary> save({
    required AiProviderType provider,
    required String model,
    String? newApiKey,
  }) async {
    final normalizedModel = model.trim();
    if (normalizedModel.isEmpty ||
        normalizedModel.length > 120 ||
        !_modelPattern.hasMatch(normalizedModel)) {
      throw const AiException(AiFailureType.invalidConfiguration, '模型名称格式不正确');
    }

    final existing = await _repository.readConfiguration(provider);
    final normalizedKey = newApiKey?.trim() ?? '';
    final apiKey = normalizedKey.isEmpty ? existing.apiKey : normalizedKey;
    if (apiKey.isEmpty) {
      throw const AiException(
        AiFailureType.invalidConfiguration,
        '请先填写 API Key',
      );
    }
    if (apiKey.length > 512 || apiKey.contains(RegExp(r'\s'))) {
      throw const AiException(
        AiFailureType.invalidConfiguration,
        'API Key 格式不正确',
      );
    }

    await _repository.saveConfiguration(
      AiProviderConfiguration(
        provider: provider,
        apiKey: apiKey,
        model: normalizedModel,
      ),
    );
    await _repository.saveSelectedProvider(provider);
    return _repository.readSummary(provider);
  }

  Future<void> delete(AiProviderType provider) {
    return _repository.deleteConfiguration(provider);
  }

  static final _modelPattern = RegExp(r'^[A-Za-z0-9._:/-]+$');
}
