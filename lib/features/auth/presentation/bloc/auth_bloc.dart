import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:flutter/foundation.dart';
import 'package:mamba_fast_tracker/core/error/failure.dart';
import 'package:mamba_fast_tracker/core/telemetry/analytics_service.dart';
import 'package:mamba_fast_tracker/core/telemetry/error_reporter.dart';
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
    required AnalyticsService analyticsService,
    required ErrorReporter errorReporter,
  }) : _observeAuthStateUseCase = observeAuthStateUseCase,
       _signInUseCase = signInUseCase,
       _signUpUseCase = signUpUseCase,
       _recoverPasswordUseCase = recoverPasswordUseCase,
       _signOutUseCase = signOutUseCase,
       _analyticsService = analyticsService,
       _errorReporter = errorReporter,
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
  final AnalyticsService _analyticsService;
  final ErrorReporter _errorReporter;
  StreamSubscription<AuthStatus>? _authSubscription;

  Future<void> _onStarted(AuthStarted event, Emitter<AuthState> emit) async {
    await _authSubscription?.cancel();
    _authSubscription = _observeAuthStateUseCase().listen(
      (status) => add(AuthStatusChanged(status == AuthStatus.authenticated)),
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
    await _analyticsService.logEvent(
      name: 'auth_login_requested',
      parameters: {'email_domain': _emailDomain(event.email)},
    );
    try {
      await _signInUseCase(email: event.email, password: event.password);
      debugPrint('[AUTH][LOGIN] Login realizado com sucesso: ${event.email}');
      await _analyticsService.logEvent(
        name: 'auth_login_success',
        parameters: {'email_domain': _emailDomain(event.email)},
      );
    } on Failure catch (e) {
      debugPrint('[AUTH][LOGIN][ERRO] ${e.code}: ${e.message}');
      await _analyticsService.logEvent(
        name: 'auth_login_failure',
        parameters: {'error_code': e.code},
      );
      emit(
        state.copyWith(status: AuthFlowStatus.error, errorMessage: e.message),
      );
    } catch (error, stackTrace) {
      debugPrint('[AUTH][LOGIN][ERRO] Falha inesperada no login');
      await _errorReporter.recordError(
        error,
        stackTrace,
        reason: 'auth_login_unexpected',
      );
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
    await _analyticsService.logEvent(
      name: 'auth_signup_requested',
      parameters: {'email_domain': _emailDomain(event.email)},
    );
    try {
      await _signUpUseCase(
        name: event.name,
        email: event.email,
        password: event.password,
      );
      debugPrint('[AUTH][CADASTRO] Cadastro concluido: ${event.email}');
      await _analyticsService.logEvent(
        name: 'auth_signup_success',
        parameters: {'email_domain': _emailDomain(event.email)},
      );
    } on Failure catch (e) {
      debugPrint('[AUTH][CADASTRO][ERRO] ${e.code}: ${e.message}');
      await _analyticsService.logEvent(
        name: 'auth_signup_failure',
        parameters: {'error_code': e.code},
      );
      emit(
        state.copyWith(status: AuthFlowStatus.error, errorMessage: e.message),
      );
    } catch (error, stackTrace) {
      debugPrint('[AUTH][CADASTRO][ERRO] Falha inesperada no cadastro');
      await _errorReporter.recordError(
        error,
        stackTrace,
        reason: 'auth_signup_unexpected',
      );
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
    await _analyticsService.logEvent(
      name: 'auth_recover_requested',
      parameters: {'email_domain': _emailDomain(event.email)},
    );
    try {
      await _recoverPasswordUseCase(email: event.email);
      debugPrint(
        '[AUTH][RECOVER] Email de recuperação de senha enviado: ${event.email}',
      );
      await _analyticsService.logEvent(
        name: 'auth_recover_success',
        parameters: {'email_domain': _emailDomain(event.email)},
      );
      emit(
        state.copyWith(
          status: AuthFlowStatus.passwordRecoverySent,
          errorMessage: '',
        ),
      );
    } on Failure catch (e) {
      debugPrint('[AUTH][RECOVER][ERRO] ${e.code}: ${e.message}');
      await _analyticsService.logEvent(
        name: 'auth_recover_failure',
        parameters: {'error_code': e.code},
      );
      emit(
        state.copyWith(status: AuthFlowStatus.error, errorMessage: e.message),
      );
    } catch (error, stackTrace) {
      debugPrint('[AUTH][RECOVER][ERRO] Falha inesperada ao recuperar senha');
      await _errorReporter.recordError(
        error,
        stackTrace,
        reason: 'auth_recover_unexpected',
      );
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
    emit(state.copyWith(status: AuthFlowStatus.loading, errorMessage: ''));
    try {
      await _signOutUseCase();
      await _analyticsService.logEvent(name: 'auth_logout_success');
    } on Failure catch (e) {
      emit(
        state.copyWith(status: AuthFlowStatus.error, errorMessage: e.message),
      );
    } catch (error, stackTrace) {
      await _errorReporter.recordError(
        error,
        stackTrace,
        reason: 'auth_logout_unexpected',
      );
      emit(
        state.copyWith(
          status: AuthFlowStatus.error,
          errorMessage: 'Falha ao sair da conta',
        ),
      );
    }
  }

  String _emailDomain(String email) {
    final parts = email.trim().split('@');
    if (parts.length != 2) return 'invalid';
    return parts.last.toLowerCase();
  }

  @override
  Future<void> close() async {
    await _authSubscription?.cancel();
    return super.close();
  }
}
