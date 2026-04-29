import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mamba_fast_tracker/core/error/failure.dart';
import 'package:mamba_fast_tracker/features/goals/data/datasources/goals_remote_data_source.dart';
import 'package:mamba_fast_tracker/features/goals/domain/entities/daily_goals.dart';

class FirebaseGoalsRemoteDataSource implements GoalsRemoteDataSource {
  FirebaseGoalsRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<DailyGoals?> getGoals({required String uid}) async {
    try {
      final snapshot = await _firestore.collection('users').doc(uid).get();
      final data = snapshot.data();
      if (data == null) return null;
      final goalsRaw = data['dailyGoals'];
      final goalsMap = goalsRaw is Map
          ? Map<String, dynamic>.from(goalsRaw)
          : null;
      if (goalsMap == null) return null;
      return DailyGoals.fromMap(goalsMap);
    } on FirebaseException catch (e) {
      throw DataFailure(
        message: e.message ?? 'Falha ao buscar metas diárias',
        code: e.code,
      );
    }
  }

  @override
  Future<void> saveGoals({
    required String uid,
    required DailyGoals goals,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'dailyGoals': goals.toMap(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw DataFailure(
        message: e.message ?? 'Falha ao salvar metas diárias',
        code: e.code,
      );
    }
  }
}
