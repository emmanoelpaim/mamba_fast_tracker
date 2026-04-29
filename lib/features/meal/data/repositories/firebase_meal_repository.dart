import 'package:mamba_fast_tracker/core/error/failure.dart';
import 'package:mamba_fast_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:mamba_fast_tracker/features/meal/data/datasources/meal_local_data_source.dart';
import 'package:mamba_fast_tracker/features/meal/data/datasources/meal_remote_data_source.dart';
import 'package:mamba_fast_tracker/features/meal/domain/entities/meal_entry.dart';
import 'package:mamba_fast_tracker/features/meal/domain/repositories/meal_repository.dart';

class FirebaseMealRepository implements MealRepository {
  FirebaseMealRepository({
    required AuthRemoteDataSource authRemoteDataSource,
    required MealLocalDataSource localDataSource,
    required MealRemoteDataSource remoteDataSource,
  }) : _authRemoteDataSource = authRemoteDataSource,
       _localDataSource = localDataSource,
       _remoteDataSource = remoteDataSource;

  final AuthRemoteDataSource _authRemoteDataSource;
  final MealLocalDataSource _localDataSource;
  final MealRemoteDataSource _remoteDataSource;

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
  Future<List<MealEntry>> getMeals() async {
    final uid = _uidOrThrow();
    try {
      final remote = await _remoteDataSource.getMeals(uid: uid);
      await _localDataSource.saveMeals(uid: uid, meals: remote);
      return remote;
    } on Failure {
      return _localDataSource.getMeals(uid: uid);
    }
  }

  @override
  Future<List<MealEntry>> saveMeal(MealEntry meal) async {
    final uid = _uidOrThrow();
    final current = await _localDataSource.getMeals(uid: uid);
    final updated = [meal, ...current];
    await _localDataSource.saveMeals(uid: uid, meals: updated);
    try {
      await _remoteDataSource.saveMeals(uid: uid, meals: updated);
    } on Failure {
      return updated;
    }
    return updated;
  }

  @override
  Future<List<MealEntry>> updateMeal(MealEntry meal) async {
    final uid = _uidOrThrow();
    final current = await _localDataSource.getMeals(uid: uid);
    final updated = current
        .map((item) => item.id == meal.id ? meal : item)
        .toList(growable: false);
    await _localDataSource.saveMeals(uid: uid, meals: updated);
    try {
      await _remoteDataSource.saveMeals(uid: uid, meals: updated);
    } on Failure {
      return updated;
    }
    return updated;
  }

  @override
  Future<List<MealEntry>> deleteMeal(String id) async {
    final uid = _uidOrThrow();
    final current = await _localDataSource.getMeals(uid: uid);
    final updated = current
        .where((item) => item.id != id)
        .toList(growable: false);
    await _localDataSource.saveMeals(uid: uid, meals: updated);
    try {
      await _remoteDataSource.saveMeals(uid: uid, meals: updated);
    } on Failure {
      return updated;
    }
    return updated;
  }
}
