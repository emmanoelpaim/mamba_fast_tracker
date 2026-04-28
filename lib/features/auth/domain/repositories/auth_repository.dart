import 'package:mamba_fast_tracker/features/auth/domain/entities/app_user.dart';

enum AuthStatus { authenticated, unauthenticated }

abstract class AuthRepository {
  Stream<AuthStatus> authStatusChanges();
  Future<AppUser?> getCurrentUser();
  Future<void> signIn({
    required String email,
    required String password,
  });
  Future<void> signUp({
    required String name,
    required String email,
    required String password,
  });
  Future<void> recoverPassword({required String email});
  Future<void> signOut();
}
