import 'package:firebase_crashlytics/firebase_crashlytics.dart';

abstract class ErrorReporter {
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
  });
}

class FirebaseCrashlyticsErrorReporter implements ErrorReporter {
  FirebaseCrashlyticsErrorReporter(this._crashlytics);

  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> recordError(
    Object error,
    StackTrace stackTrace, {
    String? reason,
    bool fatal = false,
  }) {
    return _crashlytics.recordError(
      error,
      stackTrace,
      reason: reason,
      fatal: fatal,
    );
  }
}
