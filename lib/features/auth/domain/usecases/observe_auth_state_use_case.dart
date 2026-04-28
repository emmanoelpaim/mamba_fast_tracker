import 'package:mamba_fast_tracker/features/auth/domain/repositories/auth_repository.dart';

class ObserveAuthStateUseCase {
  const ObserveAuthStateUseCase(this._repository);

  final AuthRepository _repository;

  Stream<AuthStatus> call() {
    return _repository.authStatusChanges();
  }
}
