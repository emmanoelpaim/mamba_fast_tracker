import 'package:firebase_auth/firebase_auth.dart';

abstract class AuthRemoteDataSource {
  Stream<User?> authStateChanges();
  User? get currentUser;
  Future<UserCredential> signIn({
    required String email,
    required String password,
  });
  Future<UserCredential> signUp({
    required String email,
    required String password,
  });
  Future<void> sendPasswordResetEmail({required String email});
  Future<void> signOut();
  Future<void> deleteCurrentUser();
}
