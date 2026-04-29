import 'dart:convert';

import 'package:mamba_fast_tracker/features/goals/data/datasources/goals_local_data_source.dart';
import 'package:mamba_fast_tracker/features/goals/domain/entities/daily_goals.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsGoalsLocalDataSource implements GoalsLocalDataSource {
  SharedPrefsGoalsLocalDataSource(this._preferences);

  final SharedPreferences _preferences;

  String _goalsKey(String uid) => 'daily_goals_$uid';

  @override
  Future<DailyGoals?> getGoals({required String uid}) async {
    final raw = _preferences.getString(_goalsKey(uid));
    if (raw == null || raw.isEmpty) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return DailyGoals.fromMap(map);
  }

  @override
  Future<void> saveGoals({
    required String uid,
    required DailyGoals goals,
  }) async {
    await _preferences.setString(_goalsKey(uid), jsonEncode(goals.toMap()));
  }
}
