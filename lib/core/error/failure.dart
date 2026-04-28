import 'package:equatable/equatable.dart';

class Failure extends Equatable implements Exception {
  const Failure({
    required this.message,
    this.code = 'unknown',
  });

  final String message;
  final String code;

  @override
  List<Object?> get props => [message, code];
}

class AuthFailure extends Failure {
  const AuthFailure({
    required super.message,
    super.code,
  });
}

class DataFailure extends Failure {
  const DataFailure({
    required super.message,
    super.code,
  });
}
