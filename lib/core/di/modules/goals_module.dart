import 'package:get_it/get_it.dart';
import 'package:mamba_fast_tracker/features/goals/data/datasources/firebase_goals_remote_data_source.dart';
import 'package:mamba_fast_tracker/features/goals/data/datasources/goals_local_data_source.dart';
import 'package:mamba_fast_tracker/features/goals/data/datasources/goals_remote_data_source.dart';
import 'package:mamba_fast_tracker/features/goals/data/datasources/shared_prefs_goals_local_data_source.dart';
import 'package:mamba_fast_tracker/features/goals/data/repositories/firebase_goals_repository.dart';
import 'package:mamba_fast_tracker/features/goals/domain/repositories/goals_repository.dart';
import 'package:mamba_fast_tracker/features/goals/presentation/cubit/goals_cubit.dart';

void registerGoalsModule(GetIt sl) {
  sl
    ..registerLazySingleton<GoalsRemoteDataSource>(
      () => FirebaseGoalsRemoteDataSource(sl()),
    )
    ..registerLazySingleton<GoalsLocalDataSource>(
      () => SharedPrefsGoalsLocalDataSource(sl()),
    )
    ..registerLazySingleton<GoalsRepository>(
      () => FirebaseGoalsRepository(
        authRemoteDataSource: sl(),
        localDataSource: sl(),
        remoteDataSource: sl(),
        analyticsService: sl(),
        errorReporter: sl(),
        preferences: sl(),
      ),
    )
    ..registerFactory(() => GoalsCubit(goalsRepository: sl()));
}
