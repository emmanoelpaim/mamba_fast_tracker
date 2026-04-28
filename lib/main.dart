import 'dart:ui';

import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mamba_fast_tracker/app/router/app_router.dart';
import 'package:mamba_fast_tracker/core/di/injection_container.dart';
import 'package:mamba_fast_tracker/core/theme/theme_cubit.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mamba_fast_tracker/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await setupDependencies();
  FlutterError.onError = (details) {
    sl<FirebaseCrashlytics>().recordFlutterFatalError(details);
  };
  PlatformDispatcher.instance.onError = (error, stack) {
    sl<FirebaseCrashlytics>().recordError(error, stack, fatal: true);
    return true;
  };
  runApp(const AppBootstrap());
}

class AppBootstrap extends StatefulWidget {
  const AppBootstrap({super.key});

  @override
  State<AppBootstrap> createState() => _AppBootstrapState();
}

class _AppBootstrapState extends State<AppBootstrap> {
  late final AuthBloc _authBloc;
  late final ThemeCubit _themeCubit;
  late final RouterConfig<Object> _routerConfig;

  @override
  void initState() {
    super.initState();
    _themeCubit = sl<ThemeCubit>()..load();
    _authBloc = sl<AuthBloc>();
    _routerConfig = createRouter(
      _authBloc,
      observers: [
        FirebaseAnalyticsObserver(analytics: sl<FirebaseAnalytics>()),
      ],
    );
  }

  @override
  void dispose() {
    _themeCubit.close();
    _authBloc.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authBloc),
        BlocProvider.value(value: _themeCubit),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        bloc: _themeCubit,
        builder: (context, themeMode) {
          return MaterialApp.router(
            title: 'Mamba Fast Tracker',
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
              elevatedButtonTheme: ElevatedButtonThemeData(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: Colors.black,
                ),
              ),
              textButtonTheme: TextButtonThemeData(
                style: TextButton.styleFrom(
                  foregroundColor: Colors.white,
                ),
              ),
              outlinedButtonTheme: OutlinedButtonThemeData(
                style: OutlinedButton.styleFrom(
                  foregroundColor: Colors.black,
                  backgroundColor: Colors.white,
                  side: const BorderSide(color: Colors.white),
                ),
              ),
            ),
            themeMode: themeMode,
            routerConfig: _routerConfig,
          );
        },
      ),
    );
  }
}
