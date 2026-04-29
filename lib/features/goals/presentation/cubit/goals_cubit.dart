import 'package:bloc/bloc.dart';
import 'package:mamba_fast_tracker/core/error/failure.dart';
import 'package:mamba_fast_tracker/features/goals/domain/entities/daily_goals.dart';
import 'package:mamba_fast_tracker/features/goals/domain/repositories/goals_repository.dart';
import 'package:mamba_fast_tracker/features/goals/presentation/cubit/goals_state.dart';

class GoalsCubit extends Cubit<GoalsState> {
  GoalsCubit({required GoalsRepository goalsRepository})
    : _goalsRepository = goalsRepository,
      super(GoalsState.initial());

  final GoalsRepository _goalsRepository;

  Future<void> load() async {
    emit(state.copyWith(isLoading: true, errorMessage: ''));
    try {
      final goals = await _goalsRepository.getGoals();
      emit(state.copyWith(isLoading: false, goals: goals));
    } on Failure catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    }
  }

  Future<void> save({
    required int caloriesGoal,
    required int fastingHoursGoal,
  }) async {
    final normalized = DailyGoals(
      caloriesGoal: caloriesGoal.clamp(1, 100000),
      fastingHoursGoal: fastingHoursGoal.clamp(1, 72),
    );
    try {
      final saved = await _goalsRepository.saveGoals(normalized);
      emit(state.copyWith(goals: saved, errorMessage: ''));
    } on Failure catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }
}
