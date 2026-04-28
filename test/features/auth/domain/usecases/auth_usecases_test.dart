import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mamba_fast_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:mamba_fast_tracker/features/auth/domain/usecases/observe_auth_state_use_case.dart';
import 'package:mamba_fast_tracker/features/auth/domain/usecases/recover_password_use_case.dart';
import 'package:mamba_fast_tracker/features/auth/domain/usecases/sign_in_use_case.dart';
import 'package:mamba_fast_tracker/features/auth/domain/usecases/sign_out_use_case.dart';
import 'package:mamba_fast_tracker/features/auth/domain/usecases/sign_up_use_case.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}

void main() {
  late _MockAuthRepository repository;

  setUp(() {
    repository = _MockAuthRepository();
  });

  test('SignInUseCase chama repositorio', () async {
    when(() => repository.signIn(email: any(named: 'email'), password: any(named: 'password')))
        .thenAnswer((_) async {});
    final useCase = SignInUseCase(repository);

    await useCase(email: 'a@a.com', password: '123456');

    verify(() => repository.signIn(email: 'a@a.com', password: '123456')).called(1);
  });

  test('SignUpUseCase chama repositorio', () async {
    when(() => repository.signUp(
          name: any(named: 'name'),
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async {});
    final useCase = SignUpUseCase(repository);

    await useCase(name: 'Ana', email: 'a@a.com', password: '123456');

    verify(() => repository.signUp(name: 'Ana', email: 'a@a.com', password: '123456')).called(1);
  });

  test('RecoverPasswordUseCase chama repositorio', () async {
    when(() => repository.recoverPassword(email: any(named: 'email'))).thenAnswer((_) async {});
    final useCase = RecoverPasswordUseCase(repository);

    await useCase(email: 'a@a.com');

    verify(() => repository.recoverPassword(email: 'a@a.com')).called(1);
  });

  test('SignOutUseCase chama repositorio', () async {
    when(() => repository.signOut()).thenAnswer((_) async {});
    final useCase = SignOutUseCase(repository);

    await useCase();

    verify(() => repository.signOut()).called(1);
  });

  test('ObserveAuthStateUseCase retorna stream do repositorio', () async {
    when(() => repository.authStatusChanges())
        .thenAnswer((_) => Stream.value(AuthStatus.authenticated));
    final useCase = ObserveAuthStateUseCase(repository);

    await expectLater(useCase(), emits(AuthStatus.authenticated));
  });
}
