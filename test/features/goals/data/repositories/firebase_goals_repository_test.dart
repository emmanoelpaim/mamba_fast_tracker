import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mamba_fast_tracker/core/error/failure.dart';
import 'package:mamba_fast_tracker/core/telemetry/analytics_service.dart';
import 'package:mamba_fast_tracker/core/telemetry/error_reporter.dart';
import 'package:mamba_fast_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:mamba_fast_tracker/features/goals/data/datasources/goals_local_data_source.dart';
import 'package:mamba_fast_tracker/features/goals/data/datasources/goals_remote_data_source.dart';
import 'package:mamba_fast_tracker/features/goals/data/repositories/firebase_goals_repository.dart';
import 'package:mamba_fast_tracker/features/goals/domain/entities/daily_goals.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class _MockGoalsLocalDataSource extends Mock implements GoalsLocalDataSource {}

class _MockGoalsRemoteDataSource extends Mock
    implements GoalsRemoteDataSource {}

class _MockUser extends Mock implements User {}
class _MockAnalyticsService extends Mock implements AnalyticsService {}
class _MockErrorReporter extends Mock implements ErrorReporter {}

class _FakeDailyGoals extends Fake implements DailyGoals {}

void main() {
  late _MockAuthRemoteDataSource authRemoteDataSource;
  late _MockGoalsLocalDataSource localDataSource;
  late _MockGoalsRemoteDataSource remoteDataSource;
  late _MockAnalyticsService analyticsService;
  late _MockErrorReporter errorReporter;
  late SharedPreferences preferences;
  late FirebaseGoalsRepository repository;
  late _MockUser user;

  const remoteGoals = DailyGoals(caloriesGoal: 1900, fastingHoursGoal: 14);
  const localGoals = DailyGoals(caloriesGoal: 2100, fastingHoursGoal: 16);

  setUpAll(() {
    registerFallbackValue(_FakeDailyGoals());
  });

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = await SharedPreferences.getInstance();
    authRemoteDataSource = _MockAuthRemoteDataSource();
    localDataSource = _MockGoalsLocalDataSource();
    remoteDataSource = _MockGoalsRemoteDataSource();
    analyticsService = _MockAnalyticsService();
    errorReporter = _MockErrorReporter();
    user = _MockUser();

    when(() => authRemoteDataSource.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('uid-1');
    when(
      () => remoteDataSource.getGoals(uid: any(named: 'uid')),
    ).thenAnswer((_) async => remoteGoals);
    when(
      () => localDataSource.getGoals(uid: any(named: 'uid')),
    ).thenAnswer((_) async => localGoals);
    when(
      () => localDataSource.saveGoals(
        uid: any(named: 'uid'),
        goals: any(named: 'goals'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => remoteDataSource.saveGoals(
        uid: any(named: 'uid'),
        goals: any(named: 'goals'),
      ),
    ).thenAnswer((_) async {});
    repository = FirebaseGoalsRepository(
      authRemoteDataSource: authRemoteDataSource,
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
      analyticsService: analyticsService,
      errorReporter: errorReporter,
      preferences: preferences,
    );
  });

  test('getGoals usa remoto e cacheia local', () async {
    final result = await repository.getGoals();

    expect(result, remoteGoals);
    verify(() => remoteDataSource.getGoals(uid: 'uid-1')).called(1);
    verify(
      () => localDataSource.saveGoals(uid: 'uid-1', goals: remoteGoals),
    ).called(1);
  });

  test('getGoals com falha remota faz fallback local', () async {
    when(
      () => remoteDataSource.getGoals(uid: any(named: 'uid')),
    ).thenThrow(const DataFailure(message: 'offline'));

    final result = await repository.getGoals();

    expect(result, localGoals);
    verify(() => localDataSource.getGoals(uid: 'uid-1')).called(1);
  });

  test('saveGoals salva local e tenta remoto', () async {
    const goals = DailyGoals(caloriesGoal: 1800, fastingHoursGoal: 12);

    final result = await repository.saveGoals(goals);

    expect(result, goals);
    verify(
      () => localDataSource.saveGoals(uid: 'uid-1', goals: goals),
    ).called(1);
    verify(
      () => remoteDataSource.saveGoals(uid: 'uid-1', goals: goals),
    ).called(1);
  });
}
