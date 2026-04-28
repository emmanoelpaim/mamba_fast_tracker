import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/widgets.dart';
import 'package:go_router/go_router.dart';
import 'package:mamba_fast_tracker/app/router/go_router_refresh_stream.dart';
import 'package:mamba_fast_tracker/app/router/router_guard.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/pages/login_page.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/pages/recover_pass_page.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/pages/register_page.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/pages/splash_page.dart';
import 'package:mamba_fast_tracker/features/home/presentation/pages/home_page.dart';

GoRouter createRouter(
  AuthBloc authBloc, {
  List<NavigatorObserver> observers = const [],
}) {
  return GoRouter(
    initialLocation: '/splash',
    observers: observers,
    refreshListenable: GoRouterRefreshStream(authBloc.stream),
    redirect: (context, state) {
      final authState = context.read<AuthBloc>().state;
      return resolveRedirect(
        status: authState.status,
        location: state.matchedLocation,
      );
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashPage(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginPage(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterPage(),
      ),
      GoRoute(
        path: '/recover',
        builder: (context, state) => const RecoverPassPage(),
      ),
      GoRoute(
        path: '/home',
        builder: (context, state) => const HomePage(),
      ),
    ],
  );
}
