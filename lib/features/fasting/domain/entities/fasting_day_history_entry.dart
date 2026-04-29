import 'package:equatable/equatable.dart';

enum FastingDayHistoryStatus { completed, interrupted }

class FastingDayHistoryEntry extends Equatable {
  const FastingDayHistoryEntry({
    required this.id,
    required this.startedAtUtc,
    required this.endedAtUtc,
    required this.elapsedSeconds,
    required this.status,
  });

  final String id;
  final DateTime startedAtUtc;
  final DateTime endedAtUtc;
  final int elapsedSeconds;
  final FastingDayHistoryStatus status;

  Duration get elapsed => Duration(seconds: elapsedSeconds);

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'startedAtUtc': startedAtUtc.millisecondsSinceEpoch,
      'endedAtUtc': endedAtUtc.millisecondsSinceEpoch,
      'elapsedSeconds': elapsedSeconds,
      'status': status.name,
    };
  }

  factory FastingDayHistoryEntry.fromMap(Map<String, dynamic> map) {
    final statusName =
        map['status'] as String? ?? FastingDayHistoryStatus.interrupted.name;
    final resolvedStatus = FastingDayHistoryStatus.values.firstWhere(
      (item) => item.name == statusName,
      orElse: () => FastingDayHistoryStatus.interrupted,
    );
    return FastingDayHistoryEntry(
      id: map['id'] as String? ?? '',
      startedAtUtc: DateTime.fromMillisecondsSinceEpoch(
        map['startedAtUtc'] as int? ?? 0,
        isUtc: true,
      ),
      endedAtUtc: DateTime.fromMillisecondsSinceEpoch(
        map['endedAtUtc'] as int? ?? 0,
        isUtc: true,
      ),
      elapsedSeconds: map['elapsedSeconds'] as int? ?? 0,
      status: resolvedStatus,
    );
  }

  @override
  List<Object?> get props => [
        id,
        startedAtUtc,
        endedAtUtc,
        elapsedSeconds,
        status,
      ];
}
