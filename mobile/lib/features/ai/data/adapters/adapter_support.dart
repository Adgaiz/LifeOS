import 'dart:convert';

import 'package:lifeos/features/ai/data/ai_http_client.dart';
import 'package:lifeos/features/ai/domain/ai_exception.dart';

Map<String, dynamic> decodeProviderJson(AiHttpResponse response) {
  if (response.statusCode < 200 || response.statusCode >= 300) {
    throw _httpException(response.statusCode);
  }
  try {
    final value = jsonDecode(response.body);
    if (value is! Map<String, dynamic>) {
      throw const FormatException();
    }
    return value;
  } on FormatException {
    throw const AiException(AiFailureType.malformedResponse, 'AI 服务返回了无法识别的数据');
  }
}

AiException _httpException(int statusCode) {
  if (statusCode == 401 || statusCode == 403) {
    return const AiException(AiFailureType.authentication, 'API Key 无效或没有访问权限');
  }
  if (statusCode == 429) {
    return const AiException(AiFailureType.rateLimit, '请求过于频繁或额度不足，请稍后重试');
  }
  return const AiException(
    AiFailureType.providerUnavailable,
    'AI 服务暂时不可用，请稍后重试',
  );
}

String requiredText(Object? value) {
  if (value is String && value.trim().isNotEmpty) {
    return value.trim();
  }
  throw const AiException(AiFailureType.malformedResponse, 'AI 服务未返回有效文本');
}

int? integerValue(Object? value) => value is int ? value : null;

String? optionalString(Object? value) => value is String ? value : null;
