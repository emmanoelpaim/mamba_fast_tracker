import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mamba_fast_tracker/core/error/failure.dart';
import 'package:mamba_fast_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:mamba_fast_tracker/features/meal/data/datasources/meal_local_data_source.dart';
import 'package:mamba_fast_tracker/features/meal/data/datasources/meal_remote_data_source.dart';
import 'package:mamba_fast_tracker/features/meal/data/repositories/firebase_meal_repository.dart';
import 'package:mamba_fast_tracker/features/meal/domain/entities/meal_entry.dart';

class _MockAuthRemoteDataSource extends Mock implements AuthRemoteDataSource {}

class _MockMealLocalDataSource extends Mock implements MealLocalDataSource {}

class _MockMealRemoteDataSource extends Mock implements MealRemoteDataSource {}

class _MockUser extends Mock implements User {}

void main() {
  late _MockAuthRemoteDataSource authRemoteDataSource;
  late _MockMealLocalDataSource localDataSource;
  late _MockMealRemoteDataSource remoteDataSource;
  late FirebaseMealRepository repository;
  late _MockUser user;

  final mealA = MealEntry(
    id: '1',
    name: 'Cafe',
    calories: 300,
    createdAtUtc: DateTime.utc(2026, 1, 1, 8),
  );
  final mealB = MealEntry(
    id: '2',
    name: 'Almoco',
    calories: 700,
    createdAtUtc: DateTime.utc(2026, 1, 1, 12),
  );

  setUp(() {
    authRemoteDataSource = _MockAuthRemoteDataSource();
    localDataSource = _MockMealLocalDataSource();
    remoteDataSource = _MockMealRemoteDataSource();
    user = _MockUser();

    when(() => authRemoteDataSource.currentUser).thenReturn(user);
    when(() => user.uid).thenReturn('uid-1');
    when(
      () => localDataSource.getMeals(uid: any(named: 'uid')),
    ).thenAnswer((_) async => [mealA]);
    when(
      () => localDataSource.saveMeals(
        uid: any(named: 'uid'),
        meals: any(named: 'meals'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => remoteDataSource.getMeals(uid: any(named: 'uid')),
    ).thenAnswer((_) async => [mealB]);
    when(
      () => remoteDataSource.saveMeals(
        uid: any(named: 'uid'),
        meals: any(named: 'meals'),
      ),
    ).thenAnswer((_) async {});

    repository = FirebaseMealRepository(
      authRemoteDataSource: authRemoteDataSource,
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
    );
  });

  test('getMeals usa remoto e atualiza cache local', () async {
    final result = await repository.getMeals();

    expect(result, [mealB]);
    verify(() => remoteDataSource.getMeals(uid: 'uid-1')).called(1);
    verify(
      () => localDataSource.saveMeals(uid: 'uid-1', meals: [mealB]),
    ).called(1);
  });

  test('getMeals com falha remota faz fallback local', () async {
    when(
      () => remoteDataSource.getMeals(uid: any(named: 'uid')),
    ).thenThrow(const DataFailure(message: 'offline'));

    final result = await repository.getMeals();

    expect(result, [mealA]);
    verify(() => localDataSource.getMeals(uid: 'uid-1')).called(1);
  });

  test('saveMeal salva local e remoto com item novo no topo', () async {
    final mealNew = MealEntry(
      id: '3',
      name: 'Jantar',
      calories: 650,
      createdAtUtc: DateTime.utc(2026, 1, 1, 19),
    );

    final result = await repository.saveMeal(mealNew);

    expect(result.map((e) => e.id).toList(), ['3', '1']);
    verify(
      () => localDataSource.saveMeals(uid: 'uid-1', meals: result),
    ).called(1);
    verify(
      () => remoteDataSource.saveMeals(uid: 'uid-1', meals: result),
    ).called(1);
  });

  test('sem usuario autenticado lanca AuthFailure', () async {
    when(() => authRemoteDataSource.currentUser).thenReturn(null);

    await expectLater(
      repository.getMeals,
      throwsA(
        isA<AuthFailure>().having(
          (failure) => failure.code,
          'code',
          'user-not-authenticated',
        ),
      ),
    );
  });
}
