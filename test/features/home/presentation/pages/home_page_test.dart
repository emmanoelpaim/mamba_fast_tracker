import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamba_fast_tracker/core/theme/theme_cubit.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/entities/fasting_protocol.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/entities/fasting_session.dart';
import 'package:mamba_fast_tracker/features/fasting/presentation/bloc/fasting_bloc.dart';
import 'package:mamba_fast_tracker/features/fasting/presentation/bloc/fasting_event.dart';
import 'package:mamba_fast_tracker/features/fasting/presentation/bloc/fasting_state.dart';
import 'package:mamba_fast_tracker/features/goals/domain/entities/daily_goals.dart';
import 'package:mamba_fast_tracker/features/goals/presentation/cubit/goals_cubit.dart';
import 'package:mamba_fast_tracker/features/goals/presentation/cubit/goals_state.dart';
import 'package:mamba_fast_tracker/features/home/presentation/pages/home_page.dart';
import 'package:mamba_fast_tracker/features/meal/domain/entities/meal_entry.dart';
import 'package:mamba_fast_tracker/features/meal/presentation/bloc/meal_bloc.dart';
import 'package:mamba_fast_tracker/features/meal/presentation/bloc/meal_event.dart';
import 'package:mamba_fast_tracker/features/meal/presentation/bloc/meal_state.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

class _MockFastingBloc extends MockBloc<FastingEvent, FastingState>
    implements FastingBloc {}

class _MockMealBloc extends MockBloc<MealEvent, MealState>
    implements MealBloc {}

class _MockGoalsCubit extends MockCubit<GoalsState> implements GoalsCubit {}

void main() {
  Future<void> _pumpHome(
    WidgetTester tester, {
    required _MockAuthBloc authBloc,
    required _MockFastingBloc fastingBloc,
    required _MockMealBloc mealBloc,
    required _MockGoalsCubit goalsCubit,
  }) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final themeCubit = ThemeCubit(preferences);
    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<FastingBloc>.value(value: fastingBloc),
          BlocProvider<MealBloc>.value(value: mealBloc),
          BlocProvider<GoalsCubit>.value(value: goalsCubit),
          BlocProvider<ThemeCubit>.value(value: themeCubit),
        ],
        child: MaterialApp(home: HomePage(enableDarkModeMenu: true)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renderiza tab bar e cards do resumo diário', (tester) async {
    final authBloc = _MockAuthBloc();
    final fastingBloc = _MockFastingBloc();
    final mealBloc = _MockMealBloc();
    final goalsCubit = _MockGoalsCubit();
    when(
      () => authBloc.state,
    ).thenReturn(const AuthState(status: AuthFlowStatus.authenticated));
    whenListen(authBloc, const Stream<AuthState>.empty());
    when(() => fastingBloc.state).thenReturn(FastingState.initial());
    whenListen(fastingBloc, const Stream<FastingState>.empty());
    when(() => mealBloc.state).thenReturn(MealState.initial());
    whenListen(mealBloc, const Stream<MealState>.empty());
    when(() => goalsCubit.state).thenReturn(GoalsState.initial());
    when(() => goalsCubit.load()).thenAnswer((_) async {});
    when(
      () => goalsCubit.save(
        caloriesGoal: any(named: 'caloriesGoal'),
        fastingHoursGoal: any(named: 'fastingHoursGoal'),
      ),
    ).thenAnswer((_) async {});
    whenListen(goalsCubit, const Stream<GoalsState>.empty());

    await _pumpHome(
      tester,
      authBloc: authBloc,
      fastingBloc: fastingBloc,
      mealBloc: mealBloc,
      goalsCubit: goalsCubit,
    );

    expect(find.text('Configuração'), findsAtLeastNWidgets(1));
    expect(find.text('Jejum'), findsAtLeastNWidgets(1));
    expect(find.text('Início'), findsAtLeastNWidgets(1));
    expect(find.text('Refeições'), findsOneWidget);
    expect(find.text('Histórico'), findsAtLeastNWidgets(1));
    expect(find.text('Resumo de hoje'), findsOneWidget);
    expect(find.text('Calorias do dia'), findsOneWidget);
    expect(find.text('Jejum total do dia'), findsOneWidget);
    expect(find.text('Status diário'), findsOneWidget);
    await tester.tap(find.text('Configuração'));
    await tester.pumpAndSettle();
    expect(find.text('Metas diárias'), findsOneWidget);
    expect(find.text('Tema do app'), findsOneWidget);
    expect(find.text('Sair'), findsOneWidget);
  });

  testWidgets('exibe status dentro da meta quando regras são atendidas', (
    tester,
  ) async {
    final authBloc = _MockAuthBloc();
    final fastingBloc = _MockFastingBloc();
    final mealBloc = _MockMealBloc();
    final goalsCubit = _MockGoalsCubit();
    final now = DateTime.now().toUtc();
    when(
      () => authBloc.state,
    ).thenReturn(const AuthState(status: AuthFlowStatus.authenticated));
    whenListen(authBloc, const Stream<AuthState>.empty());
    when(() => mealBloc.state).thenReturn(
      MealState.initial().copyWith(
        meals: [
          MealEntry(id: '1', name: 'Cafe', calories: 500, createdAtUtc: now),
        ],
      ),
    );
    whenListen(mealBloc, const Stream<MealState>.empty());
    when(() => goalsCubit.state).thenReturn(
      GoalsState.initial().copyWith(
        goals: const DailyGoals(caloriesGoal: 1200, fastingHoursGoal: 12),
      ),
    );
    when(() => goalsCubit.load()).thenAnswer((_) async {});
    when(
      () => goalsCubit.save(
        caloriesGoal: any(named: 'caloriesGoal'),
        fastingHoursGoal: any(named: 'fastingHoursGoal'),
      ),
    ).thenAnswer((_) async {});
    whenListen(goalsCubit, const Stream<GoalsState>.empty());
    when(() => fastingBloc.state).thenReturn(
      FastingState.initial().copyWith(
        protocol: FastingProtocol.preset1212,
        session: FastingSession(
          status: FastingSessionStatus.running,
          protocol: FastingProtocol.preset1212,
          startedAtUtc: now.subtract(const Duration(hours: 13)),
        ),
        nowUtc: now,
      ),
    );
    whenListen(fastingBloc, const Stream<FastingState>.empty());

    await _pumpHome(
      tester,
      authBloc: authBloc,
      fastingBloc: fastingBloc,
      mealBloc: mealBloc,
      goalsCubit: goalsCubit,
    );

    expect(find.text('Dentro da meta'), findsOneWidget);
  });
}
