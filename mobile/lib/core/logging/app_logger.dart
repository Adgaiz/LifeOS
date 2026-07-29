import 'dart:developer' as developer;

abstract final class AppLogger {
  static void info(String message) {
    developer.log(message, name: 'lifeos');
  }

  static void error(
    String message, {
    required Object error,
    required StackTrace stackTrace,
  }) {
    developer.log(
      message,
      name: 'lifeos',
      level: 1000,
      error: error,
      stackTrace: stackTrace,
    );
  }
}
