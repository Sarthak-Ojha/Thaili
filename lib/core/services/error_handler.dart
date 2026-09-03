import 'package:flutter/foundation.dart';

/// Global application error reporting and handling service.
class ErrorHandler {
  static void setupGlobalErrorHandling() {
    FlutterError.onError = (FlutterErrorDetails details) {
      reportError(details.exception, details.stack);
    };

    PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
      reportError(error, stack);
      return true;
    };
  }

  static void reportError(dynamic error, StackTrace? stackTrace) {
    debugPrint('--------------------------------------------------');
    debugPrint('Thaili Global Error Handler Caught Exception:');
    debugPrint('$error');
    if (stackTrace != null) {
      debugPrint('Stack Trace:\n$stackTrace');
    }
    debugPrint('--------------------------------------------------');
  }
}
