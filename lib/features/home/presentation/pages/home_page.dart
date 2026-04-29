import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:mamba_fast_tracker/core/theme/theme_cubit.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:mamba_fast_tracker/features/fasting/presentation/bloc/fasting_bloc.dart';
import 'package:mamba_fast_tracker/features/fasting/presentation/bloc/fasting_event.dart';
import 'package:mamba_fast_tracker/features/fasting/presentation/bloc/fasting_state.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/entities/fasting_session.dart';
import 'package:mamba_fast_tracker/features/fasting/presentation/pages/fasting_page.dart';
import 'package:mamba_fast_tracker/features/goals/presentation/cubit/goals_cubit.dart';
import 'package:mamba_fast_tracker/features/goals/presentation/cubit/goals_state.dart';
import 'package:mamba_fast_tracker/features/home/domain/entities/history_day_summary.dart';
import 'package:mamba_fast_tracker/features/home/domain/services/history_day_summary_builder.dart';
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

class _HomePageState extends State<HomePage> {
  var _currentIndex = 2;
  var _historyPeriod = HistoryPeriod.days7;
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
                      return _buildHistoryPeriodFilter();
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
