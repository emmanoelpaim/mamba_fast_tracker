import 'package:mamba_fast_tracker/features/fasting/domain/entities/fasting_day_history_entry.dart';
import 'package:mamba_fast_tracker/features/home/domain/entities/history_day_summary.dart';
import 'package:mamba_fast_tracker/features/meal/domain/entities/meal_entry.dart';

class HistoryDaySummaryBuilder {
  const HistoryDaySummaryBuilder();

  List<HistoryDaySummary> build({
    required List<MealEntry> meals,
    required List<FastingDayHistoryEntry> fastingHistory,
    required int caloriesGoal,
    required int fastingGoalHours,
    required DateTime now,
  }) {
    final grouped = <DateTime, List<MealEntry>>{};
    for (final meal in meals) {
      final local = meal.createdAtUtc.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      grouped.putIfAbsent(day, () => []).add(meal);
    }
    final fastingByDay = <DateTime, FastingDayHistoryEntry>{};
    for (final item in fastingHistory) {
      final localDay = item.endedAtUtc.toLocal();
      final day = DateTime(localDay.year, localDay.month, localDay.day);
      fastingByDay.putIfAbsent(day, () => item);
    }
    final summaries = <HistoryDaySummary>[];
    final days = {...grouped.keys, ...fastingByDay.keys}.toList()
      ..sort((a, b) => b.compareTo(a));
    for (final day in days) {
      final dayMeals = [...(grouped[day] ?? const <MealEntry>[])]
        ..sort((a, b) => a.createdAtUtc.compareTo(b.createdAtUtc));
      final totalCalories = dayMeals.fold<int>(
        0,
        (sum, meal) => sum + meal.calories,
      );
      final fastingItem = fastingByDay[day];
      final fastingElapsed = fastingItem?.elapsed;
      final fastingStatus = fastingItem == null
          ? 'Sem dados'
          : (fastingItem.status == FastingDayHistoryStatus.completed
                ? 'Dentro da meta'
                : 'Fora da meta');
      summaries.add(
        HistoryDaySummary(
          day: day,
          meals: dayMeals,
          totalCalories: totalCalories,
          caloriesGoal: caloriesGoal,
          caloriesStatusLabel: totalCalories <= caloriesGoal
              ? 'Dentro da meta'
              : 'Fora da meta',
          fastingGoalHours: fastingGoalHours,
          fastingElapsed: fastingElapsed,
          fastingStatusLabel: fastingStatus,
        ),
      );
    }
    return summaries;
  }

  List<HistoryDaySummary> filterByPeriod({
    required List<HistoryDaySummary> items,
    required HistoryPeriod period,
    required DateTime now,
  }) {
    if (period == HistoryPeriod.all) return items;
    final totalDays = period == HistoryPeriod.days7 ? 7 : 30;
    final base = DateTime(now.year, now.month, now.day);
    final limit = base.subtract(Duration(days: totalDays));
    return items.where((item) => item.day.isAfter(limit)).toList();
  }
}
