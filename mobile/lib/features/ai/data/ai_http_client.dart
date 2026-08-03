import 'dart:async';

import 'package:http/http.dart' as http;
import 'package:lifeos/features/ai/domain/ai_exception.dart';

final class AiHttpResponse {
  const AiHttpResponse({
    required this.statusCode,
    required this.body,
    required this.headers,
  });

  final int statusCode;
  final String body;
  final Map<String, String> headers;
}

abstract interface class AiHttpClient {
  Future<AiHttpResponse> post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
    Duration timeout,
  });

  void close();
}

final class DefaultAiHttpClient implements AiHttpClient {
  DefaultAiHttpClient({http.Client? client})
    : _client = client ?? http.Client();

  final http.Client _client;

  @override
  void close() => _client.close();

  @override
  Future<AiHttpResponse> post(
    Uri uri, {
    required Map<String, String> headers,
    required String body,
    Duration timeout = const Duration(seconds: 45),
  }) async {
    try {
      final response = await _client
          .post(uri, headers: headers, body: body)
          .timeout(timeout);
      return AiHttpResponse(
        statusCode: response.statusCode,
        body: response.body,
        headers: response.headers,
      );
    } on TimeoutException {
      throw const AiException(AiFailureType.timeout, 'AI 服务响应超时，请稍后重试');
    } on http.ClientException {
      throw const AiException(AiFailureType.network, '无法连接 AI 服务，请检查网络');
    }
  }
}
