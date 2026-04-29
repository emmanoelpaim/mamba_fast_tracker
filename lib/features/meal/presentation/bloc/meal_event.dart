import 'package:equatable/equatable.dart';
import 'package:mamba_fast_tracker/features/meal/domain/entities/meal_entry.dart';

abstract class MealEvent extends Equatable {
  const MealEvent();

  @override
  List<Object?> get props => [];
}

class MealInitialized extends MealEvent {
  const MealInitialized();
}

class MealAdded extends MealEvent {
  const MealAdded({required this.name, required this.calories});

  final String name;
  final int calories;

  @override
  List<Object?> get props => [name, calories];
}

class MealUpdated extends MealEvent {
  const MealUpdated(this.meal);

  final MealEntry meal;

  @override
  List<Object?> get props => [meal];
}

class MealDeleted extends MealEvent {
  const MealDeleted(this.id);

  final String id;

  @override
  List<Object?> get props => [id];
}
