import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mamba_fast_tracker/core/theme/theme_cubit.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:mamba_fast_tracker/features/fasting/presentation/bloc/fasting_bloc.dart';
import 'package:mamba_fast_tracker/features/fasting/presentation/bloc/fasting_event.dart';
import 'package:mamba_fast_tracker/features/fasting/presentation/bloc/fasting_state.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/entities/fasting_session.dart';
import 'package:mamba_fast_tracker/features/fasting/presentation/pages/fasting_page.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/entities/fasting_day_history_entry.dart';
import 'package:mamba_fast_tracker/features/goals/presentation/cubit/goals_cubit.dart';
import 'package:mamba_fast_tracker/features/goals/presentation/cubit/goals_state.dart';
import 'package:mamba_fast_tracker/features/home/domain/entities/history_day_summary.dart';
import 'package:mamba_fast_tracker/features/home/domain/services/history_day_summary_builder.dart';
import 'package:mamba_fast_tracker/features/meal/domain/entities/meal_entry.dart';
import 'package:mamba_fast_tracker/features/meal/presentation/bloc/meal_bloc.dart';
import 'package:mamba_fast_tracker/features/meal/presentation/bloc/meal_event.dart';
import 'package:mamba_fast_tracker/features/meal/presentation/bloc/meal_state.dart';
import 'package:mamba_fast_tracker/features/meal/presentation/pages/meal_page.dart';

class HomePage extends StatefulWidget {
  const HomePage({required this.enableDarkModeMenu, super.key});

  final bool enableDarkModeMenu;

  @override
  State<HomePage> createState() => _HomePageState();
}

enum WeeklyChartMetric { calories, fasting }

class _HomePageState extends State<HomePage> {
  var _currentIndex = 2;
  var _historyPeriod = HistoryPeriod.days7;
  var _weeklyChartMetric = WeeklyChartMetric.calories;
  var _historyChartMetric = WeeklyChartMetric.calories;
  final _historySummaryBuilder = const HistoryDaySummaryBuilder();
  late final TextEditingController _caloriesGoalController;
  late final TextEditingController _fastingGoalController;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _caloriesGoalController = TextEditingController();
    _fastingGoalController = TextEditingController();
    _pageController = PageController(initialPage: _currentIndex);
    context.read<MealBloc>().add(const MealInitialized());
    context.read<FastingBloc>().add(const FastingInitialized());
    context.read<GoalsCubit>().load();
  }

  @override
  void dispose() {
    _caloriesGoalController.dispose();
    _fastingGoalController.dispose();
    _pageController.dispose();
    super.dispose();
  }

  static const _titles = [
    'Configuração',
    'Jejum',
    'Início',
    'Registro de refeições',
    'Histórico',
  ];

  Widget _buildSettingsTab(BuildContext context) {
    return BlocConsumer<GoalsCubit, GoalsState>(
      listener: (context, state) {
        final caloriesText = state.goals.caloriesGoal.toString();
        final fastingText = state.goals.fastingHoursGoal.toString();
        if (_caloriesGoalController.text != caloriesText) {
          _caloriesGoalController.text = caloriesText;
        }
        if (_fastingGoalController.text != fastingText) {
          _fastingGoalController.text = fastingText;
        }
      },
      builder: (context, goalsState) {
        return Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              Expanded(
                child: ListView(
                  children: [
                    if (widget.enableDarkModeMenu) ...[
                      BlocBuilder<ThemeCubit, ThemeMode>(
                        builder: (context, themeMode) {
                          return DropdownButtonFormField<ThemeMode>(
                            initialValue: themeMode,
                            decoration: const InputDecoration(
                              labelText: 'Tema do app',
                              border: OutlineInputBorder(),
                            ),
                            onChanged: (mode) {
                              if (mode == null) return;
                              context.read<ThemeCubit>().setThemeMode(mode);
                            },
                            items: const [
                              DropdownMenuItem(
                                value: ThemeMode.system,
                                child: Text('Sistema'),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.light,
                                child: Text('Claro'),
                              ),
                              DropdownMenuItem(
                                value: ThemeMode.dark,
                                child: Text('Escuro'),
                              ),
                            ],
                          );
                        },
                      ),
                      const SizedBox(height: 16),
                    ],
                    Text(
                      'Metas diárias',
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _caloriesGoalController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Meta de calorias (kcal)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: _fastingGoalController,
                      keyboardType: TextInputType.number,
                      inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                      decoration: const InputDecoration(
                        labelText: 'Meta de jejum (horas)',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          final calories = int.tryParse(
                            _caloriesGoalController.text.trim(),
                          );
                          final fastingHours = int.tryParse(
                            _fastingGoalController.text.trim(),
                          );
                          if (calories == null ||
                              fastingHours == null ||
                              calories < 1 ||
                              fastingHours < 1) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Informe metas válidas'),
                              ),
                            );
                            return;
                          }
                          context.read<GoalsCubit>().save(
                            caloriesGoal: calories,
                            fastingHoursGoal: fastingHours,
                          );
                        },
                        child: const Text('Salvar metas'),
                      ),
                    ),
                    if (goalsState.errorMessage.isNotEmpty) ...[
                      const SizedBox(height: 8),
                      Text(
                        goalsState.errorMessage,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 12),
              SafeArea(
                top: false,
                child: SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    onPressed: () => context.read<AuthBloc>().add(
                      const AuthLogoutRequested(),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.error,
                      foregroundColor: Theme.of(context).colorScheme.onError,
                    ),
                    icon: const Icon(Icons.logout),
                    label: const Text('Sair'),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildHistoryTab() {
    return BlocBuilder<GoalsCubit, GoalsState>(
      builder: (context, goalsState) {
        return BlocBuilder<MealBloc, MealState>(
          builder: (context, mealState) {
            return BlocBuilder<FastingBloc, FastingState>(
              builder: (context, fastingState) {
                final today = DateTime.now();
                final todayDay = DateTime(today.year, today.month, today.day);
                final summaries = _historySummaryBuilder.build(
                  meals: mealState.meals,
                  fastingHistory: fastingState.history,
                  caloriesGoal: goalsState.goals.caloriesGoal,
                  fastingGoalHours: goalsState.goals.fastingHoursGoal,
                  now: DateTime.now(),
                );
                final filtered = _historySummaryBuilder.filterByPeriod(
                  items: summaries,
                  period: _historyPeriod,
                  now: DateTime.now(),
                );
                var visibleSummaries = filtered;
                final hasActiveFasting =
                    fastingState.session.status == FastingSessionStatus.running ||
                    fastingState.session.status == FastingSessionStatus.paused;
                if (hasActiveFasting) {
                  final todayMeals = mealState.meals
                      .where((meal) {
                        final local = meal.createdAtUtc.toLocal();
                        return local.year == todayDay.year &&
                            local.month == todayDay.month &&
                            local.day == todayDay.day;
                      })
                      .toList()
                    ..sort((a, b) => a.createdAtUtc.compareTo(b.createdAtUtc));
                  final todayCalories = todayMeals.fold<int>(
                    0,
                    (sum, meal) => sum + meal.calories,
                  );
                  final todaySummary = HistoryDaySummary(
                    day: todayDay,
                    meals: todayMeals,
                    totalCalories: todayCalories,
                    caloriesGoal: goalsState.goals.caloriesGoal,
                    caloriesStatusLabel: todayCalories <= goalsState.goals.caloriesGoal
                        ? 'Dentro da meta'
                        : 'Fora da meta',
                    fastingGoalHours: goalsState.goals.fastingHoursGoal,
                    fastingElapsed: fastingState.elapsed,
                    fastingStatusLabel: 'Em andamento',
                  );
                  visibleSummaries = [
                    todaySummary,
                    ...visibleSummaries.where((item) => item.day != todayDay),
                  ];
                }
                if (visibleSummaries.isEmpty) {
                  return const Center(
                    child: Text('Sem dias registrados'),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: visibleSummaries.length + 1,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    if (index == 0) {
                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildHistoryPeriodFilter(),
                          const SizedBox(height: 10),
                          _buildHistoryChartCard(
                            context: context,
                            summaries: visibleSummaries,
                            period: _historyPeriod,
                            now: DateTime.now(),
                            metric: _historyChartMetric,
                            onMetricChanged: (metric) {
                              setState(() {
                                _historyChartMetric = metric;
                              });
                            },
                          ),
                        ],
                      );
                    }
                    final summary = visibleSummaries[index - 1];
                    final caloriesProgress = summary.caloriesGoal == 0
                        ? 0.0
                        : (summary.totalCalories / summary.caloriesGoal)
                              .clamp(0, 1)
                              .toDouble();
                    final fastingProgress =
                        summary.fastingElapsed != null &&
                            summary.fastingGoalHours > 0
                        ? (summary.fastingElapsed!.inMinutes /
                                  (summary.fastingGoalHours * 60))
                              .clamp(0, 1)
                              .toDouble()
                        : 0.0;
                    final fastingStatusText = summary.fastingElapsed == null
                        ? 'Jejum: sem dados'
                        : summary.fastingStatusLabel == 'Em andamento'
                        ? 'Jejum: Em andamento • ${_formatDuration(summary.fastingElapsed!)}'
                        : 'Jejum: ${_formatDuration(summary.fastingElapsed!)} • ${summary.fastingStatusLabel}';
                    final fastingColor = _statusColor(
                      context,
                      summary.fastingStatusLabel,
                    );
                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: () {
                          _showDaySummary(
                            context: context,
                            summary: summary,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      _formatDay(summary.day),
                                      style: Theme.of(
                                        context,
                                      ).textTheme.titleMedium,
                                    ),
                                  ),
                                  _statusBadge(
                                    label: summary.caloriesStatusLabel,
                                    color: _statusColor(
                                      context,
                                      summary.caloriesStatusLabel,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              Text(
                                '${summary.meals.length} refeição(ões) • ${summary.totalCalories} kcal',
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Evolução calorias',
                                style: Theme.of(context).textTheme.bodySmall,
                              ),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(value: caloriesProgress),
                              const SizedBox(height: 10),
                              Row(
                                children: [
                                  Expanded(
                                    child: Text(
                                      fastingStatusText,
                                      style: Theme.of(
                                        context,
                                      ).textTheme.bodySmall,
                                    ),
                                  ),
                                  _statusBadge(
                                    label: summary.fastingStatusLabel,
                                    color: fastingColor,
                                  ),
                                ],
                              ),
                              const SizedBox(height: 6),
                              LinearProgressIndicator(value: fastingProgress),
                            ],
                          ),
                        ),
                      ),
                    );
                  },
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildHistoryPeriodFilter() {
    return SegmentedButton<HistoryPeriod>(
      segments: const [
        ButtonSegment<HistoryPeriod>(
          value: HistoryPeriod.days7,
          label: Text('7 dias'),
        ),
        ButtonSegment<HistoryPeriod>(
          value: HistoryPeriod.days30,
          label: Text('30 dias'),
        ),
        ButtonSegment<HistoryPeriod>(
          value: HistoryPeriod.all,
          label: Text('Tudo'),
        ),
      ],
      selected: {_historyPeriod},
      onSelectionChanged: (selection) {
        setState(() {
          _historyPeriod = selection.first;
        });
      },
    );
  }

  Widget _buildHistoryChartCard({
    required BuildContext context,
    required List<HistoryDaySummary> summaries,
    required HistoryPeriod period,
    required DateTime now,
    required WeeklyChartMetric metric,
    required ValueChanged<WeeklyChartMetric> onMetricChanged,
  }) {
    final chartDays = _buildHistoryChartDays(period: period, now: now);
    final summaryByDay = <DateTime, HistoryDaySummary>{
      for (final item in summaries)
        DateTime(item.day.year, item.day.month, item.day.day): item,
    };
    final values = chartDays.map((day) {
      final summary = summaryByDay[day];
      if (summary == null) return 0.0;
      if (metric == WeeklyChartMetric.calories) {
        return summary.totalCalories.toDouble();
      }
      if (summary.fastingElapsed == null) return 0.0;
      return summary.fastingElapsed!.inMinutes / 60;
    }).toList();
    final labels = chartDays
        .map((day) => day.day.toString().padLeft(2, '0'))
        .toList();
    final tooltipLabels = chartDays
        .map(
          (day) =>
              '${day.day.toString().padLeft(2, '0')}/${day.month.toString().padLeft(2, '0')}',
        )
        .toList();
    final maxValue = values.fold<double>(
      0,
      (current, value) => value > current ? value : current,
    );
    final upperBound = maxValue <= 0 ? 1.0 : maxValue * 1.2;
    final yInterval = _weeklyYAxisInterval(
      upperBound: upperBound,
      metric: metric,
    );
    final metricLabel = metric == WeeklyChartMetric.calories
        ? 'Calorias por dia'
        : 'Horas de jejum por dia';
    final barColor = _metricColor(metric);
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gráfico do período',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 6),
            SegmentedButton<WeeklyChartMetric>(
              key: const Key('history_chart_toggle'),
              segments: const [
                ButtonSegment<WeeklyChartMetric>(
                  value: WeeklyChartMetric.calories,
                  label: Text('Calorias'),
                ),
                ButtonSegment<WeeklyChartMetric>(
                  value: WeeklyChartMetric.fasting,
                  label: Text('Jejum'),
                ),
              ],
              selected: {metric},
              onSelectionChanged: (selection) {
                onMetricChanged(selection.first);
              },
            ),
            const SizedBox(height: 8),
            Text(
              metricLabel,
              key: const Key('history_chart_metric_label'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: BarChart(
                swapAnimationDuration: const Duration(milliseconds: 250),
                swapAnimationCurve: Curves.easeOutCubic,
                BarChartData(
                  minY: 0,
                  maxY: upperBound,
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: _buildBarTouchData(
                    metric: metric,
                    labels: tooltipLabels,
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: yInterval,
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        interval: yInterval,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _weeklyYAxisLabel(
                              value: value,
                              metric: metric,
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= labels.length) {
                            return const SizedBox.shrink();
                          }
                          if (!_shouldShowHistoryBottomLabel(
                            index: index,
                            total: labels.length,
                          )) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            labels[index],
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: values.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value,
                          color: barColor,
                          width: 12,
                          borderRadius: BorderRadius.circular(4),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: upperBound,
                            color: barColor.withValues(alpha: 0.12),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDaySummary({
    required BuildContext context,
    required HistoryDaySummary summary,
  }) {
    showModalBottomSheet<void>(
      context: context,
      showDragHandle: true,
      builder: (sheetContext) {
        return SafeArea(
          child: ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Text(
                'Resumo de ${_formatDay(summary.day)}',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              const SizedBox(height: 12),
              _summaryCard(
                context: context,
                title: 'Calorias do dia',
                value: '${summary.totalCalories} kcal',
                subtitle: 'Meta: ${summary.caloriesGoal} kcal',
                progress: summary.caloriesGoal == 0
                    ? 0
                    : (summary.totalCalories / summary.caloriesGoal)
                          .clamp(0, 1)
                          .toDouble(),
              ),
              const SizedBox(height: 12),
              _summaryCard(
                context: context,
                title: 'Jejum estimado',
                value: summary.fastingElapsed == null
                    ? 'Sem dados'
                    : _formatDuration(summary.fastingElapsed!),
                subtitle:
                    'Meta: ${summary.fastingGoalHours}h • ${summary.fastingStatusLabel}',
                progress:
                    summary.fastingElapsed != null &&
                        summary.fastingGoalHours > 0
                    ? (summary.fastingElapsed!.inMinutes /
                              (summary.fastingGoalHours * 60))
                          .clamp(0, 1)
                          .toDouble()
                    : 0,
              ),
              const SizedBox(height: 12),
              Text(
                'Refeições',
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 8),
              ...summary.meals.map((meal) {
                final local = meal.createdAtUtc.toLocal();
                final hour = local.hour.toString().padLeft(2, '0');
                final minute = local.minute.toString().padLeft(2, '0');
                return Card(
                  child: ListTile(
                    title: Text(meal.name),
                    subtitle: Text('$hour:$minute'),
                    trailing: Text('${meal.calories} kcal'),
                  ),
                );
              }),
            ],
          ),
        );
      },
    );
  }

  String _formatDay(DateTime day) {
    final d = day.day.toString().padLeft(2, '0');
    final m = day.month.toString().padLeft(2, '0');
    final y = day.year.toString();
    return '$d/$m/$y';
  }

  Widget _buildHomeDashboard() {
    return BlocBuilder<GoalsCubit, GoalsState>(
      builder: (context, goalsState) {
        return BlocBuilder<MealBloc, MealState>(
          builder: (context, mealState) {
            return BlocBuilder<FastingBloc, FastingState>(
              builder: (context, fastingState) {
                final now = DateTime.now();
                final todayMeals = mealState.meals.where((meal) {
                  final local = meal.createdAtUtc.toLocal();
                  return local.year == now.year &&
                      local.month == now.month &&
                      local.day == now.day;
                });
                final totalCalories = todayMeals.fold<int>(
                  0,
                  (sum, meal) => sum + meal.calories,
                );
                final fastingElapsed = fastingState.elapsed;
                final caloriesGoal = goalsState.goals.caloriesGoal;
                final fastingGoal = Duration(
                  hours: goalsState.goals.fastingHoursGoal,
                );
                final caloriesProgress = caloriesGoal == 0
                    ? 0.0
                    : totalCalories / caloriesGoal;
                final fastingGoalSeconds = fastingGoal.inSeconds;
                final fastingProgress = fastingGoalSeconds == 0
                    ? 0.0
                    : fastingElapsed.inSeconds / fastingGoalSeconds;
                final status = _buildStatus(
                  calories: totalCalories,
                  caloriesGoal: caloriesGoal,
                  fastingElapsed: fastingElapsed,
                  fastingGoal: fastingGoal,
                );
                final statusColor = switch (status) {
                  'Dentro da meta' => Colors.green,
                  'Fora da meta' => Theme.of(context).colorScheme.error,
                  _ => Colors.amber,
                };
                final weeklyCalories = _buildWeeklyCaloriesSeries(
                  meals: mealState.meals,
                  now: now,
                );
                final weeklyFasting = _buildWeeklyFastingSeries(
                  history: fastingState.history,
                  now: now,
                );
                return ListView(
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text(
                      'Resumo de hoje',
                      style: Theme.of(context).textTheme.titleLarge,
                    ),
                    const SizedBox(height: 12),
                    _summaryCard(
                      context: context,
                      title: 'Calorias do dia',
                      value: '$totalCalories kcal',
                      subtitle: 'Meta: $caloriesGoal kcal',
                      progress: caloriesProgress.clamp(0, 1).toDouble(),
                    ),
                    const SizedBox(height: 12),
                    _summaryCard(
                      context: context,
                      title: 'Jejum total do dia',
                      value: _formatDuration(fastingElapsed),
                      subtitle: 'Meta: ${_formatDuration(fastingGoal)}',
                      progress: fastingProgress.clamp(0, 1).toDouble(),
                    ),
                    const SizedBox(height: 12),
                    _buildWeeklyChartCard(
                      context: context,
                      caloriesSeries: weeklyCalories,
                      fastingSeries: weeklyFasting,
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: ListTile(
                        title: const Text('Status diário'),
                        subtitle: const Text('Dentro/fora da meta'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: statusColor.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            status,
                            style: TextStyle(
                              color: statusColor,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildWeeklyChartCard({
    required BuildContext context,
    required List<double> caloriesSeries,
    required List<double> fastingSeries,
  }) {
    final values = _weeklyChartMetric == WeeklyChartMetric.calories
        ? caloriesSeries
        : fastingSeries;
    final metricLabel = _weeklyChartMetric == WeeklyChartMetric.calories
        ? 'kcal por dia'
        : 'horas por dia';
    final maxValue = values.fold<double>(
      0,
      (current, value) => value > current ? value : current,
    );
    final upperBound = maxValue <= 0 ? 1.0 : maxValue * 1.2;
    final yInterval = _weeklyYAxisInterval(
      upperBound: upperBound,
      metric: _weeklyChartMetric,
    );
    final barColor = _metricColor(_weeklyChartMetric);
    final labels = _buildWeeklyDayLabels(now: DateTime.now());
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Evolução semanal',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 12),
            SegmentedButton<WeeklyChartMetric>(
              key: const Key('weekly_chart_toggle'),
              segments: const [
                ButtonSegment<WeeklyChartMetric>(
                  value: WeeklyChartMetric.calories,
                  label: Text('Calorias'),
                ),
                ButtonSegment<WeeklyChartMetric>(
                  value: WeeklyChartMetric.fasting,
                  label: Text('Jejum'),
                ),
              ],
              selected: {_weeklyChartMetric},
              onSelectionChanged: (selection) {
                setState(() {
                  _weeklyChartMetric = selection.first;
                });
              },
            ),
            const SizedBox(height: 12),
            Text(
              metricLabel,
              key: const Key('weekly_chart_metric_label'),
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 180,
              child: BarChart(
                swapAnimationDuration: const Duration(milliseconds: 250),
                swapAnimationCurve: Curves.easeOutCubic,
                BarChartData(
                  minY: 0,
                  maxY: upperBound,
                  alignment: BarChartAlignment.spaceAround,
                  barTouchData: _buildBarTouchData(
                    metric: _weeklyChartMetric,
                    labels: labels,
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: yInterval,
                  ),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 34,
                        interval: yInterval,
                        getTitlesWidget: (value, meta) {
                          return Text(
                            _weeklyYAxisLabel(
                              value: value,
                              metric: _weeklyChartMetric,
                            ),
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 22,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= labels.length) {
                            return const SizedBox.shrink();
                          }
                          return Text(
                            labels[index],
                            style: Theme.of(context).textTheme.bodySmall,
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: values.asMap().entries.map((entry) {
                    return BarChartGroupData(
                      x: entry.key,
                      barRods: [
                        BarChartRodData(
                          toY: entry.value,
                          color: barColor,
                          width: 14,
                          borderRadius: BorderRadius.circular(4),
                          backDrawRodData: BackgroundBarChartRodData(
                            show: true,
                            toY: upperBound,
                            color: barColor.withValues(alpha: 0.12),
                          ),
                        ),
                      ],
                    );
                  }).toList(),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<double> _buildWeeklyCaloriesSeries({
    required List<MealEntry> meals,
    required DateTime now,
  }) {
    final base = DateTime(now.year, now.month, now.day);
    final weekStart = base.subtract(Duration(days: base.weekday % 7));
    final values = List<double>.filled(7, 0);
    for (final meal in meals) {
      final local = meal.createdAtUtc.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      final index = day.difference(weekStart).inDays;
      if (index < 0 || index >= 7) continue;
      values[index] += meal.calories.toDouble();
    }
    return values;
  }

  List<double> _buildWeeklyFastingSeries({
    required List<FastingDayHistoryEntry> history,
    required DateTime now,
  }) {
    final base = DateTime(now.year, now.month, now.day);
    final weekStart = base.subtract(Duration(days: base.weekday % 7));
    final values = List<double>.filled(7, 0);
    for (final item in history) {
      final local = item.endedAtUtc.toLocal();
      final day = DateTime(local.year, local.month, local.day);
      final index = day.difference(weekStart).inDays;
      if (index < 0 || index >= 7) continue;
      final hours = item.elapsedSeconds / 3600;
      if (hours > values[index]) {
        values[index] = hours;
      }
    }
    return values;
  }

  List<String> _buildWeeklyDayLabels({required DateTime now}) {
    return const ['D', 'S', 'T', 'Q', 'Q', 'S', 'S'];
  }

  List<DateTime> _buildHistoryChartDays({
    required HistoryPeriod period,
    required DateTime now,
  }) {
    final base = DateTime(now.year, now.month, now.day);
    final totalDays = switch (period) {
      HistoryPeriod.days7 => 7,
      HistoryPeriod.days30 => 30,
      HistoryPeriod.all => 30,
    };
    return List<DateTime>.generate(
      totalDays,
      (index) => base.subtract(Duration(days: totalDays - 1 - index)),
    );
  }

  bool _shouldShowHistoryBottomLabel({
    required int index,
    required int total,
  }) {
    if (total <= 7) return true;
    if (index == 0 || index == total - 1) return true;
    return index % 5 == 0;
  }

  double _weeklyYAxisInterval({
    required double upperBound,
    required WeeklyChartMetric metric,
  }) {
    if (metric == WeeklyChartMetric.calories) {
      if (upperBound <= 1000) return 500;
      if (upperBound <= 2000) return 1000;
      return 1500;
    }
    if (upperBound <= 8) return 4;
    if (upperBound <= 16) return 8;
    return 12;
  }

  String _weeklyYAxisLabel({
    required double value,
    required WeeklyChartMetric metric,
  }) {
    if (metric == WeeklyChartMetric.calories) {
      return value.toInt().toString();
    }
    return '${value.toInt()}h';
  }

  Color _metricColor(WeeklyChartMetric metric) {
    if (metric == WeeklyChartMetric.calories) {
      return Colors.blue;
    }
    return Colors.deepPurple;
  }

  BarTouchData _buildBarTouchData({
    required WeeklyChartMetric metric,
    required List<String> labels,
  }) {
    return BarTouchData(
      enabled: true,
      touchTooltipData: BarTouchTooltipData(
        getTooltipColor: (_) => Colors.black87,
        tooltipPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
        getTooltipItem: (group, groupIndex, rod, rodIndex) {
          final label = group.x >= 0 && group.x < labels.length
              ? labels[group.x]
              : '';
          final valueText = metric == WeeklyChartMetric.calories
              ? '${rod.toY.toStringAsFixed(0)} kcal'
              : '${rod.toY.toStringAsFixed(1)} h';
          return BarTooltipItem(
            '$label\n$valueText',
            const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w600,
            ),
          );
        },
      ),
    );
  }

  String _buildStatus({
    required int calories,
    required int caloriesGoal,
    required Duration fastingElapsed,
    required Duration fastingGoal,
  }) {
    if (calories > caloriesGoal) return 'Fora da meta';
    if (calories <= caloriesGoal && fastingElapsed >= fastingGoal) {
      return 'Dentro da meta';
    }
    return 'Parcial';
  }

  Widget _summaryCard({
    required BuildContext context,
    required String title,
    required String value,
    required String subtitle,
    required double progress,
  }) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(value, style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 6),
            Text(subtitle, style: Theme.of(context).textTheme.bodySmall),
            const SizedBox(height: 10),
            LinearProgressIndicator(value: progress),
          ],
        ),
      ),
    );
  }

  String _formatDuration(Duration value) {
    final hours = value.inHours.remainder(100).toString().padLeft(2, '0');
    final minutes = value.inMinutes.remainder(60).toString().padLeft(2, '0');
    return '${hours}h ${minutes}m';
  }

  Color _statusColor(BuildContext context, String status) {
    if (status == 'Dentro da meta') return Colors.green;
    if (status == 'Fora da meta') return Theme.of(context).colorScheme.error;
    return Colors.amber;
  }

  Widget _statusBadge({required String label, required Color color}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.w600),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tabs = [
      _buildSettingsTab(context),
      const FastingPage(),
      _buildHomeDashboard(),
      const MealPage(),
      _buildHistoryTab(),
    ];

    return Scaffold(
      appBar: AppBar(title: Text(_titles[_currentIndex])),
      body: PageView(
        controller: _pageController,
        onPageChanged: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        children: tabs,
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _currentIndex,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() {
            _currentIndex = index;
          });
          _pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 260),
            curve: Curves.easeOutCubic,
          );
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.settings_outlined),
            activeIcon: Icon(Icons.settings),
            label: 'Configuração',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.timer_outlined),
            activeIcon: Icon(Icons.timer),
            label: 'Jejum',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.restaurant_menu_outlined),
            activeIcon: Icon(Icons.restaurant_menu),
            label: 'Refeições',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.history_outlined),
            activeIcon: Icon(Icons.history),
            label: 'Histórico',
          ),
        ],
      ),
    );
  }
}
