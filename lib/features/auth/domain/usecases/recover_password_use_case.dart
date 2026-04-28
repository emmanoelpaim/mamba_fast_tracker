import 'package:mamba_fast_tracker/features/auth/domain/repositories/auth_repository.dart';

class RecoverPasswordUseCase {
  const RecoverPasswordUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call({required String email}) {
    return _repository.recoverPassword(email: email);
  }
}
