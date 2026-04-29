import 'package:equatable/equatable.dart';
import 'package:mamba_fast_tracker/features/goals/domain/entities/daily_goals.dart';

class GoalsState extends Equatable {
  const GoalsState({
    required this.isLoading,
    required this.goals,
    this.errorMessage = '',
  });

  final bool isLoading;
  final DailyGoals goals;
  final String errorMessage;

  GoalsState copyWith({
    bool? isLoading,
    DailyGoals? goals,
    String? errorMessage,
  }) {
    return GoalsState(
      isLoading: isLoading ?? this.isLoading,
      goals: goals ?? this.goals,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  static GoalsState initial() {
    return const GoalsState(isLoading: false, goals: DailyGoals.defaults);
  }

  @override
  List<Object?> get props => [isLoading, goals, errorMessage];
}
