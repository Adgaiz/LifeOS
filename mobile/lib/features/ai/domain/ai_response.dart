import 'package:lifeos/features/ai/domain/ai_provider.dart';

final class AiResponse {
  const AiResponse({
    required this.text,
    required this.provider,
    required this.model,
    this.requestId,
    this.inputTokens,
    this.outputTokens,
  });

  final String text;
  final AiProviderType provider;
  final String model;
  final String? requestId;
  final int? inputTokens;
  final int? outputTokens;
}
