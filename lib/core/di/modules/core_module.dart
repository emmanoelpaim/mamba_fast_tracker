import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:get_it/get_it.dart';
import 'package:mamba_fast_tracker/core/feature_flags/feature_flags_service.dart';
import 'package:mamba_fast_tracker/core/telemetry/analytics_service.dart';
import 'package:mamba_fast_tracker/core/telemetry/error_reporter.dart';
import 'package:mamba_fast_tracker/core/theme/theme_cubit.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> registerCoreModule(GetIt sl) async {
  final preferences = await SharedPreferences.getInstance();
  final firebaseFirestore = FirebaseFirestore.instance;
  firebaseFirestore.settings = const Settings(
    persistenceEnabled: true,
    cacheSizeBytes: 50 * 1024 * 1024,
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
    ..registerLazySingleton<AnalyticsService>(
      () => FirebaseAnalyticsService(sl()),
    )
    ..registerLazySingleton<ErrorReporter>(
      () => FirebaseCrashlyticsErrorReporter(sl()),
    )
    ..registerFactory(() => ThemeCubit(sl()))
    ..registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance)
    ..registerLazySingleton<FirebaseFirestore>(() => firebaseFirestore);
}
