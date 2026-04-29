import 'package:mamba_fast_tracker/features/meal/domain/entities/meal_entry.dart';

abstract class MealRepository {
  Future<List<MealEntry>> getMeals();
  Future<List<MealEntry>> saveMeal(MealEntry meal);
  Future<List<MealEntry>> updateMeal(MealEntry meal);
  Future<List<MealEntry>> deleteMeal(String id);
}
