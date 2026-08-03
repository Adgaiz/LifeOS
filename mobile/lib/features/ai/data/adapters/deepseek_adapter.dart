import 'dart:convert';

import 'package:lifeos/features/ai/data/adapters/adapter_support.dart';
import 'package:lifeos/features/ai/data/ai_http_client.dart';
import 'package:lifeos/features/ai/domain/ai_provider.dart';
import 'package:lifeos/features/ai/domain/ai_request.dart';
import 'package:lifeos/features/ai/domain/ai_response.dart';
import 'package:lifeos/features/ai/domain/ai_service.dart';
import 'package:lifeos/features/ai/domain/ai_settings_repository.dart';

final class DeepSeekAdapter implements AiService {
  DeepSeekAdapter(this._client, this._configuration);

  static final endpoint = Uri.parse(
    'https://api.deepseek.com/chat/completions',
  );

  final AiHttpClient _client;
  final AiProviderConfiguration _configuration;

  @override
  Future<AiResponse> generate(AiRequest request) async {
    final response = await _client.post(
      endpoint,
      headers: {
        'authorization': 'Bearer ${_configuration.apiKey}',
        'content-type': 'application/json',
      },
      body: jsonEncode({
        'model': _configuration.model,
        'stream': false,
        'max_tokens': request.maxOutputTokens,
        'messages': [
          if (request.systemInstruction?.trim().isNotEmpty ?? false)
            {'role': 'system', 'content': request.systemInstruction!.trim()},
          for (final message in request.messages)
            {'role': message.role.apiValue, 'content': message.text},
        ],
      }),
    );
    final json = decodeProviderJson(response);
    final choices = json['choices'];
    String? text;
    if (choices is List && choices.isNotEmpty) {
      final choice = choices.first;
      if (choice is Map<String, dynamic>) {
        final message = choice['message'];
        if (message is Map<String, dynamic>) {
          text = optionalString(message['content']);
        }
      }
    }
    final usage = json['usage'];
    return AiResponse(
      text: requiredText(text),
      provider: AiProviderType.deepSeek,
      model: _configuration.model,
      requestId: optionalString(json['id']),
      inputTokens: usage is Map<String, dynamic>
          ? integerValue(usage['prompt_tokens'])
          : null,
      outputTokens: usage is Map<String, dynamic>
          ? integerValue(usage['completion_tokens'])
          : null,
    );
  }
}
