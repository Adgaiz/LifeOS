import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lifeos/app/app.dart';
import 'package:lifeos/core/logging/app_logger.dart';

void bootstrap() {
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    AppLogger.error(
      'Flutter framework error',
      error: details.exception,
      stackTrace: details.stack ?? StackTrace.current,
    );
  };

  PlatformDispatcher.instance.onError = (error, stackTrace) {
    AppLogger.error(
      'Uncaught platform error',
      error: error,
      stackTrace: stackTrace,
    );
    return true;
  };

  runZonedGuarded(
    () => runApp(const ProviderScope(child: LifeOsApp())),
    (error, stackTrace) => AppLogger.error(
      'Uncaught asynchronous error',
      error: error,
      stackTrace: stackTrace,
    ),
  );
}
