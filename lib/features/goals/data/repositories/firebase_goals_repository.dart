import 'package:mamba_fast_tracker/core/error/failure.dart';
import 'package:mamba_fast_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:mamba_fast_tracker/features/goals/data/datasources/goals_local_data_source.dart';
import 'package:mamba_fast_tracker/features/goals/data/datasources/goals_remote_data_source.dart';
import 'package:mamba_fast_tracker/features/goals/domain/entities/daily_goals.dart';
import 'package:mamba_fast_tracker/features/goals/domain/repositories/goals_repository.dart';

class FirebaseGoalsRepository implements GoalsRepository {
  FirebaseGoalsRepository({
    required AuthRemoteDataSource authRemoteDataSource,
    required GoalsLocalDataSource localDataSource,
    required GoalsRemoteDataSource remoteDataSource,
  }) : _authRemoteDataSource = authRemoteDataSource,
       _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource;

  final AuthRemoteDataSource _authRemoteDataSource;
  final GoalsLocalDataSource _localDataSource;
  final GoalsRemoteDataSource _remoteDataSource;

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
    try {
      final remote = await _remoteDataSource.getGoals(uid: uid);
      if (remote != null) {
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
  Future<DailyGoals> saveGoals(DailyGoals goals) async {
    final uid = _uidOrThrow();
    await _localDataSource.saveGoals(uid: uid, goals: goals);
    try {
      await _remoteDataSource.saveGoals(uid: uid, goals: goals);
    } on Failure {
      return goals;
    }
    return goals;
  }
}
