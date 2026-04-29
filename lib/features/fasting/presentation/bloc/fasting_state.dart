import 'package:equatable/equatable.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/entities/fasting_day_history_entry.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/entities/fasting_protocol.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/entities/fasting_session.dart';

class FastingState extends Equatable {
  const FastingState({
    required this.isLoading,
    required this.protocol,
    required this.session,
    required this.history,
    required this.nowUtc,
    this.errorMessage = '',
  });

  final bool isLoading;
  final FastingProtocol protocol;
  final FastingSession session;
  final List<FastingDayHistoryEntry> history;
  final DateTime nowUtc;
  final String errorMessage;

  Duration get elapsed {
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

  Duration get total => protocol.fastingDuration;

  Duration get remaining {
    final value = total - elapsed;
    if (value.isNegative) return Duration.zero;
    return value;
  }

  bool get isCompleted => elapsed >= total && total > Duration.zero;

  FastingState copyWith({
    bool? isLoading,
    FastingProtocol? protocol,
    FastingSession? session,
    List<FastingDayHistoryEntry>? history,
    DateTime? nowUtc,
    String? errorMessage,
  }) {
    return FastingState(
      isLoading: isLoading ?? this.isLoading,
      protocol: protocol ?? this.protocol,
      session: session ?? this.session,
      history: history ?? this.history,
      nowUtc: nowUtc ?? this.nowUtc,
      errorMessage: errorMessage ?? this.errorMessage,
    );
  }

  static FastingState initial() {
    return FastingState(
      isLoading: false,
      protocol: FastingProtocol.defaultProtocol,
      session: FastingSession.idle,
      history: const [],
      nowUtc: DateTime.now().toUtc(),
    );
  }

  @override
  List<Object?> get props => [
        isLoading,
        protocol,
        session,
        history,
        nowUtc.millisecondsSinceEpoch,
        errorMessage,
      ];
}
