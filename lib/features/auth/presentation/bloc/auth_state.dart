import 'package:equatable/equatable.dart';

enum AuthFlowStatus {
  initial,
  loading,
  authenticated,
  unauthenticated,
  passwordRecoverySent,
  error,
}

class AuthState extends Equatable {
  const AuthState({required this.status, this.errorMessage = ''});

  final AuthFlowStatus status;
  final String errorMessage;

  bool get isAuthenticated => status == AuthFlowStatus.authenticated;

  AuthState copyWith({AuthFlowStatus? status, String? errorMessage}) {
    return AuthState(
      status: status ?? this.status,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  static const initial = AuthState(status: AuthFlowStatus.initial);

  @override
  List<Object?> get props => [status, errorMessage];
}
