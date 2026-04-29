import 'package:mamba_fast_tracker/features/meal/domain/entities/meal_entry.dart';

class HistoryDaySummary {
  const HistoryDaySummary({
    required this.day,
    required this.meals,
    required this.totalCalories,
    required this.caloriesGoal,
    required this.caloriesStatusLabel,
    required this.fastingGoalHours,
    required this.fastingElapsed,
    required this.fastingStatusLabel,
  });

  final DateTime day;
  final List<MealEntry> meals;
  final int totalCalories;
  final int caloriesGoal;
  final String caloriesStatusLabel;
  final int fastingGoalHours;
  final Duration? fastingElapsed;
  final String fastingStatusLabel;
}

enum HistoryPeriod { days7, days30, all }
