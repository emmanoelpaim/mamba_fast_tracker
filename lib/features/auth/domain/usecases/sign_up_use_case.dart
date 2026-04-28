import 'package:mamba_fast_tracker/features/auth/domain/repositories/auth_repository.dart';

class SignUpUseCase {
  const SignUpUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({
    required String name,
    required String email,
    required String password,
  }) {
    return _repository.signUp(
      name: name,
      email: email,
      password: password,
    );
  }
}
