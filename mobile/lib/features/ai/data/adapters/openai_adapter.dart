import 'dart:convert';

import 'package:lifeos/features/ai/data/adapters/adapter_support.dart';
import 'package:lifeos/features/ai/data/ai_http_client.dart';
import 'package:lifeos/features/ai/domain/ai_provider.dart';
import 'package:lifeos/features/ai/domain/ai_request.dart';
import 'package:lifeos/features/ai/domain/ai_response.dart';
import 'package:lifeos/features/ai/domain/ai_service.dart';
import 'package:lifeos/features/ai/domain/ai_settings_repository.dart';

final class OpenAiAdapter implements AiService {
  OpenAiAdapter(this._client, this._configuration);

  static final endpoint = Uri.parse('https://api.openai.com/v1/responses');

  final AiHttpClient _client;
  final AiProviderConfiguration _configuration;

  @override
  Future<AiResponse> generate(AiRequest request) async {
    final payload = <String, Object?>{
      'model': _configuration.model,
      'input': [
        for (final message in request.messages)
          {'role': message.role.apiValue, 'content': message.text},
      ],
      'max_output_tokens': request.maxOutputTokens,
      'store': false,
      if (request.systemInstruction?.trim().isNotEmpty ?? false)
        'instructions': request.systemInstruction!.trim(),
    };
    final response = await _client.post(
      endpoint,
      headers: {
        'authorization': 'Bearer ${_configuration.apiKey}',
        'content-type': 'application/json',
      },
      body: jsonEncode(payload),
    );
    final json = decodeProviderJson(response);
    final output = json['output'];
    String? text;
    if (output is List) {
      for (final item in output.whereType<Map<String, dynamic>>()) {
        final content = item['content'];
        if (item['type'] == 'message' && content is List) {
          for (final part in content.whereType<Map<String, dynamic>>()) {
            if (part['type'] == 'output_text' && part['text'] is String) {
              text = part['text'] as String;
              break;
            }
          }
        }
        if (text != null) break;
      }
    }
    final usage = json['usage'];
    return AiResponse(
      text: requiredText(text),
      provider: AiProviderType.openAi,
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
