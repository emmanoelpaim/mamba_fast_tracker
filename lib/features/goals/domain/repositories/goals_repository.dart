import 'package:mamba_fast_tracker/features/goals/domain/entities/daily_goals.dart';

abstract class GoalsRepository {
  Future<DailyGoals> getGoals();
  Future<DailyGoals> saveGoals(DailyGoals goals);
}
