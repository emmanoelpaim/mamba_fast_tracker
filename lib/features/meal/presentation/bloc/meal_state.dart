import 'package:equatable/equatable.dart';
import 'package:mamba_fast_tracker/features/meal/domain/entities/meal_entry.dart';

class MealState extends Equatable {
  const MealState({
    required this.isLoading,
    required this.meals,
    this.errorMessage = '',
  });

  final bool isLoading;
  final List<MealEntry> meals;
  final String errorMessage;

  MealState copyWith({
    bool? isLoading,
    List<MealEntry>? meals,
    String? errorMessage,
  }) {
    return MealState(
      isLoading: isLoading ?? this.isLoading,
      meals: meals ?? this.meals,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  static MealState initial() {
    return const MealState(isLoading: false, meals: []);
  }

  @override
  List<Object?> get props => [isLoading, meals, errorMessage];
}
