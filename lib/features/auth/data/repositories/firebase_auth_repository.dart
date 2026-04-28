import 'package:mamba_fast_tracker/core/error/failure.dart';
import 'package:mamba_fast_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:mamba_fast_tracker/features/auth/data/datasources/user_profile_local_data_source.dart';
import 'package:mamba_fast_tracker/features/auth/data/datasources/user_profile_remote_data_source.dart';
import 'package:mamba_fast_tracker/features/auth/domain/entities/app_user.dart';
import 'package:mamba_fast_tracker/features/auth/domain/repositories/auth_repository.dart';

class FirebaseAuthRepository implements AuthRepository {
  FirebaseAuthRepository({
    required AuthRemoteDataSource authRemoteDataSource,
    required UserProfileRemoteDataSource userProfileRemoteDataSource,
    required UserProfileLocalDataSource userProfileLocalDataSource,
  })  : _authRemoteDataSource = authRemoteDataSource,
        _userProfileRemoteDataSource = userProfileRemoteDataSource,
        _userProfileLocalDataSource = userProfileLocalDataSource;

  final AuthRemoteDataSource _authRemoteDataSource;
  final UserProfileRemoteDataSource _userProfileRemoteDataSource;
  final UserProfileLocalDataSource _userProfileLocalDataSource;

  AuthFailure _mapSignUpFailure(DataFailure failure) {
    switch (failure.code) {
      case 'permission-denied':
        return const AuthFailure(
          message: 'Sem permissão para salvar perfil do usuário',
          code: 'permission-denied',
        );
      case 'not-found':
        return const AuthFailure(
          message: 'Banco de dados do Firestore não encontrado',
          code: 'not-found',
        );
      case 'unavailable':
        return const AuthFailure(
          message: 'Serviço indisponível. Tente novamente em instantes',
          code: 'unavailable',
        );
      default:
        return AuthFailure(
          message: failure.message,
          code: failure.code,
        );
    }
  }

  Future<void> _deleteCurrentUserSafely() async {
    try {
      await _authRemoteDataSource.deleteCurrentUser();
    } on Failure catch (_) {
      return;
    }
  }

  @override
  Stream<AuthStatus> authStatusChanges() {
    return _authRemoteDataSource.authStateChanges().map(
          (user) =>
              user == null ? AuthStatus.unauthenticated : AuthStatus.authenticated,
        );
  }

  @override
  Future<AppUser?> getCurrentUser() async {
    final user = _authRemoteDataSource.currentUser;
    if (user == null) return null;
    try {
      final data = await _userProfileRemoteDataSource.getProfile(uid: user.uid);
      final appUser = AppUser(
        uid: user.uid,
        email: user.email ?? '',
        name: data?['name'] as String? ?? '',
      );
      await _userProfileLocalDataSource.cacheProfile(appUser);
      return appUser;
    } on Failure {
      return _userProfileLocalDataSource.getCachedProfile();
    }
  }

  @override
  Future<void> signIn({
    required String email,
    required String password,
  }) async {
    await _authRemoteDataSource.signIn(
      email: email,
      password: password,
    );
  }

  @override
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  }) async {
    final normalizedName = name.trim();
    final normalizedEmail = email.trim();
    final credential = await _authRemoteDataSource.signUp(
      email: normalizedEmail,
      password: password,
    );
    final user = credential.user;
    if (user == null) {
      throw const AuthFailure(
        message: 'Usuario nao criado no Firebase Auth',
        code: 'user-not-created',
      );
    }
    final appUser = AppUser(
      uid: user.uid,
      email: normalizedEmail,
      name: normalizedName,
    );
    try {
      await _userProfileRemoteDataSource.createProfile(
        uid: user.uid,
        name: normalizedName,
        email: normalizedEmail,
      );
      await _userProfileLocalDataSource.cacheProfile(appUser);
    } on DataFailure catch (e) {
      await _deleteCurrentUserSafely();
      throw _mapSignUpFailure(e);
    } on Failure {
      await _deleteCurrentUserSafely();
      rethrow;
    }
  }

  @override
  Future<void> recoverPassword({required String email}) async {
    await _authRemoteDataSource.sendPasswordResetEmail(email: email);
  }

  @override
  Future<void> signOut() async {
    await _authRemoteDataSource.signOut();
  }
}
