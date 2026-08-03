import 'package:lifeos/features/ai/domain/ai_provider.dart';

final class AiProviderConfiguration {
  const AiProviderConfiguration({
    required this.provider,
    required this.apiKey,
    required this.model,
  });

  final AiProviderType provider;
  final String apiKey;
  final String model;

  bool get isConfigured => apiKey.isNotEmpty;
}

final class AiProviderSummary {
  const AiProviderSummary({
    required this.provider,
    required this.model,
    required this.isConfigured,
    this.maskedApiKey,
  });

  final AiProviderType provider;
  final String model;
  final bool isConfigured;
  final String? maskedApiKey;
}

abstract interface class AiSettingsRepository {
  Future<AiProviderType> readSelectedProvider();

  Future<void> saveSelectedProvider(AiProviderType provider);

  Future<AiProviderConfiguration> readConfiguration(AiProviderType provider);

  Future<AiProviderSummary> readSummary(AiProviderType provider);

  Future<void> saveConfiguration(AiProviderConfiguration configuration);

  Future<void> deleteConfiguration(AiProviderType provider);
}
