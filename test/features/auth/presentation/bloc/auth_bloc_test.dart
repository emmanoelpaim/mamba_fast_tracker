import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mamba_fast_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:mamba_fast_tracker/features/auth/domain/usecases/observe_auth_state_use_case.dart';
import 'package:mamba_fast_tracker/features/auth/domain/usecases/recover_password_use_case.dart';
import 'package:mamba_fast_tracker/features/auth/domain/usecases/sign_in_use_case.dart';
import 'package:mamba_fast_tracker/features/auth/domain/usecases/sign_out_use_case.dart';
import 'package:mamba_fast_tracker/features/auth/domain/usecases/sign_up_use_case.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_state.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;

  setUp(() {
    repository = _MockAuthRepository();
    when(() => repository.authStatusChanges())
        .thenAnswer((_) => const Stream<AuthStatus>.empty());
    when(() => repository.signIn(email: any(named: 'email'), password: any(named: 'password')))
        .thenAnswer((_) async {});
    when(() => repository.signUp(
          name: any(named: 'name'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async {});
    when(() => repository.recoverPassword(email: any(named: 'email'))).thenAnswer((_) async {});
    when(() => repository.signOut()).thenAnswer((_) async {});
  });

  AuthBloc buildBloc() {
    return AuthBloc(
      observeAuthStateUseCase: ObserveAuthStateUseCase(repository),
      signInUseCase: SignInUseCase(repository),
      signUpUseCase: SignUpUseCase(repository),
      recoverPasswordUseCase: RecoverPasswordUseCase(repository),
      signOutUseCase: SignOutUseCase(repository),
    );
  }

  blocTest<AuthBloc, AuthState>(
    'AuthStatusChanged para autenticado',
    build: buildBloc,
    act: (bloc) => bloc.add(const AuthStatusChanged(true)),
    expect: () => [
      const AuthState(status: AuthFlowStatus.authenticated),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'AuthLoginRequested emite loading',
    build: buildBloc,
    act: (bloc) => bloc.add(
      const AuthLoginRequested(email: 'a@a.com', password: '123456'),
    ),
    expect: () => [
      const AuthState(status: AuthFlowStatus.loading),
    ],
  );

  blocTest<AuthBloc, AuthState>(
    'AuthRecoverPasswordRequested emite loading e sucesso',
    build: buildBloc,
    act: (bloc) => bloc.add(
      const AuthRecoverPasswordRequested('a@a.com'),
    ),
    expect: () => [
      const AuthState(status: AuthFlowStatus.loading),
      const AuthState(status: AuthFlowStatus.passwordRecoverySent),
    ],
  );
}
