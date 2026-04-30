import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mamba_fast_tracker/core/error/failure.dart';
import 'package:mamba_fast_tracker/features/auth/data/datasources/user_profile_remote_data_source.dart';

class FirebaseUserProfileRemoteDataSource
    implements UserProfileRemoteDataSource {
  FirebaseUserProfileRemoteDataSource(this._firebaseFirestore);

  final FirebaseFirestore _firebaseFirestore;

  @override
  Future<Map<String, dynamic>?> getProfile({required String uid}) async {
    try {
      final snapshot = await _firebaseFirestore
          .collection('users')
          .doc(uid)
          .get();
      return snapshot.data();
    } on FirebaseException catch (e) {
      throw DataFailure(
        message: e.message ?? 'Falha ao carregar perfil',
        code: e.code,
      );
    }
  }

  @override
  Future<void> createProfile({
    required String uid,
    required String name,
    required String email,
  }) async {
    try {
      await _firebaseFirestore.collection('users').doc(uid).set({
        'name': name.trim(),
        'email': email.trim(),
        'createdAt': FieldValue.serverTimestamp(),
      });
    } on FirebaseException catch (e) {
      final message = switch (e.code) {
        'permission-denied' => 'Sem permissao para salvar perfil no Firestore',
        'not-found' => 'Banco de dados do Firestore nao encontrado',
        'unavailable' => 'Servico do Firestore indisponivel',
        _ => e.message ?? 'Falha ao salvar perfil no Firestore',
      };
      throw DataFailure(message: message, code: e.code);
    }
  }
}
