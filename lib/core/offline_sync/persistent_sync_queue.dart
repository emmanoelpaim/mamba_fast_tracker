import 'dart:convert';

import 'package:mamba_fast_tracker/core/telemetry/analytics_service.dart';
import 'package:mamba_fast_tracker/core/telemetry/error_reporter.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SyncQueueItem {
  const SyncQueueItem({
    required this.id,
    required this.operation,
    required this.payload,
    required this.createdAtMs,
    this.attempts = 0,
    this.nextRetryAtMs,
    this.lastError,
  });

  final String id;
  final String operation;
  final Map<String, dynamic> payload;
  final int createdAtMs;
  final int attempts;
  final int? nextRetryAtMs;
  final String? lastError;

  bool isDue(int nowMs) => (nextRetryAtMs ?? 0) <= nowMs;

  SyncQueueItem copyWith({
    int? attempts,
    int? nextRetryAtMs,
    String? lastError,
    bool clearError = false,
  }) {
    return SyncQueueItem(
      id: id,
      operation: operation,
      payload: payload,
      createdAtMs: createdAtMs,
      attempts: attempts ?? this.attempts,
      nextRetryAtMs: nextRetryAtMs ?? this.nextRetryAtMs,
      lastError: clearError ? null : (lastError ?? this.lastError),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'operation': operation,
      'payload': payload,
      'createdAtMs': createdAtMs,
      'attempts': attempts,
      'nextRetryAtMs': nextRetryAtMs,
      'lastError': lastError,
    };
  }

  factory SyncQueueItem.fromMap(Map<String, dynamic> map) {
    return SyncQueueItem(
      id: map['id'] as String? ?? '',
      operation: map['operation'] as String? ?? '',
      payload: Map<String, dynamic>.from(map['payload'] as Map? ?? const {}),
      createdAtMs: map['createdAtMs'] as int? ?? 0,
      attempts: map['attempts'] as int? ?? 0,
      nextRetryAtMs: map['nextRetryAtMs'] as int?,
      lastError: map['lastError'] as String?,
    );
  }
}

class PersistentSyncQueue {
  PersistentSyncQueue({
    required SharedPreferences preferences,
    required AnalyticsService analyticsService,
    required ErrorReporter errorReporter,
    required String scope,
  }) : _preferences = preferences,
       _analyticsService = analyticsService,
       _errorReporter = errorReporter,
       _scope = scope;

  final SharedPreferences _preferences;
  final AnalyticsService _analyticsService;
  final ErrorReporter _errorReporter;
  final String _scope;

  String _key(String uid) => 'sync_queue_${_scope}_$uid';

  Future<void> enqueue({
    required String uid,
    required String operation,
    required Map<String, dynamic> payload,
  }) async {
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    final queue = await _read(uid);
    final item = SyncQueueItem(
      id: '$operation-$nowMs',
      operation: operation,
      payload: payload,
      createdAtMs: nowMs,
    );
    queue.add(item);
    await _write(uid, queue);
    await _analyticsService.logEvent(
      name: 'sync_enqueued',
      parameters: {'scope': _scope, 'operation': operation, 'size': queue.length},
    );
  }

  Future<int> count(String uid) async {
    final queue = await _read(uid);
    return queue.length;
  }

  Future<void> process(
    String uid,
    Future<void> Function(SyncQueueItem item) handler,
  ) async {
    final queue = await _read(uid);
    if (queue.isEmpty) return;
    final nowMs = DateTime.now().toUtc().millisecondsSinceEpoch;
    final updated = <SyncQueueItem>[];
    for (final item in queue) {
      if (!item.isDue(nowMs)) {
        updated.add(item);
        continue;
      }
      try {
        await handler(item);
        await _analyticsService.logEvent(
          name: 'sync_success',
          parameters: {'scope': _scope, 'operation': item.operation},
        );
      } catch (error, stackTrace) {
        final nextAttempts = item.attempts + 1;
        final shouldDrop = nextAttempts >= 8;
        await _analyticsService.logEvent(
          name: shouldDrop ? 'sync_dropped' : 'sync_retry_scheduled',
          parameters: {
            'scope': _scope,
            'operation': item.operation,
            'attempts': nextAttempts,
          },
        );
        await _errorReporter.recordError(
          error,
          stackTrace,
          reason: 'sync_${_scope}_${item.operation}_attempt_$nextAttempts',
          fatal: false,
        );
        if (!shouldDrop) {
          updated.add(
            item.copyWith(
              attempts: nextAttempts,
              nextRetryAtMs: nowMs + _retryDelayMs(nextAttempts),
              lastError: error.toString(),
            ),
          );
        }
      }
    }
    await _write(uid, updated);
  }

  int _retryDelayMs(int attempt) {
    final cappedAttempt = attempt.clamp(1, 8);
    final seconds = 15 * (1 << (cappedAttempt - 1));
    final cappedSeconds = seconds > 1800 ? 1800 : seconds;
    return cappedSeconds * 1000;
  }

  Future<List<SyncQueueItem>> _read(String uid) async {
    final raw = _preferences.getString(_key(uid));
    if (raw == null || raw.isEmpty) return [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return [];
    return decoded
        .whereType<Map>()
        .map((item) => SyncQueueItem.fromMap(Map<String, dynamic>.from(item)))
        .toList(growable: true);
  }

  Future<void> _write(String uid, List<SyncQueueItem> queue) {
    final payload = queue.map((item) => item.toMap()).toList(growable: false);
    return _preferences.setString(_key(uid), jsonEncode(payload));
  }
}
