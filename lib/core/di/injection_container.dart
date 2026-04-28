import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:get_it/get_it.dart';
import 'package:mamba_fast_tracker/core/feature_flags/feature_flags_service.dart';
import 'package:mamba_fast_tracker/core/theme/theme_cubit.dart';
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
import 'package:shared_preferences/shared_preferences.dart';

final sl = GetIt.instance;

Future<void> setupDependencies() async {
  final preferences = await SharedPreferences.getInstance();
  final firebaseFirestore = FirebaseFirestore.instance;
  firebaseFirestore.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
  );

  sl
    ..registerSingleton<SharedPreferences>(preferences)
    ..registerLazySingleton<FirebaseAnalytics>(() => FirebaseAnalytics.instance)
    ..registerLazySingleton<FirebaseCrashlytics>(
      () => FirebaseCrashlytics.instance,
    )
    ..registerLazySingleton<FirebaseRemoteConfig>(
      () => FirebaseRemoteConfig.instance,
    )
    ..registerLazySingleton<FeatureFlagsService>(
      () => FeatureFlagsService(sl()),
    )
    ..registerFactory(() => ThemeCubit(sl()))
    ..registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance)
    ..registerLazySingleton<FirebaseFirestore>(() => firebaseFirestore)
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
      ),
    );

}
