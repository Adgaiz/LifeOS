enum AiFailureType {
  invalidConfiguration,
  authentication,
  rateLimit,
  timeout,
  network,
  providerUnavailable,
  outputLimit,
  contentFiltered,
  malformedResponse,
}

final class AiException implements Exception {
  const AiException(this.type, this.message);

  final AiFailureType type;
  final String message;

  @override
  String toString() => 'AiException(${type.name}): $message';
}
