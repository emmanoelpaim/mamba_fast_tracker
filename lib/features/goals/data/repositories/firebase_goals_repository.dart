import 'package:mamba_fast_tracker/core/error/failure.dart';
import 'package:mamba_fast_tracker/core/offline_sync/persistent_sync_queue.dart';
import 'package:mamba_fast_tracker/core/telemetry/analytics_service.dart';
import 'package:mamba_fast_tracker/core/telemetry/error_reporter.dart';
import 'package:mamba_fast_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:mamba_fast_tracker/features/goals/data/datasources/goals_local_data_source.dart';
import 'package:mamba_fast_tracker/features/goals/data/datasources/goals_remote_data_source.dart';
import 'package:mamba_fast_tracker/features/goals/domain/entities/daily_goals.dart';
import 'package:mamba_fast_tracker/features/goals/domain/entities/goals_save_result.dart';
import 'package:mamba_fast_tracker/features/goals/domain/repositories/goals_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseGoalsRepository implements GoalsRepository {
  FirebaseGoalsRepository({
    required AuthRemoteDataSource authRemoteDataSource,
    required GoalsLocalDataSource localDataSource,
    required GoalsRemoteDataSource remoteDataSource,
    required AnalyticsService analyticsService,
    required ErrorReporter errorReporter,
    required SharedPreferences preferences,
  }) : _authRemoteDataSource = authRemoteDataSource,
       _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource,
       _syncQueue = PersistentSyncQueue(
         preferences: preferences,
         analyticsService: analyticsService,
         errorReporter: errorReporter,
         scope: 'goals',
       );

  final AuthRemoteDataSource _authRemoteDataSource;
  final GoalsLocalDataSource _localDataSource;
  final GoalsRemoteDataSource _remoteDataSource;
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
  Future<DailyGoals> getGoals() async {
    final uid = _uidOrThrow();
    await _flushQueue(uid);
    try {
      final remote = await _remoteDataSource.getGoals(uid: uid);
      if (remote != null) {
        final pending = await _syncQueue.count(uid);
        if (pending > 0) {
          final localPending = await _localDataSource.getGoals(uid: uid);
          if (localPending != null) return localPending;
        }
        await _localDataSource.saveGoals(uid: uid, goals: remote);
        return remote;
      }
    } on Failure {
      final localFallback = await _localDataSource.getGoals(uid: uid);
      return localFallback ?? DailyGoals.defaults;
    }
    final local = await _localDataSource.getGoals(uid: uid);
    return local ?? DailyGoals.defaults;
  }

  @override
  Future<GoalsSaveResult> saveGoals(DailyGoals goals) async {
    final uid = _uidOrThrow();
    await _localDataSource.saveGoals(uid: uid, goals: goals);
    try {
      await _remoteDataSource.saveGoals(uid: uid, goals: goals);
    } on Failure {
      await _syncQueue.enqueue(
        uid: uid,
        operation: 'save_goals',
        payload: goals.toMap(),
      );
      return GoalsSaveResult(
        goals: goals,
        status: GoalsSaveStatus.savedPendingSync,
      );
    }
    await _flushQueue(uid);
    return GoalsSaveResult(goals: goals, status: GoalsSaveStatus.savedRemote);
  }

  Future<void> _flushQueue(String uid) {
    return _syncQueue.process(uid, (item) async {
      if (item.operation == 'save_goals') {
        await _remoteDataSource.saveGoals(
          uid: uid,
          goals: DailyGoals.fromMap(item.payload),
        );
      }
    });
  }
}
