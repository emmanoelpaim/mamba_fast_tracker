import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:mamba_fast_tracker/core/error/failure.dart';
import 'package:mamba_fast_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:mamba_fast_tracker/features/auth/domain/usecases/observe_auth_state_use_case.dart';
import 'package:mamba_fast_tracker/features/auth/domain/usecases/recover_password_use_case.dart';
import 'package:mamba_fast_tracker/features/auth/domain/usecases/sign_in_use_case.dart';
import 'package:mamba_fast_tracker/features/auth/domain/usecases/sign_out_use_case.dart';
import 'package:mamba_fast_tracker/features/auth/domain/usecases/sign_up_use_case.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_state.dart';

class AuthBloc extends Bloc<AuthEvent, AuthState> {
  AuthBloc({
    required ObserveAuthStateUseCase observeAuthStateUseCase,
    required SignInUseCase signInUseCase,
    required SignUpUseCase signUpUseCase,
    required RecoverPasswordUseCase recoverPasswordUseCase,
    required SignOutUseCase signOutUseCase,
  })  : _observeAuthStateUseCase = observeAuthStateUseCase,
        _signInUseCase = signInUseCase,
        _signUpUseCase = signUpUseCase,
        _recoverPasswordUseCase = recoverPasswordUseCase,
        _signOutUseCase = signOutUseCase,
        super(AuthState.initial) {
    on<AuthStarted>(_onStarted);
    on<AuthStatusChanged>(_onAuthStatusChanged);
    on<AuthLoginRequested>(_onLoginRequested);
    on<AuthRegisterRequested>(_onRegisterRequested);
    on<AuthRecoverPasswordRequested>(_onRecoverPasswordRequested);
    on<AuthLogoutRequested>(_onLogoutRequested);
  }

  final ObserveAuthStateUseCase _observeAuthStateUseCase;
  final SignInUseCase _signInUseCase;
  final SignUpUseCase _signUpUseCase;
  final RecoverPasswordUseCase _recoverPasswordUseCase;
  final SignOutUseCase _signOutUseCase;
  StreamSubscription<AuthStatus>? _authSubscription;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    await _authSubscription?.cancel();
    _authSubscription = _observeAuthStateUseCase().listen(
      (status) => add(
        AuthStatusChanged(status == AuthStatus.authenticated),
      ),
    );
  }

  void _onAuthStatusChanged(AuthStatusChanged event, Emitter<AuthState> emit) {
    emit(
      state.copyWith(
        status: event.isAuthenticated
            ? AuthFlowStatus.authenticated
            : AuthFlowStatus.unauthenticated,
        errorMessage: '',
      ),
    );
  }

  Future<void> _onLoginRequested(
    AuthLoginRequested event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint('[AUTH][LOGIN] Tentando login: ${event.email}');
    emit(state.copyWith(status: AuthFlowStatus.loading, errorMessage: ''));
    try {
      await _signInUseCase(email: event.email, password: event.password);
      debugPrint('[AUTH][LOGIN] Login realizado com sucesso: ${event.email}');
    } on Failure catch (e) {
      debugPrint('[AUTH][LOGIN][ERRO] ${e.code}: ${e.message}');
      emit(
        state.copyWith(
          status: AuthFlowStatus.error,
          errorMessage: e.message,
        ),
      );
    } catch (_) {
      debugPrint('[AUTH][LOGIN][ERRO] Falha inesperada no login');
      emit(
        state.copyWith(
          status: AuthFlowStatus.error,
          errorMessage: 'Falha ao autenticar',
        ),
      );
    }
  }

  Future<void> _onRegisterRequested(
    AuthRegisterRequested event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint('[AUTH][CADASTRO] Tentando cadastro: ${event.email}');
    emit(state.copyWith(status: AuthFlowStatus.loading, errorMessage: ''));
    try {
      await _signUpUseCase(
        name: event.name,
        email: event.email,
        password: event.password,
      );
      debugPrint('[AUTH][CADASTRO] Cadastro concluido: ${event.email}');
    } on Failure catch (e) {
      debugPrint('[AUTH][CADASTRO][ERRO] ${e.code}: ${e.message}');
      emit(
        state.copyWith(
          status: AuthFlowStatus.error,
          errorMessage: e.message,
        ),
      );
    } catch (_) {
      debugPrint('[AUTH][CADASTRO][ERRO] Falha inesperada no cadastro');
      emit(
        state.copyWith(
          status: AuthFlowStatus.error,
          errorMessage: 'Falha ao cadastrar',
        ),
      );
    }
  }

  Future<void> _onRecoverPasswordRequested(
    AuthRecoverPasswordRequested event,
    Emitter<AuthState> emit,
  ) async {
    debugPrint('[AUTH][RECOVER] Tentando recuperar senha: ${event.email}');
    emit(state.copyWith(status: AuthFlowStatus.loading, errorMessage: ''));
    try {
      await _recoverPasswordUseCase(email: event.email);
      debugPrint('[AUTH][RECOVER] Email de recuperação de senha enviado: ${event.email}');
      emit(
        state.copyWith(
          status: AuthFlowStatus.passwordRecoverySent,
          errorMessage: '',
        ),
      );
    } on Failure catch (e) {
      debugPrint('[AUTH][RECOVER][ERRO] ${e.code}: ${e.message}');
      emit(
        state.copyWith(
          status: AuthFlowStatus.error,
          errorMessage: e.message,
        ),
      );
    } catch (_) {
      debugPrint('[AUTH][RECOVER][ERRO] Falha inesperada ao recuperar senha');
      emit(
        state.copyWith(
          status: AuthFlowStatus.error,
          errorMessage: 'Falha ao enviar recuperação de senha',
        ),
      );
    }
  }

  Future<void> _onLogoutRequested(
    AuthLogoutRequested event,
    Emitter<AuthState> emit,
  ) async {
    await _signOutUseCase();
  }

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    return super.close();
  }
}
