import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mamba_fast_tracker/core/theme/theme_cubit.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:mamba_fast_tracker/features/home/presentation/pages/home_page.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAuthBloc extends MockBloc<AuthEvent, AuthState>
    implements AuthBloc {}

void main() {
  testWidgets('renderiza tab bar com 5 opções', (tester) async {
    final authBloc = _MockAuthBloc();
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final themeCubit = ThemeCubit(preferences);
    when(
      () => authBloc.state,
    ).thenReturn(const AuthState(status: AuthFlowStatus.authenticated));
    whenListen(authBloc, const Stream<AuthState>.empty());

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<ThemeCubit>.value(value: themeCubit),
        ],
        child: MaterialApp(home: HomePage(enableDarkModeMenu: true)),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Configuração'), findsAtLeastNWidgets(1));
    expect(find.text('Jejum'), findsAtLeastNWidgets(1));
    expect(find.text('Início'), findsAtLeastNWidgets(1));
    expect(find.text('Refeições'), findsOneWidget);
    expect(find.text('Histórico'), findsAtLeastNWidgets(1));
  });
}
