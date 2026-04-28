import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mamba_fast_tracker/core/error/failure.dart';
import 'package:mamba_fast_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:mamba_fast_tracker/features/auth/data/datasources/user_profile_local_data_source.dart';
import 'package:mamba_fast_tracker/features/auth/data/datasources/user_profile_remote_data_source.dart';
import 'package:mamba_fast_tracker/features/auth/data/repositories/firebase_auth_repository.dart';
import 'package:mamba_fast_tracker/features/auth/domain/entities/app_user.dart';
import 'package:mamba_fast_tracker/features/auth/domain/repositories/auth_repository.dart';

class _MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}
class _MockUserProfileRemoteDataSource extends Mock
    implements UserProfileRemoteDataSource {}
class _MockUserProfileLocalDataSource extends Mock
    implements UserProfileLocalDataSource {}
class _MockUserCredential extends Mock implements UserCredential {}
class _MockUser extends Mock implements User {}
class _FakeAppUser extends Fake implements AppUser {}

void main() {
  late _MockAuthRemoteDataSource authRemoteDataSource;
  late _MockUserProfileRemoteDataSource userProfileRemoteDataSource;
  late _MockUserProfileLocalDataSource userProfileLocalDataSource;
  late FirebaseAuthRepository repository;

  setUpAll(() {
    registerFallbackValue(_FakeAppUser());
  });

  setUp(() {
    authRemoteDataSource = _MockAuthRemoteDataSource();
    userProfileRemoteDataSource = _MockUserProfileRemoteDataSource();
    userProfileLocalDataSource = _MockUserProfileLocalDataSource();
    when(() => userProfileLocalDataSource.cacheProfile(any()))
        .thenAnswer((_) async {});
    when(() => userProfileLocalDataSource.getCachedProfile())
        .thenAnswer((_) async => null);
    repository = FirebaseAuthRepository(
      authRemoteDataSource: authRemoteDataSource,
      userProfileRemoteDataSource: userProfileRemoteDataSource,
      userProfileLocalDataSource: userProfileLocalDataSource,
    );
  });

  test('authStatusChanges mapeia usuario nulo para unauthenticated', () async {
    when(() => authRemoteDataSource.authStateChanges())
        .thenAnswer((_) => Stream.value(null));

    await expectLater(repository.authStatusChanges(), emits(AuthStatus.unauthenticated));
  });

  test('signIn chama datasource remoto', () async {
    when(() => authRemoteDataSource.signIn(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => _MockUserCredential());

    await repository.signIn(email: 'a@a.com', password: '123456');

    verify(() => authRemoteDataSource.signIn(
          email: 'a@a.com',
          password: '123456',
        )).called(1);
  });

  test('recoverPassword chama datasource remoto', () async {
    when(() => authRemoteDataSource.sendPasswordResetEmail(
          email: any(named: 'email'),
        ))
        .thenAnswer((_) async {});

    await repository.recoverPassword(email: 'a@a.com');

    verify(() => authRemoteDataSource.sendPasswordResetEmail(email: 'a@a.com'))
        .called(1);
  });

  test('signOut chama datasource remoto', () async {
    when(() => authRemoteDataSource.signOut()).thenAnswer((_) async {});

    await repository.signOut();

    verify(() => authRemoteDataSource.signOut()).called(1);
  });

  test('signUp chama auth remoto e cria perfil', () async {
    final credential = _MockUserCredential();
    final user = _MockUser();
    when(() => authRemoteDataSource.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => credential);
    when(() => credential.user).thenReturn(user);
    when(() => user.uid).thenReturn('uid-1');
    when(() => userProfileRemoteDataSource.createProfile(
          uid: any(named: 'uid'),
          name: any(named: 'name'),
          email: any(named: 'email'),
        )).thenAnswer((_) async {});

    await repository.signUp(
      name: 'Ana',
      email: 'a@a.com',
      password: '123456',
    );

    verify(() => authRemoteDataSource.signUp(
          email: 'a@a.com',
          password: '123456',
        )).called(1);
    verify(
      () => userProfileRemoteDataSource.createProfile(
        uid: 'uid-1',
        name: 'Ana',
        email: 'a@a.com',
      ),
    ).called(1);
    verify(() => userProfileLocalDataSource.cacheProfile(any())).called(1);
  });

  test('signUp com not-found remove usuario e lanca AuthFailure', () async {
    final credential = _MockUserCredential();
    final user = _MockUser();
    when(() => authRemoteDataSource.signUp(
          email: any(named: 'email'),
          password: any(named: 'password'),
        )).thenAnswer((_) async => credential);
    when(() => credential.user).thenReturn(user);
    when(() => user.uid).thenReturn('uid-1');
    when(() => userProfileRemoteDataSource.createProfile(
          uid: any(named: 'uid'),
          name: any(named: 'name'),
          email: any(named: 'email'),
        )).thenThrow(
          const DataFailure(
            message: 'Banco de dados do Firestore nao encontrado',
            code: 'not-found',
          ),
        );
    when(() => authRemoteDataSource.deleteCurrentUser()).thenAnswer((_) async {});

    await expectLater(
      () => repository.signUp(
        name: 'Ana',
        email: 'a@a.com',
        password: '123456',
      ),
      throwsA(
        isA<AuthFailure>()
            .having((failure) => failure.code, 'code', 'not-found'),
      ),
    );

    verify(() => authRemoteDataSource.deleteCurrentUser()).called(1);
    verifyNever(() => userProfileLocalDataSource.cacheProfile(any()));
  });

  test('getCurrentUser usa cache local em falha remota', () async {
    final user = _MockUser();
    when(() => authRemoteDataSource.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('uid-1');
    when(() => user.email).thenReturn('a@a.com');
    when(() => userProfileRemoteDataSource.getProfile(uid: any(named: 'uid')))
        .thenThrow(const DataFailure(message: 'offline'));
    when(() => userProfileLocalDataSource.getCachedProfile()).thenAnswer(
      (_) async => const AppUser(uid: 'uid-1', email: 'a@a.com', name: 'Ana'),
    );

    final result = await repository.getCurrentUser();

    expect(result, const AppUser(uid: 'uid-1', email: 'a@a.com', name: 'Ana'));
  });
}
