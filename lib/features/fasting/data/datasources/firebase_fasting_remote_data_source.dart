import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:mamba_fast_tracker/core/error/failure.dart';
import 'package:mamba_fast_tracker/features/fasting/data/datasources/fasting_remote_data_source.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/entities/fasting_day_history_entry.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/entities/fasting_protocol.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/entities/fasting_session.dart';

class FirebaseFastingRemoteDataSource implements FastingRemoteDataSource {
  FirebaseFastingRemoteDataSource(this._firestore);

  final FirebaseFirestore _firestore;

  @override
  Future<FastingProtocol?> getProtocol({required String uid}) async {
    try {
      final snapshot = await _firestore.collection('users').doc(uid).get();
      final data = snapshot.data();
      if (data == null) return null;
      final fastingRaw = data['fasting'];
      final fasting = fastingRaw is Map ? Map<String, dynamic>.from(fastingRaw) : null;
      final protocolRaw = fasting?['protocol'];
      final protocolMap =
          protocolRaw is Map ? Map<String, dynamic>.from(protocolRaw) : null;
      if (protocolMap == null) return null;
      return FastingProtocol.fromMap(protocolMap);
    } on FirebaseException catch (e) {
      throw DataFailure(
        message: e.message ?? 'Falha ao buscar protocolo de jejum',
        code: e.code,
      );
    }
  }

  @override
  Future<FastingSession?> getSession({required String uid}) async {
    try {
      final snapshot = await _firestore.collection('users').doc(uid).get();
      final data = snapshot.data();
      if (data == null) return null;
      final fastingRaw = data['fasting'];
      final fasting = fastingRaw is Map ? Map<String, dynamic>.from(fastingRaw) : null;
      final sessionRaw = fasting?['session'];
      final sessionMap =
          sessionRaw is Map ? Map<String, dynamic>.from(sessionRaw) : null;
      if (sessionMap == null) return null;
      return FastingSession.fromMap(sessionMap);
    } on FirebaseException catch (e) {
      throw DataFailure(
        message: e.message ?? 'Falha ao buscar sessão de jejum',
        code: e.code,
      );
    }
  }

  @override
  Future<List<FastingDayHistoryEntry>> getDayHistory({required String uid}) async {
    try {
      final snapshot = await _firestore.collection('users').doc(uid).get();
      final data = snapshot.data();
      if (data == null) return const [];
      final fastingRaw = data['fasting'];
      final fasting = fastingRaw is Map
          ? Map<String, dynamic>.from(fastingRaw)
          : null;
      final historyRaw = fasting?['history'];
      if (historyRaw is! List) return const [];
      return historyRaw
          .whereType<Map>()
          .map(
            (item) => FastingDayHistoryEntry.fromMap(
              Map<String, dynamic>.from(item),
            ),
          )
          .toList(growable: false);
    } on FirebaseException catch (e) {
      throw DataFailure(
        message: e.message ?? 'Falha ao buscar histórico de jejum',
        code: e.code,
      );
    }
  }

  @override
  Future<void> saveProtocol({
    required String uid,
    required FastingProtocol protocol,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'fasting': {
          'protocol': protocol.toMap(),
        },
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw DataFailure(
        message: e.message ?? 'Falha ao salvar protocolo de jejum',
        code: e.code,
      );
    }
  }

  @override
  Future<void> saveSession({
    required String uid,
    required FastingSession session,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'fasting': {
          'session': session.toMap(),
        },
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw DataFailure(
        message: e.message ?? 'Falha ao salvar sessão de jejum',
        code: e.code,
      );
    }
  }

  @override
  Future<void> saveDayHistory({
    required String uid,
    required List<FastingDayHistoryEntry> history,
  }) async {
    try {
      await _firestore.collection('users').doc(uid).set({
        'fasting': {
          'history': history.map((item) => item.toMap()).toList(),
        },
      }, SetOptions(merge: true));
    } on FirebaseException catch (e) {
      throw DataFailure(
        message: e.message ?? 'Falha ao salvar histórico de jejum',
        code: e.code,
      );
    }
  }
}
