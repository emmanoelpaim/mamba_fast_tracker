import 'package:mamba_fast_tracker/features/meal/domain/entities/meal_entry.dart';

abstract class MealRemoteDataSource {
  Future<List<MealEntry>> getMeals({required String uid});
  Future<void> saveMeals({required String uid, required List<MealEntry> meals});
}
