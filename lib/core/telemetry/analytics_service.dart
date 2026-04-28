import 'package:firebase_analytics/firebase_analytics.dart';

abstract class AnalyticsService {
  Future<void> logEvent({
    required String name,
    Map<String, Object?> parameters = const {},
  });
}

class FirebaseAnalyticsService implements AnalyticsService {
  FirebaseAnalyticsService(this._analytics);

  final FirebaseAnalytics _analytics;

  @override
  Future<void> logEvent({
    required String name,
    Map<String, Object?> parameters = const {},
  }) async {
    final sanitized = <String, Object>{};
    for (final entry in parameters.entries) {
      final value = entry.value;
      if (value is String || value is num || value is bool) {
        sanitized[entry.key] = value as Object;
      }
    }
    await _analytics.logEvent(name: name, parameters: sanitized);
  }
}
