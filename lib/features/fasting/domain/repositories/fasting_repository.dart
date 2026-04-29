import 'package:mamba_fast_tracker/features/fasting/domain/entities/fasting_protocol.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/entities/fasting_day_history_entry.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/entities/fasting_session.dart';

abstract class FastingRepository {
  Future<FastingProtocol> getSelectedProtocol();
  Future<void> saveSelectedProtocol(FastingProtocol protocol);
  Future<FastingSession> getSession();
  Future<void> saveSession(FastingSession session);
  Future<List<FastingDayHistoryEntry>> getDayHistory();
  Future<void> saveDayHistory(List<FastingDayHistoryEntry> history);
}
