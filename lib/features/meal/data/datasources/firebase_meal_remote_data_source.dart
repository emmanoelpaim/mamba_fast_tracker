import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mamba_fast_tracker/core/error/failure.dart';
import 'package:mamba_fast_tracker/features/meal/data/datasources/meal_remote_data_source.dart';
import 'package:mamba_fast_tracker/features/meal/domain/entities/meal_entry.dart';

class FirebaseMealRemoteDataSource implements MealRemoteDataSource {
  FirebaseMealRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<List<MealEntry>> getMeals({required String uid}) async {
    try {
      final snapshot = await _firestore.collection('users').doc(uid).get();
      final data = snapshot.data();
      if (data == null) return const [];
      final mealsRaw = data['meals'];
      if (mealsRaw is! List) return const [];
      return mealsRaw
          .whereType<Map>()
          .map((item) => MealEntry.fromMap(Map<String, dynamic>.from(item)))
          .toList(growable: false);
    } on FirebaseException catch (e) {
      throw DataFailure(
        message: e.message ?? 'Falha ao buscar refeições',
        code: e.code,
      );
    }
  }

  @override
  Future<void> saveMeals({
    required String uid,
    required List<MealEntry> meals,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'meals': meals.map((meal) => meal.toMap()).toList(),
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw DataFailure(
        message: e.message ?? 'Falha ao salvar refeições',
        code: e.code,
      );
    }
  }
}
