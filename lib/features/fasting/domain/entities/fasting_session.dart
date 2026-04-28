import 'package:equatable/equatable.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/entities/fasting_protocol.dart';

enum FastingSessionStatus { idle, running, paused }

class FastingSession extends Equatable {
  const FastingSession({
    required this.status,
    required this.protocol,
    this.startedAtUtc,
    this.pausedAtUtc,
    this.totalPausedSeconds = 0,
  });

  final FastingSessionStatus status;
  final FastingProtocol protocol;
  final DateTime? startedAtUtc;
  final DateTime? pausedAtUtc;
  final int totalPausedSeconds;

  Map<String, dynamic> toMap() {
    return {
      'status': status.name,
      'protocol': protocol.toMap(),
      'startedAtUtc': startedAtUtc?.millisecondsSinceEpoch,
      'pausedAtUtc': pausedAtUtc?.millisecondsSinceEpoch,
      'totalPausedSeconds': totalPausedSeconds,
    };
  }

  factory FastingSession.fromMap(Map<String, dynamic> map) {
    final startedMs = map['startedAtUtc'] as int?;
    final pausedMs = map['pausedAtUtc'] as int?;
    final statusName = map['status'] as String? ?? FastingSessionStatus.idle.name;
    final status = FastingSessionStatus.values.firstWhere(
      (value) => value.name == statusName,
      orElse: () => FastingSessionStatus.idle,
    );
    return FastingSession(
      status: status,
      protocol: FastingProtocol.fromMap(
        map['protocol'] as Map<String, dynamic>? ?? const {},
      ),
      startedAtUtc: startedMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(startedMs, isUtc: true),
      pausedAtUtc: pausedMs == null
          ? null
          : DateTime.fromMillisecondsSinceEpoch(pausedMs, isUtc: true),
      totalPausedSeconds: map['totalPausedSeconds'] as int? ?? 0,
    );
  }

  static const idle = FastingSession(
    status: FastingSessionStatus.idle,
    protocol: FastingProtocol.defaultProtocol,
  );

  FastingSession copyWith({
    FastingSessionStatus? status,
    FastingProtocol? protocol,
    DateTime? startedAtUtc,
    DateTime? pausedAtUtc,
    int? totalPausedSeconds,
    bool clearStartedAt = false,
    bool clearPausedAt = false,
  }) {
    return FastingSession(
      status: status ?? this.status,
      protocol: protocol ?? this.protocol,
      startedAtUtc: clearStartedAt ? null : (startedAtUtc ?? this.startedAtUtc),
      pausedAtUtc: clearPausedAt ? null : (pausedAtUtc ?? this.pausedAtUtc),
      totalPausedSeconds: totalPausedSeconds ?? this.totalPausedSeconds,
    );
  }

  @override
  List<Object?> get props => [
        status,
        protocol,
        startedAtUtc,
        pausedAtUtc,
        totalPausedSeconds,
      ];
}
