import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:lifeos/features/ai/data/adapters/claude_adapter.dart';
import 'package:lifeos/features/ai/data/adapters/deepseek_adapter.dart';
import 'package:lifeos/features/ai/data/adapters/gemini_adapter.dart';
import 'package:lifeos/features/ai/data/adapters/openai_adapter.dart';
import 'package:lifeos/features/ai/data/ai_http_client.dart';
import 'package:lifeos/features/ai/domain/ai_exception.dart';
import 'package:lifeos/features/ai/domain/ai_provider.dart';
import 'package:lifeos/features/ai/domain/ai_request.dart';
import 'package:lifeos/features/ai/domain/ai_settings_repository.dart';

void main() {
  final request = AiRequest(
    systemInstruction: '温暖但诚实',
    messages: const [AiMessage(role: AiMessageRole.user, text: '今天怎么样？')],
    maxOutputTokens: 128,
  );

  test('OpenAI adapter uses Responses API and disables storage', () async {
    final client = _FakeHttpClient(
      responseBody: jsonEncode({
        'id': 'resp_1',
        'output': [
          {
            'type': 'message',
            'content': [
              {'type': 'output_text', 'text': '慢慢来。'},
            ],
          },
        ],
        'usage': {'input_tokens': 8, 'output_tokens': 4},
      }),
    );
    final adapter = OpenAiAdapter(
      client,
      _configuration(AiProviderType.openAi),
    );

    final response = await adapter.generate(request);
    final body = jsonDecode(client.lastBody!) as Map<String, dynamic>;

    expect(client.lastUri, OpenAiAdapter.endpoint);
    expect(client.lastHeaders?['authorization'], 'Bearer test-secret-key');
    expect(body['store'], isFalse);
    expect(body['instructions'], '温暖但诚实');
    expect(response.text, '慢慢来。');
    expect(response.inputTokens, 8);
  });

  test('Gemini adapter maps roles and candidate text', () async {
    final client = _FakeHttpClient(
      responseBody: jsonEncode({
        'candidates': [
          {
            'content': {
              'parts': [
                {'text': '看见自己就很好。'},
              ],
            },
          },
        ],
        'usageMetadata': {'promptTokenCount': 7, 'candidatesTokenCount': 6},
      }),
    );
    final adapter = GeminiAdapter(
      client,
      _configuration(AiProviderType.gemini),
    );

    final response = await adapter.generate(request);
    final body = jsonDecode(client.lastBody!) as Map<String, dynamic>;

    expect(client.lastUri?.host, 'generativelanguage.googleapis.com');
    expect(client.lastHeaders?['x-goog-api-key'], 'test-secret-key');
    expect(body['systemInstruction'], isNotNull);
    expect(response.text, '看见自己就很好。');
  });

  test(
    'Claude adapter sends required version header and parses text',
    () async {
      final client = _FakeHttpClient(
        responseBody: jsonEncode({
          'id': 'msg_1',
          'content': [
            {'type': 'text', 'text': '你已经在行动。'},
          ],
          'usage': {'input_tokens': 9, 'output_tokens': 5},
        }),
      );
      final adapter = ClaudeAdapter(
        client,
        _configuration(AiProviderType.claude),
      );

      final response = await adapter.generate(request);
      final body = jsonDecode(client.lastBody!) as Map<String, dynamic>;

      expect(client.lastUri, ClaudeAdapter.endpoint);
      expect(client.lastHeaders?['anthropic-version'], '2023-06-01');
      expect(body['max_tokens'], 128);
      expect(response.text, '你已经在行动。');
    },
  );

  test('DeepSeek adapter uses official chat completions contract', () async {
    final client = _FakeHttpClient(
      responseBody: jsonEncode({
        'id': 'chat_1',
        'choices': [
          {
            'message': {'role': 'assistant', 'content': '先完成最小的一步。'},
          },
        ],
        'usage': {'prompt_tokens': 10, 'completion_tokens': 7},
      }),
    );
    final adapter = DeepSeekAdapter(
      client,
      _configuration(AiProviderType.deepSeek),
    );

    final response = await adapter.generate(request);
    final body = jsonDecode(client.lastBody!) as Map<String, dynamic>;
    final messages = body['messages'] as List<dynamic>;

    expect(client.lastUri, DeepSeekAdapter.endpoint);
    expect(client.lastHeaders?['authorization'], 'Bearer test-secret-key');
    expect(body['model'], AiProviderType.deepSeek.defaultModel);
    expect(body['stream'], isFalse);
    expect((messages.first as Map<String, dynamic>)['role'], 'system');
    expect(response.text, '先完成最小的一步。');
    expect(response.provider, AiProviderType.deepSeek);
  });

  test('HTTP failures are mapped without provider body or secret', () async {
    final client = _FakeHttpClient(
      statusCode: 401,
      responseBody: 'test-secret-key 今天怎么样？',
    );
    final adapter = DeepSeekAdapter(
      client,
      _configuration(AiProviderType.deepSeek),
    );

    AiException? failure;
    try {
      await adapter.generate(request);
    } on AiException catch (error) {
      failure = error;
    }

    expect(failure?.type, AiFailureType.authentication);
    expect(failure.toString(), isNot(contains('test-secret-key')));
    expect(failure.toString(), isNot(contains('今天怎么样')));
  });

  test('malformed success response becomes a safe typed failure', () async {
    final client = _FakeHttpClient(responseBody: '{not-json');
    final adapter = DeepSeekAdapter(
      client,
      _configuration(AiProviderType.deepSeek),
    );

    expect(
      () => adapter.generate(request),
      throwsA(
        isA<AiException>().having(
          (error) => error.type,
          'type',
          AiFailureType.malformedResponse,
        ),
      ),
    );
  });
}

AiProviderConfiguration _configuration(AiProviderType provider) {
  return AiProviderConfiguration(
    provider: provider,
    apiKey: 'test-secret-key',
    model: provider.defaultModel,
  );
}

final class _FakeHttpClient implements AiHttpClient {
  _FakeHttpClient({this.statusCode = 200, required this.responseBody});

  final int statusCode;
  final String responseBody;
  Uri? lastUri;
  Map<String, String>? lastHeaders;
  String? lastBody;

  @override
  void close() {}

  @override
  Future<AiHttpResponse> post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    lastUri = uri;
    lastHeaders = headers;
    lastBody = body;
    return AiHttpResponse(
      statusCode: statusCode,
      body: responseBody,
      headers: const {},
    );
  }
}
