import 'dart:convert';

import 'package:lifeos/features/ai/data/adapters/adapter_support.dart';
import 'package:lifeos/features/ai/data/ai_http_client.dart';
import 'package:lifeos/features/ai/domain/ai_provider.dart';
import 'package:lifeos/features/ai/domain/ai_request.dart';
import 'package:lifeos/features/ai/domain/ai_response.dart';
import 'package:lifeos/features/ai/domain/ai_service.dart';
import 'package:lifeos/features/ai/domain/ai_settings_repository.dart';

final class ClaudeAdapter implements AiService {
  ClaudeAdapter(this._client, this._configuration);

  static final endpoint = Uri.parse('https://api.anthropic.com/v1/messages');

  final AiHttpClient _client;
  final AiProviderConfiguration _configuration;

  @override
  Future<AiResponse> generate(AiRequest request) async {
    final response = await _client.post(
      endpoint,
      headers: {
        'x-api-key': _configuration.apiKey,
        'anthropic-version': '2023-06-01',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'model': _configuration.model,
        'max_tokens': request.maxOutputTokens,
        if (request.systemInstruction?.trim().isNotEmpty ?? false)
          'system': request.systemInstruction!.trim(),
        'messages': [
          for (final message in request.messages)
            {'role': message.role.apiValue, 'content': message.text},
        ],
      }),
    );
    final json = decodeProviderJson(response);
    final content = json['content'];
    String? text;
    if (content is List) {
      text = content
          .whereType<Map<String, dynamic>>()
          .where((part) => part['type'] == 'text')
          .map((part) => part['text'])
          .whereType<String>()
          .join();
    }
    final usage = json['usage'];
    return AiResponse(
      text: requiredText(text),
      provider: AiProviderType.claude,
      model: _configuration.model,
      requestId: optionalString(json['id']),
      inputTokens: usage is Map<String, dynamic>
          ? integerValue(usage['input_tokens'])
          : null,
      outputTokens: usage is Map<String, dynamic>
          ? integerValue(usage['output_tokens'])
          : null,
    );
  }
}
