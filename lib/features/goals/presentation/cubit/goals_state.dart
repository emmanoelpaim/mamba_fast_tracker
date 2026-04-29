import 'package:equatable/equatable.dart';
import 'package:mamba_fast_tracker/features/goals/domain/entities/daily_goals.dart';
import 'package:mamba_fast_tracker/features/goals/domain/entities/goals_save_result.dart';

enum GoalsSaveFeedback { none, success, pendingSync, error }

class GoalsState extends Equatable {
  const GoalsState({
    required this.isLoading,
    required this.goals,
    this.errorMessage = '',
    this.saveStatus = GoalsSaveFeedback.none,
  });

  final bool isLoading;
  final DailyGoals goals;
  final String errorMessage;
  final GoalsSaveFeedback saveStatus;

  GoalsState copyWith({
    bool? isLoading,
    DailyGoals? goals,
    String? errorMessage,
    GoalsSaveFeedback? saveStatus,
  }) {
    return GoalsState(
      isLoading: isLoading ?? this.isLoading,
      goals: goals ?? this.goals,
      errorMessage: errorMessage ?? this.errorMessage,
      saveStatus: saveStatus ?? this.saveStatus,
    );
  }

  static GoalsState initial() {
    return const GoalsState(
      isLoading: false,
      goals: DailyGoals.defaults,
      saveStatus: GoalsSaveFeedback.none,
    );
  }

  static GoalsSaveFeedback mapSaveStatus(GoalsSaveStatus status) {
    return switch (status) {
      GoalsSaveStatus.savedRemote => GoalsSaveFeedback.success,
      GoalsSaveStatus.savedPendingSync => GoalsSaveFeedback.pendingSync,
    };
  }

  @override
  List<Object?> get props => [isLoading, goals, errorMessage, saveStatus];
}
