import 'dart:convert';

import 'package:lifeos/features/ai/data/adapters/adapter_support.dart';
import 'package:lifeos/features/ai/data/ai_http_client.dart';
import 'package:lifeos/features/ai/domain/ai_provider.dart';
import 'package:lifeos/features/ai/domain/ai_request.dart';
import 'package:lifeos/features/ai/domain/ai_response.dart';
import 'package:lifeos/features/ai/domain/ai_service.dart';
import 'package:lifeos/features/ai/domain/ai_settings_repository.dart';

final class GeminiAdapter implements AiService {
  GeminiAdapter(this._client, this._configuration);

  final AiHttpClient _client;
  final AiProviderConfiguration _configuration;

  @override
  Future<AiResponse> generate(AiRequest request) async {
    final endpoint = Uri.https(
      'generativelanguage.googleapis.com',
      '/v1beta/models/${_configuration.model}:generateContent',
    );
    final response = await _client.post(
      endpoint,
      headers: {
        'x-goog-api-key': _configuration.apiKey,
        'content-type': 'application/json',
      },
      body: jsonEncode({
        if (request.systemInstruction?.trim().isNotEmpty ?? false)
          'systemInstruction': {
            'parts': [
              {'text': request.systemInstruction!.trim()},
            ],
          },
        'contents': [
          for (final message in request.messages)
            {
              'role': message.role == AiMessageRole.assistant
                  ? 'model'
                  : 'user',
              'parts': [
                {'text': message.text},
              ],
            },
        ],
        'generationConfig': {'maxOutputTokens': request.maxOutputTokens},
      }),
    );
    final json = decodeProviderJson(response);
    final candidates = json['candidates'];
    String? text;
    if (candidates is List && candidates.isNotEmpty) {
      final candidate = candidates.first;
      if (candidate is Map<String, dynamic>) {
        final content = candidate['content'];
        if (content is Map<String, dynamic>) {
          final parts = content['parts'];
          if (parts is List) {
            final texts = parts
                .whereType<Map<String, dynamic>>()
                .map((part) => part['text'])
                .whereType<String>();
            text = texts.join();
          }
        }
      }
    }
    final usage = json['usageMetadata'];
    return AiResponse(
      text: requiredText(text),
      provider: AiProviderType.gemini,
      model: _configuration.model,
      inputTokens: usage is Map<String, dynamic>
          ? integerValue(usage['promptTokenCount'])
          : null,
      outputTokens: usage is Map<String, dynamic>
          ? integerValue(usage['candidatesTokenCount'])
          : null,
    );
  }
}
