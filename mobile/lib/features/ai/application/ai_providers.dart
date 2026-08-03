import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/core/security/secure_store_provider.dart';
import 'package:lifeos/features/ai/application/ai_configuration_service.dart';
import 'package:lifeos/features/ai/application/ai_service_router.dart';
import 'package:lifeos/features/ai/data/ai_http_client.dart';
import 'package:lifeos/features/ai/data/secure_ai_settings_repository.dart';
import 'package:lifeos/features/ai/domain/ai_service.dart';
import 'package:lifeos/features/ai/domain/ai_settings_repository.dart';

final aiSettingsRepositoryProvider = Provider<AiSettingsRepository>((ref) {
  return SecureAiSettingsRepository(ref.watch(secureStoreProvider));
});

final aiHttpClientProvider = Provider<AiHttpClient>((ref) {
  final client = DefaultAiHttpClient();
  ref.onDispose(client.close);
  return client;
});

final aiConfigurationServiceProvider = Provider<AiConfigurationService>((ref) {
  return AiConfigurationService(ref.watch(aiSettingsRepositoryProvider));
});

final aiServiceProvider = Provider<AiService>((ref) {
  return AiServiceRouter(
    ref.watch(aiSettingsRepositoryProvider),
    ref.watch(aiHttpClientProvider),
  );
});
