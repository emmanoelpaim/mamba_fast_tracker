import 'package:bloc/bloc.dart';
import 'package:mamba_fast_tracker/core/error/failure.dart';
import 'package:mamba_fast_tracker/core/telemetry/analytics_service.dart';
import 'package:mamba_fast_tracker/features/meal/domain/entities/meal_entry.dart';
import 'package:mamba_fast_tracker/features/meal/domain/repositories/meal_repository.dart';
import 'package:mamba_fast_tracker/features/meal/presentation/bloc/meal_event.dart';
import 'package:mamba_fast_tracker/features/meal/presentation/bloc/meal_state.dart';

class MealBloc extends Bloc<MealEvent, MealState> {
  MealBloc({
    required MealRepository mealRepository,
    required AnalyticsService analyticsService,
  }) : _mealRepository = mealRepository,
       _analyticsService = analyticsService,
       super(MealState.initial()) {
    on<MealInitialized>(_onInitialized);
    on<MealAdded>(_onAdded);
    on<MealUpdated>(_onUpdated);
    on<MealDeleted>(_onDeleted);
  }

  final MealRepository _mealRepository;
  final AnalyticsService _analyticsService;

  Future<void> _onInitialized(
    MealInitialized event,
    Emitter<MealState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: ''));
    try {
      final meals = await _mealRepository.getMeals();
      emit(state.copyWith(isLoading: false, meals: meals));
    } on Failure catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    }
  }

  Future<void> _onAdded(MealAdded event, Emitter<MealState> emit) async {
    final meal = MealEntry(
      id: DateTime.now().microsecondsSinceEpoch.toString(),
      name: event.name.trim(),
      calories: event.calories,
      createdAtUtc: DateTime.now().toUtc(),
    );
    try {
      final updated = await _mealRepository.saveMeal(meal);
      emit(state.copyWith(meals: updated, errorMessage: ''));
      await _analyticsService.logEvent(
        name: 'meal_added',
        parameters: {'calories': meal.calories},
      );
    } on Failure catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  Future<void> _onUpdated(MealUpdated event, Emitter<MealState> emit) async {
    try {
      final updated = await _mealRepository.updateMeal(event.meal);
      emit(state.copyWith(meals: updated, errorMessage: ''));
      await _analyticsService.logEvent(
        name: 'meal_updated',
        parameters: {'calories': event.meal.calories},
      );
    } on Failure catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  Future<void> _onDeleted(MealDeleted event, Emitter<MealState> emit) async {
    try {
      final updated = await _mealRepository.deleteMeal(event.id);
      emit(state.copyWith(meals: updated, errorMessage: ''));
      await _analyticsService.logEvent(name: 'meal_deleted');
    } on Failure catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }
}
