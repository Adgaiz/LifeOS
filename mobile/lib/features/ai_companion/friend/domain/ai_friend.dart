import 'package:lifeos/features/ai/domain/ai_provider.dart';

const aiFriendPromptVersion = 1;
const aiFriendMaximumMessageLength = 2000;

enum AiFriendSafetyLevel {
  standard('日常陪伴'),
  sensitive('敏感主题'),
  crisis('安全回应');

  const AiFriendSafetyLevel(this.label);

  final String label;

  static AiFriendSafetyLevel fromStorage(String value) {
    return values.firstWhere(
      (level) => level.name == value,
      orElse: () => throw ArgumentError.value(
        value,
        'value',
        'Invalid AI Friend safety level',
      ),
    );
  }
}

final class AiFriendExchange {
  const AiFriendExchange({
    required this.id,
    required this.userMessage,
    required this.assistantMessage,
    required this.safetyLevel,
    required this.promptVersion,
    required this.createdAt,
    required this.version,
    this.provider,
    this.model,
    this.requestId,
    this.inputTokens,
    this.outputTokens,
  });

  final String id;
  final String userMessage;
  final String assistantMessage;
  final AiFriendSafetyLevel safetyLevel;
  final AiProviderType? provider;
  final String? model;
  final int promptVersion;
  final String? requestId;
  final int? inputTokens;
  final int? outputTokens;
  final DateTime createdAt;
  final int version;

  bool get isLocalSafetyResponse => safetyLevel == AiFriendSafetyLevel.crisis;
}

final class AiFriendValidationException implements Exception {
  const AiFriendValidationException(this.message);

  final String message;

  @override
  String toString() => message;
}
