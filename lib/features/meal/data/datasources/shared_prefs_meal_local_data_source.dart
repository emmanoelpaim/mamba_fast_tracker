import 'dart:convert';

import 'package:mamba_fast_tracker/features/meal/data/datasources/meal_local_data_source.dart';
import 'package:mamba_fast_tracker/features/meal/domain/entities/meal_entry.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsMealLocalDataSource implements MealLocalDataSource {
  SharedPrefsMealLocalDataSource(this._preferences);

  final SharedPreferences _preferences;

  String _mealsKey(String uid) => 'meals_$uid';

  @override
  Future<List<MealEntry>> getMeals({required String uid}) async {
    final raw = _preferences.getString(_mealsKey(uid));
    if (raw == null || raw.isEmpty) return const [];
    final decoded = jsonDecode(raw);
    if (decoded is! List) return const [];
    return decoded
        .whereType<Map>()
        .map((item) => MealEntry.fromMap(Map<String, dynamic>.from(item)))
        .toList(growable: false);
  }

  @override
  Future<void> saveMeals({
    required String uid,
    required List<MealEntry> meals,
  }) async {
    final encoded = jsonEncode(meals.map((meal) => meal.toMap()).toList());
    await _preferences.setString(_mealsKey(uid), encoded);
  }
}
