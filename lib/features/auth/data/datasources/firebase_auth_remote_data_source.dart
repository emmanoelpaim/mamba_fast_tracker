import 'package:firebase_auth/firebase_auth.dart';
import 'package:mamba_fast_tracker/core/error/failure.dart';
import 'package:mamba_fast_tracker/features/auth/data/datasources/auth_remote_data_source.dart';

class FirebaseAuthRemoteDataSource implements AuthRemoteDataSource {
  FirebaseAuthRemoteDataSource(this._firebaseAuth);

  final FirebaseAuth _firebaseAuth;

  @override
  Stream<User?> authStateChanges() => _firebaseAuth.authStateChanges();

  @override
  User? get currentUser => _firebaseAuth.currentUser;

  @override
  Future<UserCredential> signIn({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(
        message: e.message ?? 'Falha ao autenticar',
        code: e.code,
      );
    }
  }

  @override
  Future<UserCredential> signUp({
    required String email,
    required String password,
  }) async {
    try {
      return await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(
        message: e.message ?? 'Falha ao cadastrar',
        code: e.code,
      );
    }
  }

  @override
  Future<void> sendPasswordResetEmail({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on FirebaseAuthException catch (e) {
      throw AuthFailure(
        message: e.message ?? 'Falha ao enviar recuperacao',
        code: e.code,
      );
    }
  }

  @override
  Future<void> signOut() async {
    await _firebaseAuth.signOut();
  }

  @override
  Future<void> deleteCurrentUser() async {
    await _firebaseAuth.currentUser?.delete();
  }
}
