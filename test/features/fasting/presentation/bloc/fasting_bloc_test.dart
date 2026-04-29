import 'package:bloc_test/bloc_test.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/entities/fasting_protocol.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/entities/fasting_session.dart';
import 'package:mamba_fast_tracker/core/notifications/fasting_end_notification_scheduler.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/repositories/fasting_repository.dart';
import 'package:mamba_fast_tracker/features/fasting/presentation/bloc/fasting_bloc.dart';
import 'package:mamba_fast_tracker/features/fasting/presentation/bloc/fasting_event.dart';
import 'package:mamba_fast_tracker/features/fasting/presentation/bloc/fasting_state.dart';

class _MockFastingRepository extends Mock implements FastingRepository {}

class _MockFastingEndNotificationScheduler extends Mock
    implements FastingEndNotificationScheduler {}

void main() {
  late _MockFastingRepository repository;
  late _MockFastingEndNotificationScheduler endNotifications;

  setUpAll(() {
    registerFallbackValue(FastingProtocol.preset168);
    registerFallbackValue(const FastingSession(
      status: FastingSessionStatus.idle,
      protocol: FastingProtocol.preset168,
    ));
    registerFallbackValue(FastingState.initial());
  });

  setUp(() {
    repository = _MockFastingRepository();
    endNotifications = _MockFastingEndNotificationScheduler();
    when(() => endNotifications.syncSchedule(any())).thenAnswer((_) async {});
    when(() => endNotifications.notifyFastingStarted()).thenAnswer((_) async {});
    when(() => endNotifications.notifyFastingEnded()).thenAnswer((_) async {});
    when(() => repository.getSelectedProtocol()).thenAnswer(
      (_) async => FastingProtocol.preset168,
    );
    when(() => repository.getSession()).thenAnswer(
      (_) async => const FastingSession(
        status: FastingSessionStatus.idle,
        protocol: FastingProtocol.preset168,
      ),
    );
    when(() => repository.saveSelectedProtocol(any())).thenAnswer((_) async {});
    when(() => repository.saveSession(any())).thenAnswer((_) async {});
  });

  blocTest<FastingBloc, FastingState>(
    'carrega protocolo e sessão na inicialização',
    build: () => FastingBloc(
      fastingRepository: repository,
      endNotificationScheduler: endNotifications,
    ),
    act: (bloc) => bloc.add(const FastingInitialized()),
    wait: const Duration(milliseconds: 200),
    verify: (bloc) {
      expect(bloc.state.isLoading, false);
      expect(bloc.state.protocol.label, '16:8');
    },
  );

  blocTest<FastingBloc, FastingState>(
    'inicia jejum e muda status para running',
    build: () => FastingBloc(
      fastingRepository: repository,
      endNotificationScheduler: endNotifications,
    ),
    seed: FastingState.initial,
    act: (bloc) => bloc.add(const FastingStarted()),
    expect: () => [
      isA<FastingState>().having(
        (s) => s.session.status,
        'status',
        FastingSessionStatus.running,
      ),
    ],
  );

  blocTest<FastingBloc, FastingState>(
    'encerrar jejum em andamento dispara notificação de término',
    build: () => FastingBloc(
      fastingRepository: repository,
      endNotificationScheduler: endNotifications,
    ),
    seed: () => FastingState.initial().copyWith(
      session: FastingSession(
        status: FastingSessionStatus.running,
        protocol: FastingProtocol.defaultProtocol,
        startedAtUtc: DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
      ),
    ),
    act: (bloc) => bloc.add(const FastingStopped()),
    verify: (_) {
      verify(() => endNotifications.notifyFastingEnded()).called(1);
    },
  );

  blocTest<FastingBloc, FastingState>(
    'encerrar jejum pausado dispara notificação de término',
    build: () => FastingBloc(
      fastingRepository: repository,
      endNotificationScheduler: endNotifications,
    ),
    seed: () => FastingState.initial().copyWith(
      session: FastingSession(
        status: FastingSessionStatus.paused,
        protocol: FastingProtocol.defaultProtocol,
        startedAtUtc: DateTime.now().toUtc().subtract(const Duration(minutes: 5)),
        pausedAtUtc: DateTime.now().toUtc().subtract(const Duration(minutes: 1)),
      ),
    ),
    act: (bloc) => bloc.add(const FastingStopped()),
    verify: (_) {
      verify(() => endNotifications.notifyFastingEnded()).called(1);
    },
  );
}
