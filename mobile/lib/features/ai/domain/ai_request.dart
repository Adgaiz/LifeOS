enum AiMessageRole {
  user,
  assistant;

  String get apiValue => name;
}

final class AiMessage {
  const AiMessage({required this.role, required this.text});

  final AiMessageRole role;
  final String text;
}

final class AiRequest {
  AiRequest({
    required List<AiMessage> messages,
    this.systemInstruction,
    this.maxOutputTokens = 800,
  }) : messages = List.unmodifiable(messages) {
    if (messages.isEmpty ||
        messages.any((message) => message.text.trim().isEmpty)) {
      throw ArgumentError.value(messages, 'messages', '消息不能为空');
    }
    if (maxOutputTokens <= 0) {
      throw ArgumentError.value(maxOutputTokens, 'maxOutputTokens', '必须大于 0');
    }
  }

  final String? systemInstruction;
  final List<AiMessage> messages;
  final int maxOutputTokens;
}
