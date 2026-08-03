import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/ai/application/ai_service_router.dart';
import 'package:lifeos/features/ai/data/ai_http_client.dart';
import 'package:lifeos/features/ai/domain/ai_exception.dart';
import 'package:lifeos/features/ai/domain/ai_provider.dart';
import 'package:lifeos/features/ai/domain/ai_request.dart';
import 'package:lifeos/features/ai/domain/ai_settings_repository.dart';

void main() {
  test('routes generation through selected DeepSeek provider', () async {
    final repository = _MemorySettingsRepository(
      selected: AiProviderType.deepSeek,
      configurations: {
        AiProviderType.deepSeek: const AiProviderConfiguration(
          provider: AiProviderType.deepSeek,
          apiKey: 'secret',
          model: 'deepseek-v4-flash',
        ),
      },
    );
    final client = _RoutingHttpClient();
    final router = AiServiceRouter(repository, client);

    final response = await router.generate(
      AiRequest(
        messages: const [AiMessage(role: AiMessageRole.user, text: '你好')],
      ),
    );

    expect(client.lastHost, 'api.deepseek.com');
    expect(response.provider, AiProviderType.deepSeek);
  });

  test('rejects provider without an API key before network call', () async {
    final repository = _MemorySettingsRepository(
      selected: AiProviderType.gemini,
      configurations: const {},
    );
    final client = _RoutingHttpClient();
    final router = AiServiceRouter(repository, client);

    expect(
      () => router.generate(
        AiRequest(
          messages: const [AiMessage(role: AiMessageRole.user, text: '你好')],
        ),
      ),
      throwsA(
        isA<AiException>().having(
          (error) => error.type,
          'type',
          AiFailureType.invalidConfiguration,
        ),
      ),
    );
    expect(client.lastHost, isNull);
  });
}

final class _MemorySettingsRepository implements AiSettingsRepository {
  _MemorySettingsRepository({
    required this.selected,
    required this.configurations,
  });

  AiProviderType selected;
  final Map<AiProviderType, AiProviderConfiguration> configurations;

  @override
  Future<void> deleteConfiguration(AiProviderType provider) async {
    configurations.remove(provider);
  }

  @override
  Future<AiProviderConfiguration> readConfiguration(
    AiProviderType provider,
  ) async {
    return configurations[provider] ??
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
    );
  }

  @override
  Future<void> saveConfiguration(AiProviderConfiguration configuration) async {
    configurations[configuration.provider] = configuration;
  }

  @override
  Future<void> saveSelectedProvider(AiProviderType provider) async {
    selected = provider;
  }
}

final class _RoutingHttpClient implements AiHttpClient {
  String? lastHost;

  @override
  void close() {}

  @override
  Future<AiHttpResponse> post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    lastHost = uri.host;
    return AiHttpResponse(
      statusCode: 200,
      body: jsonEncode({
        'choices': [
          {
            'message': {'content': '你好'},
          },
        ],
      }),
      headers: const {},
    );
  }
}
