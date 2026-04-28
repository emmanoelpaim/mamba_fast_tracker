import 'dart:convert';

import 'package:mamba_fast_tracker/features/fasting/data/datasources/fasting_local_data_source.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/entities/fasting_protocol.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/entities/fasting_session.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsFastingLocalDataSource implements FastingLocalDataSource {
  SharedPrefsFastingLocalDataSource(this._preferences);

  final SharedPreferences _preferences;

  String _protocolKey(String uid) => 'fasting_protocol_$uid';
  String _sessionKey(String uid) => 'fasting_session_$uid';

  @override
  Future<FastingProtocol?> getProtocol({required String uid}) async {
    final raw = _preferences.getString(_protocolKey(uid));
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return FastingProtocol.fromMap(map);
  }

  @override
  Future<FastingSession?> getSession({required String uid}) async {
    final raw = _preferences.getString(_sessionKey(uid));
    if (raw == null) return null;
    final map = jsonDecode(raw) as Map<String, dynamic>;
    return FastingSession.fromMap(map);
  }

  @override
  Future<void> saveProtocol({
    required String uid,
    required FastingProtocol protocol,
  }) async {
    await _preferences.setString(
      _protocolKey(uid),
      jsonEncode(protocol.toMap()),
    );
  }

  @override
  Future<void> saveSession({
    required String uid,
    required FastingSession session,
  }) async {
    await _preferences.setString(
      _sessionKey(uid),
      jsonEncode(session.toMap()),
    );
  }
}
