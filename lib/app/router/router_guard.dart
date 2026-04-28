import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_state.dart';

String? resolveRedirect({
  required AuthFlowStatus status,
  required String location,
}) {
  const publicRoutes = {'/login', '/register', '/recover'};
  const privateRoutes = {'/home'};

  if (status == AuthFlowStatus.initial) {
    return location == '/splash' ? null : '/splash';
  }
  if (status == AuthFlowStatus.loading) {
    return location == '/splash' ? '/login' : null;
  }
  if (location == '/splash') {
    return status == AuthFlowStatus.authenticated ? '/home' : '/login';
  }
  if (status == AuthFlowStatus.authenticated && publicRoutes.contains(location)) {
    return '/home';
  }
  if (status != AuthFlowStatus.authenticated && privateRoutes.contains(location)) {
    return '/login';
  }
  return null;
}
