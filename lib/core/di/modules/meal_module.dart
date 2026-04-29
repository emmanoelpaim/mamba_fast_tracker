import 'package:get_it/get_it.dart';
import 'package:mamba_fast_tracker/core/telemetry/analytics_service.dart';
import 'package:mamba_fast_tracker/features/meal/data/datasources/firebase_meal_remote_data_source.dart';
import 'package:mamba_fast_tracker/features/meal/data/datasources/meal_local_data_source.dart';
import 'package:mamba_fast_tracker/features/meal/data/datasources/meal_remote_data_source.dart';
import 'package:mamba_fast_tracker/features/meal/data/datasources/shared_prefs_meal_local_data_source.dart';
import 'package:mamba_fast_tracker/features/meal/data/repositories/firebase_meal_repository.dart';
import 'package:mamba_fast_tracker/features/meal/domain/repositories/meal_repository.dart';
import 'package:mamba_fast_tracker/features/meal/presentation/bloc/meal_bloc.dart';

void registerMealModule(GetIt sl) {
  sl
    ..registerLazySingleton<MealRemoteDataSource>(
      () => FirebaseMealRemoteDataSource(sl()),
    )
    ..registerLazySingleton<MealLocalDataSource>(
      () => SharedPrefsMealLocalDataSource(sl()),
    )
    ..registerLazySingleton<MealRepository>(
      () => FirebaseMealRepository(
        authRemoteDataSource: sl(),
        localDataSource: sl(),
        remoteDataSource: sl(),
        analyticsService: sl(),
        errorReporter: sl(),
        preferences: sl(),
      ),
    )
    ..registerFactory(
      () => MealBloc(
        mealRepository: sl(),
        analyticsService: sl<AnalyticsService>(),
      ),
    );
}
