import 'package:flutter_test/flutter_test.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/entities/fasting_day_history_entry.dart';
import 'package:mamba_fast_tracker/features/home/domain/entities/history_day_summary.dart';
import 'package:mamba_fast_tracker/features/home/domain/services/history_day_summary_builder.dart';
import 'package:mamba_fast_tracker/features/meal/domain/entities/meal_entry.dart';

void main() {
  const builder = HistoryDaySummaryBuilder();

  test('combina refeições por dia com histórico de jejum real', () {
    final now = DateTime(2026, 4, 29, 12);
    final meals = [
      MealEntry(
        id: 'm1',
        name: 'Cafe',
        calories: 400,
        createdAtUtc: DateTime.utc(2026, 4, 28, 11),
      ),
      MealEntry(
        id: 'm2',
        name: 'Almoco',
        calories: 700,
        createdAtUtc: DateTime.utc(2026, 4, 28, 15),
      ),
      MealEntry(
        id: 'm3',
        name: 'Janta',
        calories: 650,
        createdAtUtc: DateTime.utc(2026, 4, 27, 20),
      ),
      MealEntry(
        id: 'm4',
        name: 'Hoje',
        calories: 500,
        createdAtUtc: DateTime.utc(2026, 4, 29, 9),
      ),
    ];
    final fastingHistory = [
      FastingDayHistoryEntry(
        id: 'f1',
        startedAtUtc: DateTime.utc(2026, 4, 27, 20),
        endedAtUtc: DateTime.utc(2026, 4, 28, 12),
        elapsedSeconds: const Duration(hours: 16).inSeconds,
        status: FastingDayHistoryStatus.completed,
      ),
      FastingDayHistoryEntry(
        id: 'f2',
        startedAtUtc: DateTime.utc(2026, 4, 26, 21),
        endedAtUtc: DateTime.utc(2026, 4, 27, 7),
        elapsedSeconds: const Duration(hours: 10).inSeconds,
        status: FastingDayHistoryStatus.interrupted,
      ),
    ];

    final result = builder.build(
      meals: meals,
      fastingHistory: fastingHistory,
      caloriesGoal: 1200,
      fastingGoalHours: 16,
      now: now,
    );

    expect(result.length, 3);
    expect(result[0].day, DateTime(2026, 4, 29));
    expect(result[0].totalCalories, 500);
    expect(result[0].fastingStatusLabel, 'Sem dados');
    expect(result[1].day, DateTime(2026, 4, 28));
    expect(result[1].totalCalories, 1100);
    expect(result[1].caloriesStatusLabel, 'Dentro da meta');
    expect(result[1].fastingStatusLabel, 'Dentro da meta');
    expect(result[1].fastingElapsed, const Duration(hours: 16));
    expect(result[2].day, DateTime(2026, 4, 27));
    expect(result[2].totalCalories, 650);
    expect(result[2].fastingStatusLabel, 'Fora da meta');
  });

  test('retorna status sem dados quando dia não possui jejum salvo', () {
    final now = DateTime(2026, 4, 29, 12);
    final meals = [
      MealEntry(
        id: 'm1',
        name: 'Cafe',
        calories: 300,
        createdAtUtc: DateTime.utc(2026, 4, 28, 8),
      ),
    ];

    final result = builder.build(
      meals: meals,
      fastingHistory: const [],
      caloriesGoal: 200,
      fastingGoalHours: 16,
      now: now,
    );

    expect(result.length, 1);
    expect(result[0].caloriesStatusLabel, 'Fora da meta');
    expect(result[0].fastingStatusLabel, 'Sem dados');
    expect(result[0].fastingElapsed, isNull);
  });

  test('filtra período de 7 dias corretamente', () {
    final now = DateTime(2026, 4, 29, 12);
    final items = [
      _summary(DateTime(2026, 4, 28)),
      _summary(DateTime(2026, 4, 23)),
      _summary(DateTime(2026, 4, 20)),
    ];

    final filtered = builder.filterByPeriod(
      items: items,
      period: HistoryPeriod.days7,
      now: now,
    );

    expect(filtered.length, 2);
    expect(filtered.map((item) => item.day), [
      DateTime(2026, 4, 28),
      DateTime(2026, 4, 23),
    ]);
  });

  test('filtra período de 30 dias corretamente', () {
    final now = DateTime(2026, 4, 29, 12);
    final items = [
      _summary(DateTime(2026, 4, 28)),
      _summary(DateTime(2026, 4, 2)),
      _summary(DateTime(2026, 3, 15)),
      _summary(DateTime(2026, 3, 1)),
    ];

    final filtered = builder.filterByPeriod(
      items: items,
      period: HistoryPeriod.days30,
      now: now,
    );

    expect(filtered.length, 2);
    expect(filtered.map((item) => item.day), [
      DateTime(2026, 4, 28),
      DateTime(2026, 4, 2),
    ]);
  });

  test('período tudo retorna todos os itens sem filtrar', () {
    final now = DateTime(2026, 4, 29, 12);
    final items = [
      _summary(DateTime(2026, 4, 28)),
      _summary(DateTime(2026, 1, 10)),
    ];

    final filtered = builder.filterByPeriod(
      items: items,
      period: HistoryPeriod.all,
      now: now,
    );

    expect(filtered, items);
  });

  test('prioriza a primeira entrada de jejum no mesmo dia', () {
    final now = DateTime(2026, 4, 29, 12);
    final meals = [
      MealEntry(
        id: 'm1',
        name: 'Cafe',
        calories: 350,
        createdAtUtc: DateTime.utc(2026, 4, 28, 9),
      ),
    ];
    final fastingHistory = [
      FastingDayHistoryEntry(
        id: 'first',
        startedAtUtc: DateTime.utc(2026, 4, 27, 19),
        endedAtUtc: DateTime.utc(2026, 4, 28, 10),
        elapsedSeconds: const Duration(hours: 15).inSeconds,
        status: FastingDayHistoryStatus.interrupted,
      ),
      FastingDayHistoryEntry(
        id: 'second',
        startedAtUtc: DateTime.utc(2026, 4, 27, 18),
        endedAtUtc: DateTime.utc(2026, 4, 28, 12),
        elapsedSeconds: const Duration(hours: 18).inSeconds,
        status: FastingDayHistoryStatus.completed,
      ),
    ];

    final result = builder.build(
      meals: meals,
      fastingHistory: fastingHistory,
      caloriesGoal: 1000,
      fastingGoalHours: 16,
      now: now,
    );

    expect(result.length, 1);
    expect(result[0].fastingElapsed, const Duration(hours: 15));
    expect(result[0].fastingStatusLabel, 'Fora da meta');
  });

  test('ignora entradas seguintes no mesmo dia quando já mapeado', () {
    final now = DateTime(2026, 4, 29, 12);
    final meals = [
      MealEntry(
        id: 'm1',
        name: 'Almoco',
        calories: 500,
        createdAtUtc: DateTime.utc(2026, 4, 28, 13),
      ),
    ];
    final fastingHistory = [
      FastingDayHistoryEntry(
        id: 'first',
        startedAtUtc: DateTime.utc(2026, 4, 27, 20),
        endedAtUtc: DateTime.utc(2026, 4, 28, 11),
        elapsedSeconds: const Duration(hours: 16).inSeconds,
        status: FastingDayHistoryStatus.completed,
      ),
      FastingDayHistoryEntry(
        id: 'later',
        startedAtUtc: DateTime.utc(2026, 4, 28, 0),
        endedAtUtc: DateTime.utc(2026, 4, 28, 22),
        elapsedSeconds: const Duration(hours: 6).inSeconds,
        status: FastingDayHistoryStatus.interrupted,
      ),
    ];

    final result = builder.build(
      meals: meals,
      fastingHistory: fastingHistory,
      caloriesGoal: 1000,
      fastingGoalHours: 16,
      now: now,
    );

    expect(result.length, 1);
    expect(result[0].fastingElapsed, const Duration(hours: 16));
    expect(result[0].fastingStatusLabel, 'Dentro da meta');
  });

  test('inclui dia com histórico de jejum mesmo sem refeições', () {
    final now = DateTime(2026, 4, 29, 12);
    final fastingHistory = [
      FastingDayHistoryEntry(
        id: 'f1',
        startedAtUtc: DateTime.utc(2026, 4, 27, 20),
        endedAtUtc: DateTime.utc(2026, 4, 28, 12),
        elapsedSeconds: const Duration(hours: 16).inSeconds,
        status: FastingDayHistoryStatus.completed,
      ),
    ];

    final result = builder.build(
      meals: const [],
      fastingHistory: fastingHistory,
      caloriesGoal: 1200,
      fastingGoalHours: 16,
      now: now,
    );

    expect(result.length, 1);
    expect(result[0].day, DateTime(2026, 4, 28));
    expect(result[0].totalCalories, 0);
    expect(result[0].meals, isEmpty);
    expect(result[0].fastingStatusLabel, 'Dentro da meta');
    expect(result[0].fastingElapsed, const Duration(hours: 16));
  });
}

HistoryDaySummary _summary(DateTime day) {
  return HistoryDaySummary(
    day: day,
    meals: const [],
    totalCalories: 0,
    caloriesGoal: 2000,
    caloriesStatusLabel: 'Dentro da meta',
    fastingGoalHours: 16,
    fastingElapsed: null,
    fastingStatusLabel: 'Sem dados',
  );
}
