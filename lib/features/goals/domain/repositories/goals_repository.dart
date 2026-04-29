import 'package:mamba_fast_tracker/features/goals/domain/entities/daily_goals.dart';
import 'package:mamba_fast_tracker/features/goals/domain/entities/goals_save_result.dart';

abstract class GoalsRepository {
  Future<DailyGoals> getGoals();
  Future<GoalsSaveResult> saveGoals(DailyGoals goals);
}
