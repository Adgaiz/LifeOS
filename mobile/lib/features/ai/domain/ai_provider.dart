enum AiProviderType {
  openAi(
    displayName: 'OpenAI',
    defaultModel: 'gpt-5.6-sol',
    keyPlaceholder: 'sk-...',
  ),
  gemini(
    displayName: 'Gemini',
    defaultModel: 'gemini-3.6-flash',
    keyPlaceholder: 'AIza...',
  ),
  claude(
    displayName: 'Claude',
    defaultModel: 'claude-sonnet-5',
    keyPlaceholder: 'sk-ant-...',
  ),
  deepSeek(
    displayName: 'DeepSeek',
    defaultModel: 'deepseek-v4-flash',
    keyPlaceholder: 'sk-...',
  );

  const AiProviderType({
    required this.displayName,
    required this.defaultModel,
    required this.keyPlaceholder,
  });

  final String displayName;
  final String defaultModel;
  final String keyPlaceholder;

  static AiProviderType fromStorage(String? value) {
    return AiProviderType.values.firstWhere(
      (provider) => provider.name == value,
      orElse: () => AiProviderType.deepSeek,
    );
  }
}
