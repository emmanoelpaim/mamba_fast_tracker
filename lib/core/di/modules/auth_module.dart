import 'package:get_it/get_it.dart';
import 'package:mamba_fast_tracker/core/telemetry/analytics_service.dart';
import 'package:mamba_fast_tracker/core/telemetry/error_reporter.dart';
import 'package:mamba_fast_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:mamba_fast_tracker/features/auth/data/datasources/firebase_auth_remote_data_source.dart';
import 'package:mamba_fast_tracker/features/auth/data/datasources/firebase_user_profile_remote_data_source.dart';
import 'package:mamba_fast_tracker/features/auth/data/datasources/shared_prefs_user_profile_local_data_source.dart';
import 'package:mamba_fast_tracker/features/auth/data/datasources/user_profile_local_data_source.dart';
import 'package:mamba_fast_tracker/features/auth/data/datasources/user_profile_remote_data_source.dart';
import 'package:mamba_fast_tracker/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:mamba_fast_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:mamba_fast_tracker/features/auth/domain/usecases/observe_auth_state_use_case.dart';
import 'package:mamba_fast_tracker/features/auth/domain/usecases/recover_password_use_case.dart';
import 'package:mamba_fast_tracker/features/auth/domain/usecases/sign_in_use_case.dart';
import 'package:mamba_fast_tracker/features/auth/domain/usecases/sign_out_use_case.dart';
import 'package:mamba_fast_tracker/features/auth/domain/usecases/sign_up_use_case.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_bloc.dart';

void registerAuthModule(GetIt sl) {
  sl
    ..registerLazySingleton<AuthRemoteDataSource>(
      () => FirebaseAuthRemoteDataSource(sl()),
    )
    ..registerLazySingleton<UserProfileRemoteDataSource>(
      () => FirebaseUserProfileRemoteDataSource(sl()),
    )
    ..registerLazySingleton<UserProfileLocalDataSource>(
      () => SharedPrefsUserProfileLocalDataSource(sl()),
    )
    ..registerLazySingleton<AuthRepository>(
      () => FirebaseAuthRepository(
        authRemoteDataSource: sl(),
        userProfileRemoteDataSource: sl(),
        userProfileLocalDataSource: sl(),
      ),
    )
    ..registerLazySingleton(() => ObserveAuthStateUseCase(sl()))
    ..registerLazySingleton(() => SignInUseCase(sl()))
    ..registerLazySingleton(() => SignUpUseCase(sl()))
    ..registerLazySingleton(() => RecoverPasswordUseCase(sl()))
    ..registerLazySingleton(() => SignOutUseCase(sl()))
    ..registerFactory(
      () => AuthBloc(
        observeAuthStateUseCase: sl(),
        signInUseCase: sl(),
        signUpUseCase: sl(),
        recoverPasswordUseCase: sl(),
        signOutUseCase: sl(),
        analyticsService: sl<AnalyticsService>(),
        errorReporter: sl<ErrorReporter>(),
      ),
    );
}
