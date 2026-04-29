import 'dart:async';

import 'package:bloc/bloc.dart';
import 'package:mamba_fast_tracker/core/error/failure.dart';
import 'package:mamba_fast_tracker/core/notifications/fasting_end_notification_scheduler.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/entities/fasting_day_history_entry.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/entities/fasting_session.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/repositories/fasting_repository.dart';
import 'package:mamba_fast_tracker/features/fasting/presentation/bloc/fasting_event.dart';
import 'package:mamba_fast_tracker/features/fasting/presentation/bloc/fasting_state.dart';

class FastingBloc extends Bloc<FastingEvent, FastingState> {
  FastingBloc({
    required FastingRepository fastingRepository,
    required FastingEndNotificationScheduler endNotificationScheduler,
  }) : _fastingRepository = fastingRepository,
       _endNotificationScheduler = endNotificationScheduler,
       super(FastingState.initial()) {
    on<FastingInitialized>(_onInitialized);
    on<FastingProtocolSelected>(_onProtocolSelected);
    on<FastingStarted>(_onStarted);
    on<FastingPaused>(_onPaused);
    on<FastingResumed>(_onResumed);
    on<FastingStopped>(_onStopped);
    on<FastingTicked>(_onTicked);
    on<FastingAlignNotifications>(_onAlignNotifications);
  }

  final FastingRepository _fastingRepository;
  final FastingEndNotificationScheduler _endNotificationScheduler;
  Timer? _ticker;

  Future<void> _onInitialized(
    FastingInitialized event,
    Emitter<FastingState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: ''));
    try {
      final protocol = await _fastingRepository.getSelectedProtocol();
      final session = await _fastingRepository.getSession();
      final history = await _fastingRepository.getDayHistory();
      emit(
        state.copyWith(
          isLoading: false,
          protocol: protocol,
          session: session.copyWith(protocol: protocol),
          history: history,
          nowUtc: DateTime.now().toUtc(),
        ),
      );
      _startTickerIfNeeded();
      add(const FastingTicked());
      await _endNotificationScheduler.syncSchedule(state);
    } on Failure catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    }
  }

  Future<void> _onProtocolSelected(
    FastingProtocolSelected event,
    Emitter<FastingState> emit,
  ) async {
    if (state.session.status == FastingSessionStatus.running ||
        state.session.status == FastingSessionStatus.paused) {
      emit(state.copyWith(errorMessage: 'É obrigado a parar o jejum atual'));
      return;
    }
    try {
      await _fastingRepository.saveSelectedProtocol(event.protocol);
      final updatedSession = state.session.copyWith(protocol: event.protocol);
      await _fastingRepository.saveSession(updatedSession);
      emit(
        state.copyWith(
          protocol: event.protocol,
          session: updatedSession,
          errorMessage: '',
        ),
      );
      await _endNotificationScheduler.syncSchedule(state);
    } on Failure catch (e) {
      emit(state.copyWith(errorMessage: e.message));
    }
  }

  Future<void> _onStarted(
    FastingStarted event,
    Emitter<FastingState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: ''));
    try {
      final now = DateTime.now().toUtc();
      final session = FastingSession(
        status: FastingSessionStatus.running,
        protocol: state.protocol,
        startedAtUtc: now,
        totalPausedSeconds: 0,
      );
      await _fastingRepository.saveSession(session);
      emit(
        state.copyWith(
          isLoading: false,
          session: session,
          nowUtc: now,
          errorMessage: '',
        ),
      );
      _startTickerIfNeeded();
      await _endNotificationScheduler.notifyFastingStarted();
      await _endNotificationScheduler.syncSchedule(state);
    } on Failure catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    }
  }

  Future<void> _onPaused(
    FastingPaused event,
    Emitter<FastingState> emit,
  ) async {
    if (state.session.status != FastingSessionStatus.running) return;
    final now = DateTime.now().toUtc();
    final session = state.session.copyWith(
      status: FastingSessionStatus.paused,
      pausedAtUtc: now,
    );
    await _fastingRepository.saveSession(session);
    emit(state.copyWith(session: session, nowUtc: now, errorMessage: ''));
    _stopTicker();
    await _endNotificationScheduler.syncSchedule(state);
  }

  Future<void> _onResumed(
    FastingResumed event,
    Emitter<FastingState> emit,
  ) async {
    if (state.session.status != FastingSessionStatus.paused ||
        state.session.pausedAtUtc == null) {
      return;
    }
    final now = DateTime.now().toUtc();
    final pausedDelta = now
        .difference(state.session.pausedAtUtc!)
        .inSeconds
        .clamp(0, 1 << 31);
    final session = state.session.copyWith(
      status: FastingSessionStatus.running,
      totalPausedSeconds: state.session.totalPausedSeconds + pausedDelta,
      clearPausedAt: true,
    );
    await _fastingRepository.saveSession(session);
    emit(state.copyWith(session: session, nowUtc: now, errorMessage: ''));
    _startTickerIfNeeded();
    await _endNotificationScheduler.syncSchedule(state);
  }

  Future<void> _onStopped(
    FastingStopped event,
    Emitter<FastingState> emit,
  ) async {
    emit(state.copyWith(isLoading: true, errorMessage: ''));
    try {
      final previousSession = state.session;
      final now = DateTime.now().toUtc();
      final shouldNotifyEnd =
          previousSession.status == FastingSessionStatus.running ||
          previousSession.status == FastingSessionStatus.paused;
      var nextHistory = state.history;
      if (shouldNotifyEnd) {
        nextHistory = await _appendHistoryEntry(
          session: previousSession,
          endedAtUtc: now,
        );
      }
      final session = FastingSession(
        status: FastingSessionStatus.idle,
        protocol: state.protocol,
      );
      await _fastingRepository.saveSession(session);
      if (shouldNotifyEnd) {
        await _fastingRepository.saveDayHistory(nextHistory);
      }
      emit(
        state.copyWith(
          isLoading: false,
          session: session,
          history: nextHistory,
          nowUtc: now,
          errorMessage: '',
        ),
      );
      _stopTicker();
      if (shouldNotifyEnd) {
        await _endNotificationScheduler.notifyFastingEnded();
      }
      await _endNotificationScheduler.syncSchedule(state);
    } on Failure catch (e) {
      emit(state.copyWith(isLoading: false, errorMessage: e.message));
    }
  }

  Future<void> _onTicked(
    FastingTicked event,
    Emitter<FastingState> emit,
  ) async {
    final now = DateTime.now().toUtc();
    emit(state.copyWith(nowUtc: now));
    if (state.session.status == FastingSessionStatus.running &&
        state.isCompleted) {
      final endedAt = now;
      final nextHistory = await _appendHistoryEntry(
        session: state.session,
        endedAtUtc: endedAt,
      );
      await _endNotificationScheduler.notifyFastingEnded();
      final completed = FastingSession(
        status: FastingSessionStatus.idle,
        protocol: state.protocol,
      );
      await _fastingRepository.saveSession(completed);
      await _fastingRepository.saveDayHistory(nextHistory);
      emit(state.copyWith(session: completed, history: nextHistory));
      _stopTicker();
      await _endNotificationScheduler.syncSchedule(state);
    }
  }

  Future<List<FastingDayHistoryEntry>> _appendHistoryEntry({
    required FastingSession session,
    required DateTime endedAtUtc,
  }) async {
    final startedAt = session.startedAtUtc;
    if (startedAt == null) return state.history;
    final elapsed = _calculateElapsed(session: session, nowUtc: endedAtUtc);
    if (elapsed <= Duration.zero) return state.history;
    final item = FastingDayHistoryEntry(
      id: '${endedAtUtc.microsecondsSinceEpoch}_${session.protocol.label}',
      startedAtUtc: startedAt,
      endedAtUtc: endedAtUtc,
      elapsedSeconds: elapsed.inSeconds,
      status: elapsed >= session.protocol.fastingDuration
          ? FastingDayHistoryStatus.completed
          : FastingDayHistoryStatus.interrupted,
    );
    return [item, ...state.history];
  }

  Duration _calculateElapsed({
    required FastingSession session,
    required DateTime nowUtc,
  }) {
    if (session.startedAtUtc == null) return Duration.zero;
    final end = session.status == FastingSessionStatus.paused
        ? (session.pausedAtUtc ?? nowUtc)
        : nowUtc;
    final raw = end.difference(session.startedAtUtc!);
    final paused = Duration(seconds: session.totalPausedSeconds);
    final value = raw - paused;
    if (value.isNegative) return Duration.zero;
    return value;
  }

  Future<void> _onAlignNotifications(
    FastingAlignNotifications event,
    Emitter<FastingState> emit,
  ) async {
    await _endNotificationScheduler.syncSchedule(state);
  }

  void _startTickerIfNeeded() {
    if (state.session.status != FastingSessionStatus.running) return;
    _ticker ??= Timer.periodic(
      const Duration(seconds: 1),
      (_) => add(const FastingTicked()),
    );
  }

  void _stopTicker() {
    _ticker?.cancel();
    _ticker = null;
  }

  @override
  Future<void> close() async {
    _stopTicker();
    return super.close();
  }
}
