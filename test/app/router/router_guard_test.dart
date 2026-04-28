import 'package:flutter_test/flutter_test.dart';
import 'package:mamba_fast_tracker/app/router/router_guard.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_state.dart';

void main() {
  test('redireciona splash para login quando nao autenticado', () {
    final redirect = resolveRedirect(
      status: AuthFlowStatus.unauthenticated,
      location: '/splash',
    );

    expect(redirect, '/login');
  });

  test('redireciona splash para home quando autenticado', () {
    final redirect = resolveRedirect(
      status: AuthFlowStatus.authenticated,
      location: '/splash',
    );

    expect(redirect, '/home');
  });

  test('redireciona para home quando autenticado em rota publica', () {
    final redirect = resolveRedirect(
      status: AuthFlowStatus.authenticated,
      location: '/login',
    );

    expect(redirect, '/home');
  });

  test('redireciona para login quando nao autenticado em rota privada', () {
    final redirect = resolveRedirect(
      status: AuthFlowStatus.unauthenticated,
      location: '/home',
    );

    expect(redirect, '/login');
  });

  test('mantem splash sem redirecionamento', () {
    final redirect = resolveRedirect(
      status: AuthFlowStatus.initial,
      location: '/splash',
    );

    expect(redirect, isNull);
  });

  test('nao redireciona rota publica durante loading de formulario', () {
    final redirect = resolveRedirect(
      status: AuthFlowStatus.loading,
      location: '/register',
    );

    expect(redirect, isNull);
  });
}
