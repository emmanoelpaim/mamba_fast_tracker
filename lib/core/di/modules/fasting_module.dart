import 'package:get_it/get_it.dart';
import 'package:mamba_fast_tracker/core/notifications/fasting_end_notification_scheduler.dart';
import 'package:mamba_fast_tracker/features/fasting/data/datasources/fasting_local_data_source.dart';
import 'package:mamba_fast_tracker/features/fasting/data/datasources/fasting_remote_data_source.dart';
import 'package:mamba_fast_tracker/features/fasting/data/datasources/firebase_fasting_remote_data_source.dart';
import 'package:mamba_fast_tracker/features/fasting/data/datasources/shared_prefs_fasting_local_data_source.dart';
import 'package:mamba_fast_tracker/features/fasting/data/repositories/firebase_fasting_repository.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/repositories/fasting_repository.dart';
import 'package:mamba_fast_tracker/features/fasting/presentation/bloc/fasting_bloc.dart';

void registerFastingModule(GetIt sl) {
  sl
    ..registerLazySingleton<FastingRemoteDataSource>(
      () => FirebaseFastingRemoteDataSource(sl()),
    )
    ..registerLazySingleton<FastingLocalDataSource>(
      () => SharedPrefsFastingLocalDataSource(sl()),
    )
    ..registerLazySingleton<FastingRepository>(
      () => FirebaseFastingRepository(
        authRemoteDataSource: sl(),
        localDataSource: sl(),
        remoteDataSource: sl(),
        analyticsService: sl(),
        errorReporter: sl(),
        preferences: sl(),
      ),
    )
    ..registerFactory(
      () => FastingBloc(
        fastingRepository: sl(),
        endNotificationScheduler: sl<FastingEndNotificationScheduler>(),
      ),
    );
}
