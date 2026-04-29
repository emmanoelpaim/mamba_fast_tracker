import 'package:mamba_fast_tracker/features/goals/domain/entities/daily_goals.dart';

enum GoalsSaveStatus { savedRemote, savedPendingSync }

class GoalsSaveResult {
  const GoalsSaveResult({required this.goals, required this.status});

  final DailyGoals goals;
  final GoalsSaveStatus status;
}
