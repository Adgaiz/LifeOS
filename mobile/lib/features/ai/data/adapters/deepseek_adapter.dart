import 'dart:convert';

import 'package:lifeos/features/ai/data/adapters/adapter_support.dart';
import 'package:lifeos/features/ai/data/ai_http_client.dart';
import 'package:lifeos/features/ai/domain/ai_exception.dart';
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
        if (request.reasoningMode != AiReasoningMode.providerDefault)
          'thinking': {
            'type': request.reasoningMode == AiReasoningMode.enabled
                ? 'enabled'
                : 'disabled',
          },
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
    String? finishReason;
    if (choices is List && choices.isNotEmpty) {
      final choice = choices.first;
      if (choice is Map<String, dynamic>) {
        finishReason = optionalString(choice['finish_reason']);
        final message = choice['message'];
        if (message is Map<String, dynamic>) {
          text = optionalString(message['content']);
        }
      }
    }
    if (text?.trim().isEmpty ?? true) {
      switch (finishReason) {
        case 'length':
          throw const AiException(
            AiFailureType.outputLimit,
            'AI 在生成最终回答前已达到输出上限，请重试',
          );
        case 'content_filter':
          throw const AiException(
            AiFailureType.contentFiltered,
            'AI 回复触发了服务商的内容安全限制',
          );
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
