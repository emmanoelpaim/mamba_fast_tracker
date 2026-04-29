import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mamba_fast_tracker/core/error/failure.dart';
import 'package:mamba_fast_tracker/core/telemetry/analytics_service.dart';
import 'package:mamba_fast_tracker/features/meal/domain/entities/meal_entry.dart';
import 'package:mamba_fast_tracker/features/meal/domain/repositories/meal_repository.dart';
import 'package:mamba_fast_tracker/features/meal/presentation/bloc/meal_bloc.dart';
import 'package:mamba_fast_tracker/features/meal/presentation/bloc/meal_event.dart';
import 'package:mamba_fast_tracker/features/meal/presentation/bloc/meal_state.dart';

class _MockMealRepository extends Mock implements MealRepository {}

class _MockAnalyticsService extends Mock implements AnalyticsService {}

class _FakeMealEntry extends Fake implements MealEntry {}

void main() {
  late _MockMealRepository repository;
  late _MockAnalyticsService analyticsService;

  final mealA = MealEntry(
    id: '1',
    name: 'Cafe',
    calories: 250,
    createdAtUtc: DateTime.utc(2026, 1, 1, 10),
  );
  final mealB = MealEntry(
    id: '2',
    name: 'Almoco',
    calories: 600,
    createdAtUtc: DateTime.utc(2026, 1, 1, 13),
  );

  setUpAll(() {
    registerFallbackValue(_FakeMealEntry());
    registerFallbackValue(<String, Object?>{});
  });

  setUp(() {
    repository = _MockMealRepository();
    analyticsService = _MockAnalyticsService();

    when(() => repository.getMeals()).thenAnswer((_) async => [mealA]);
    when(
      () => repository.saveMeal(any()),
    ).thenAnswer((_) async => [mealA, mealB]);
    when(() => repository.updateMeal(any())).thenAnswer((_) async => [mealB]);
    when(() => repository.deleteMeal(any())).thenAnswer((_) async => [mealA]);
    when(
      () => analyticsService.logEvent(
        name: any(named: 'name'),
        parameters: any(named: 'parameters'),
      ),
    ).thenAnswer((_) async {});
  });

  blocTest<MealBloc, MealState>(
    'MealInitialized carrega lista de refeicoes',
    build: () => MealBloc(
      mealRepository: repository,
      analyticsService: analyticsService,
    ),
    act: (bloc) => bloc.add(const MealInitialized()),
    expect: () => [
      MealState.initial().copyWith(isLoading: true, errorMessage: ''),
      MealState.initial().copyWith(isLoading: false, meals: [mealA]),
    ],
  );

  blocTest<MealBloc, MealState>(
    'MealAdded adiciona refeicao e limpa erro',
    build: () => MealBloc(
      mealRepository: repository,
      analyticsService: analyticsService,
    ),
    act: (bloc) => bloc.add(const MealAdded(name: 'Jantar', calories: 700)),
    verify: (bloc) {
      expect(bloc.state.meals, [mealA, mealB]);
      expect(bloc.state.errorMessage, '');
      verify(
        () => analyticsService.logEvent(
          name: 'meal_added',
          parameters: any(named: 'parameters'),
        ),
      ).called(1);
    },
  );

  blocTest<MealBloc, MealState>(
    'MealUpdated com falha emite mensagem de erro',
    build: () => MealBloc(
      mealRepository: repository,
      analyticsService: analyticsService,
    ),
    setUp: () {
      when(
        () => repository.updateMeal(any()),
      ).thenThrow(const DataFailure(message: 'erro ao atualizar'));
    },
    act: (bloc) => bloc.add(MealUpdated(mealA.copyWith(name: 'Cafe 2'))),
    expect: () => [
      MealState.initial().copyWith(errorMessage: 'erro ao atualizar'),
    ],
  );

  blocTest<MealBloc, MealState>(
    'MealDeleted remove item da lista',
    build: () => MealBloc(
      mealRepository: repository,
      analyticsService: analyticsService,
    ),
    seed: () => MealState.initial().copyWith(meals: [mealA, mealB]),
    act: (bloc) => bloc.add(const MealDeleted('2')),
    expect: () => [
      MealState.initial().copyWith(meals: [mealA], errorMessage: ''),
    ],
  );
}
