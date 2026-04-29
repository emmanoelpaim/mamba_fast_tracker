import 'package:mamba_fast_tracker/core/error/failure.dart';
import 'package:mamba_fast_tracker/core/offline_sync/persistent_sync_queue.dart';
import 'package:mamba_fast_tracker/core/telemetry/analytics_service.dart';
import 'package:mamba_fast_tracker/core/telemetry/error_reporter.dart';
import 'package:mamba_fast_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:mamba_fast_tracker/features/fasting/data/datasources/fasting_local_data_source.dart';
import 'package:mamba_fast_tracker/features/fasting/data/datasources/fasting_remote_data_source.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/entities/fasting_day_history_entry.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/entities/fasting_protocol.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/entities/fasting_session.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/repositories/fasting_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseFastingRepository implements FastingRepository {
  FirebaseFastingRepository({
    required AuthRemoteDataSource authRemoteDataSource,
    required FastingLocalDataSource localDataSource,
    required FastingRemoteDataSource remoteDataSource,
    required AnalyticsService analyticsService,
    required ErrorReporter errorReporter,
    required SharedPreferences preferences,
  })  : _authRemoteDataSource = authRemoteDataSource,
        _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource,
        _syncQueue = PersistentSyncQueue(
          preferences: preferences,
          analyticsService: analyticsService,
          errorReporter: errorReporter,
          scope: 'fasting',
        );

  final AuthRemoteDataSource _authRemoteDataSource;
  final FastingLocalDataSource _localDataSource;
  final FastingRemoteDataSource _remoteDataSource;
  final PersistentSyncQueue _syncQueue;

  String _uidOrThrow() {
    final uid = _authRemoteDataSource.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw const AuthFailure(
        message: 'Usuário não autenticado',
        code: 'user-not-authenticated',
      );
    }
    return uid;
  }

  @override
  Future<FastingProtocol> getSelectedProtocol() async {
    final uid = _uidOrThrow();
    await _flushQueue(uid);
    var remoteFailed = false;
    try {
      final remote = await _remoteDataSource.getProtocol(uid: uid);
      if (remote != null) {
        final pending = await _syncQueue.count(uid);
        if (pending > 0) {
          final localPending = await _localDataSource.getProtocol(uid: uid);
          if (localPending != null) return localPending;
        }
        await _localDataSource.saveProtocol(uid: uid, protocol: remote);
        return remote;
      }
    } on Failure {
      remoteFailed = true;
    }
    final local = await _localDataSource.getProtocol(uid: uid);
    if (local != null) return local;
    if (remoteFailed) return FastingProtocol.defaultProtocol;
    return FastingProtocol.defaultProtocol;
  }

  @override
  Future<FastingSession> getSession() async {
    final uid = _uidOrThrow();
    await _flushQueue(uid);
    var remoteFailed = false;
    try {
      final remote = await _remoteDataSource.getSession(uid: uid);
      if (remote != null) {
        final pending = await _syncQueue.count(uid);
        if (pending > 0) {
          final localPending = await _localDataSource.getSession(uid: uid);
          if (localPending != null) return localPending;
        }
        await _localDataSource.saveSession(uid: uid, session: remote);
        return remote;
      }
    } on Failure {
      remoteFailed = true;
    }
    final local = await _localDataSource.getSession(uid: uid);
    if (local != null) return local;
    if (remoteFailed) return FastingSession.idle;
    return FastingSession.idle;
  }

  @override
  Future<void> saveSelectedProtocol(FastingProtocol protocol) async {
    final uid = _uidOrThrow();
    await _localDataSource.saveProtocol(uid: uid, protocol: protocol);
    var remoteFailed = false;
    try {
      await _remoteDataSource.saveProtocol(uid: uid, protocol: protocol);
    } on Failure {
      remoteFailed = true;
      await _syncQueue.enqueue(
        uid: uid,
        operation: 'save_protocol',
        payload: protocol.toMap(),
      );
    }
    if (remoteFailed) return;
    await _flushQueue(uid);
  }

  @override
  Future<void> saveSession(FastingSession session) async {
    final uid = _uidOrThrow();
    await _localDataSource.saveSession(uid: uid, session: session);
    var remoteFailed = false;
    try {
      await _remoteDataSource.saveSession(uid: uid, session: session);
    } on Failure {
      remoteFailed = true;
      await _syncQueue.enqueue(
        uid: uid,
        operation: 'save_session',
        payload: session.toMap(),
      );
    }
    if (remoteFailed) return;
    await _flushQueue(uid);
  }

  @override
  Future<List<FastingDayHistoryEntry>> getDayHistory() async {
    final uid = _uidOrThrow();
    await _flushQueue(uid);
    try {
      final remote = await _remoteDataSource.getDayHistory(uid: uid);
      final local = await _localDataSource.getDayHistory(uid: uid);
      final merged = _mergeHistory(local: local, remote: remote);
      await _localDataSource.saveDayHistory(uid: uid, history: merged);
      return merged;
    } on Failure {
      return _localDataSource.getDayHistory(uid: uid);
    }
  }

  @override
  Future<void> saveDayHistory(List<FastingDayHistoryEntry> history) async {
    final uid = _uidOrThrow();
    await _localDataSource.saveDayHistory(uid: uid, history: history);
    var remoteFailed = false;
    try {
      await _remoteDataSource.saveDayHistory(uid: uid, history: history);
    } on Failure {
      remoteFailed = true;
      await _syncQueue.enqueue(
        uid: uid,
        operation: 'save_history',
        payload: {
          'items': history.map((item) => item.toMap()).toList(growable: false),
        },
      );
    }
    if (remoteFailed) return;
    await _flushQueue(uid);
  }

  Future<void> _flushQueue(String uid) {
    return _syncQueue.process(uid, (item) async {
      if (item.operation == 'save_protocol') {
        await _remoteDataSource.saveProtocol(
          uid: uid,
          protocol: FastingProtocol.fromMap(item.payload),
        );
        return;
      }
      if (item.operation == 'save_session') {
        await _remoteDataSource.saveSession(
          uid: uid,
          session: FastingSession.fromMap(item.payload),
        );
        return;
      }
      if (item.operation == 'save_history') {
        final itemsRaw = item.payload['items'] as List? ?? const [];
        final history = itemsRaw
            .whereType<Map>()
            .map(
              (entry) =>
                  FastingDayHistoryEntry.fromMap(Map<String, dynamic>.from(entry)),
            )
            .toList(growable: false);
        await _remoteDataSource.saveDayHistory(uid: uid, history: history);
      }
    });
  }

  List<FastingDayHistoryEntry> _mergeHistory({
    required List<FastingDayHistoryEntry> local,
    required List<FastingDayHistoryEntry> remote,
  }) {
    final merged = <String, FastingDayHistoryEntry>{};
    for (final item in remote) {
      merged[item.id] = item;
    }
    for (final item in local) {
      final current = merged[item.id];
      if (current == null || item.endedAtUtc.isAfter(current.endedAtUtc)) {
        merged[item.id] = item;
      }
    }
    final result = merged.values.toList(growable: false);
    result.sort((a, b) => b.endedAtUtc.compareTo(a.endedAtUtc));
    return result;
  }
}
