import 'package:mamba_fast_tracker/features/goals/domain/entities/daily_goals.dart';

abstract class GoalsLocalDataSource {
  Future<DailyGoals?> getGoals({required String uid});
  Future<void> saveGoals({required String uid, required DailyGoals goals});
}
