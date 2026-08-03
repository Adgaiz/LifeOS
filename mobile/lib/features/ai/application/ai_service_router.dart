import 'package:lifeos/features/ai/data/adapters/claude_adapter.dart';
import 'package:lifeos/features/ai/data/adapters/deepseek_adapter.dart';
import 'package:lifeos/features/ai/data/adapters/gemini_adapter.dart';
import 'package:lifeos/features/ai/data/adapters/openai_adapter.dart';
import 'package:lifeos/features/ai/data/ai_http_client.dart';
import 'package:lifeos/features/ai/domain/ai_exception.dart';
import 'package:lifeos/features/ai/domain/ai_provider.dart';
import 'package:lifeos/features/ai/domain/ai_request.dart';
import 'package:lifeos/features/ai/domain/ai_response.dart';
import 'package:lifeos/features/ai/domain/ai_service.dart';
import 'package:lifeos/features/ai/domain/ai_settings_repository.dart';

final class AiServiceRouter implements AiService {
  AiServiceRouter(this._settingsRepository, this._httpClient);

  final AiSettingsRepository _settingsRepository;
  final AiHttpClient _httpClient;

  @override
  Future<AiResponse> generate(AiRequest request) async {
    final provider = await _settingsRepository.readSelectedProvider();
    final configuration = await _settingsRepository.readConfiguration(provider);
    if (!configuration.isConfigured) {
      throw AiException(
        AiFailureType.invalidConfiguration,
        '请先配置 ${provider.displayName} API Key',
      );
    }

    final adapter = switch (provider) {
      AiProviderType.openAi => OpenAiAdapter(_httpClient, configuration),
      AiProviderType.gemini => GeminiAdapter(_httpClient, configuration),
      AiProviderType.claude => ClaudeAdapter(_httpClient, configuration),
      AiProviderType.deepSeek => DeepSeekAdapter(_httpClient, configuration),
    };
    return adapter.generate(request);
  }
}
