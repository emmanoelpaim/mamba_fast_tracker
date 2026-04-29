import 'package:mamba_fast_tracker/core/error/failure.dart';
import 'package:mamba_fast_tracker/core/offline_sync/persistent_sync_queue.dart';
import 'package:mamba_fast_tracker/core/telemetry/analytics_service.dart';
import 'package:mamba_fast_tracker/core/telemetry/error_reporter.dart';
import 'package:mamba_fast_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:mamba_fast_tracker/features/meal/data/datasources/meal_local_data_source.dart';
import 'package:mamba_fast_tracker/features/meal/data/datasources/meal_remote_data_source.dart';
import 'package:mamba_fast_tracker/features/meal/domain/entities/meal_entry.dart';
import 'package:mamba_fast_tracker/features/meal/domain/repositories/meal_repository.dart';
import 'package:shared_preferences/shared_preferences.dart';

class FirebaseMealRepository implements MealRepository {
  FirebaseMealRepository({
    required AuthRemoteDataSource authRemoteDataSource,
    required MealLocalDataSource localDataSource,
    required MealRemoteDataSource remoteDataSource,
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
         scope: 'meal',
       );

  final AuthRemoteDataSource _authRemoteDataSource;
  final MealLocalDataSource _localDataSource;
  final MealRemoteDataSource _remoteDataSource;
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
  Future<List<MealEntry>> getMeals() async {
    final uid = _uidOrThrow();
    await _flushQueue(uid);
    try {
      final remote = await _remoteDataSource.getMeals(uid: uid);
      final local = await _localDataSource.getMeals(uid: uid);
      final merged = _mergeMeals(local: local, remote: remote);
      await _localDataSource.saveMeals(uid: uid, meals: merged);
      return merged;
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
      await _enqueueMeals(uid, updated);
      return updated;
    }
    await _flushQueue(uid);
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
      await _enqueueMeals(uid, updated);
      return updated;
    }
    await _flushQueue(uid);
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
      await _enqueueMeals(uid, updated);
      return updated;
    }
    await _flushQueue(uid);
    return updated;
  }

  Future<void> _enqueueMeals(String uid, List<MealEntry> meals) {
    return _syncQueue.enqueue(
      uid: uid,
      operation: 'save_meals',
      payload: {'items': meals.map((item) => item.toMap()).toList(growable: false)},
    );
  }

  Future<void> _flushQueue(String uid) {
    return _syncQueue.process(uid, (item) async {
      if (item.operation != 'save_meals') return;
      final itemsRaw = item.payload['items'] as List? ?? const [];
      final meals = itemsRaw
          .whereType<Map>()
          .map((entry) => MealEntry.fromMap(Map<String, dynamic>.from(entry)))
          .toList(growable: false);
      await _remoteDataSource.saveMeals(uid: uid, meals: meals);
    });
  }

  List<MealEntry> _mergeMeals({
    required List<MealEntry> local,
    required List<MealEntry> remote,
  }) {
    final merged = <String, MealEntry>{};
    for (final item in remote) {
      merged[item.id] = item;
    }
    for (final item in local) {
      final current = merged[item.id];
      if (current == null || item.createdAtUtc.isAfter(current.createdAtUtc)) {
        merged[item.id] = item;
      }
    }
    final result = merged.values.toList(growable: false);
    result.sort((a, b) => b.createdAtUtc.compareTo(a.createdAtUtc));
    return result;
  }
}
