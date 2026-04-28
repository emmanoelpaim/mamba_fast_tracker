import 'package:mamba_fast_tracker/features/fasting/domain/entities/fasting_protocol.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/entities/fasting_session.dart';

abstract class FastingLocalDataSource {
  Future<void> saveProtocol({
    required String uid,
    required FastingProtocol protocol,
  });
  Future<FastingProtocol?> getProtocol({required String uid});
  Future<void> saveSession({
    required String uid,
    required FastingSession session,
  });
  Future<FastingSession?> getSession({required String uid});
}
