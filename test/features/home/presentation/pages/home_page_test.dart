import 'package:bloc_test/bloc_test.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mamba_fast_tracker/core/theme/theme_cubit.dart';
import 'package:mamba_fast_tracker/features/auth/domain/entities/app_user.dart';
import 'package:mamba_fast_tracker/features/auth/domain/repositories/auth_repository.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_bloc.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_event.dart';
import 'package:mamba_fast_tracker/features/auth/presentation/bloc/auth_state.dart';
import 'package:mamba_fast_tracker/features/home/presentation/pages/home_page.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAuthRepository extends Mock implements AuthRepository {}
class _MockAuthBloc extends MockBloc<AuthEvent, AuthState> implements AuthBloc {}

void main() {
  testWidgets('renderiza saudação com nome do usuário', (tester) async {
    final repository = _MockAuthRepository();
    final authBloc = _MockAuthBloc();
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();
    final themeCubit = ThemeCubit(preferences);
    when(() => authBloc.state).thenReturn(const AuthState(status: AuthFlowStatus.authenticated));
    whenListen(authBloc, const Stream<AuthState>.empty());
    when(() => repository.getCurrentUser()).thenAnswer(
      (_) async => const AppUser(
        uid: '1',
        email: 'user@test.com',
        name: 'Emmanoel',
      ),
    );

    await tester.pumpWidget(
      MultiBlocProvider(
        providers: [
          BlocProvider<AuthBloc>.value(value: authBloc),
          BlocProvider<ThemeCubit>.value(value: themeCubit),
        ],
        child: MaterialApp(
          home: HomePage(
            enableDarkModeMenu: true,
            authRepository: repository,
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Olá, Emmanoel'), findsOneWidget);
  });
}
