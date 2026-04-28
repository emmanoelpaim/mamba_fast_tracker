import 'package:equatable/equatable.dart';

abstract class AuthEvent extends Equatable {
  const AuthEvent();

  @override
  List<Object?> get props => [];
}

class AuthStarted extends AuthEvent {
  const AuthStarted();
}

class AuthStatusChanged extends AuthEvent {
  const AuthStatusChanged(this.isAuthenticated);

  final bool isAuthenticated;

  @override
  List<Object?> get props => [isAuthenticated];
}

class AuthLoginRequested extends AuthEvent {
  const AuthLoginRequested({
    required this.email,
    required this.password,
  });

  final String email;
  final String password;

  @override
  List<Object?> get props => [email, password];
}

class AuthRegisterRequested extends AuthEvent {
  const AuthRegisterRequested({
    required this.name,
    required this.email,
    required this.password,
  });

  final String name;
  final String email;
  final String password;

  @override
  List<Object?> get props => [name, email, password];
}

class AuthRecoverPasswordRequested extends AuthEvent {
  const AuthRecoverPasswordRequested(this.email);

  final String email;

  @override
  List<Object?> get props => [email];
}

class AuthLogoutRequested extends AuthEvent {
  const AuthLogoutRequested();
}
