import 'package:mamba_fast_tracker/core/error/failure.dart';
import 'package:mamba_fast_tracker/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:mamba_fast_tracker/features/fasting/data/datasources/fasting_local_data_source.dart';
import 'package:mamba_fast_tracker/features/fasting/data/datasources/fasting_remote_data_source.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/entities/fasting_protocol.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/entities/fasting_session.dart';
import 'package:mamba_fast_tracker/features/fasting/domain/repositories/fasting_repository.dart';

class FirebaseFastingRepository implements FastingRepository {
  FirebaseFastingRepository({
    required AuthRemoteDataSource authRemoteDataSource,
    required FastingLocalDataSource localDataSource,
    required FastingRemoteDataSource remoteDataSource,
  })  : _authRemoteDataSource = authRemoteDataSource,
        _localDataSource = localDataSource,
        _remoteDataSource = remoteDataSource;

  final AuthRemoteDataSource _authRemoteDataSource;
  final FastingLocalDataSource _localDataSource;
  final FastingRemoteDataSource _remoteDataSource;

  String _uidOrThrow() {
    final uid = _authRemoteDataSource.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      throw const AuthFailure(
        message: 'Usuário não autenticado',
        code: 'user-not-authenticated',
      );
    }
    return uid;
  }

  @override
  Future<FastingProtocol> getSelectedProtocol() async {
    final uid = _uidOrThrow();
    var remoteFailed = false;
    try {
      final remote = await _remoteDataSource.getProtocol(uid: uid);
      if (remote != null) {
        await _localDataSource.saveProtocol(uid: uid, protocol: remote);
        return remote;
      }
    } on Failure {
      remoteFailed = true;
    }
    final local = await _localDataSource.getProtocol(uid: uid);
    if (local != null) return local;
    if (remoteFailed) return FastingProtocol.defaultProtocol;
    return FastingProtocol.defaultProtocol;
  }

  @override
  Future<FastingSession> getSession() async {
    final uid = _uidOrThrow();
    var remoteFailed = false;
    try {
      final remote = await _remoteDataSource.getSession(uid: uid);
      if (remote != null) {
        await _localDataSource.saveSession(uid: uid, session: remote);
        return remote;
      }
    } on Failure {
      remoteFailed = true;
    }
    final local = await _localDataSource.getSession(uid: uid);
    if (local != null) return local;
    if (remoteFailed) return FastingSession.idle;
    return FastingSession.idle;
  }

  @override
  Future<void> saveSelectedProtocol(FastingProtocol protocol) async {
    final uid = _uidOrThrow();
    await _localDataSource.saveProtocol(uid: uid, protocol: protocol);
    var remoteFailed = false;
    try {
      await _remoteDataSource.saveProtocol(uid: uid, protocol: protocol);
    } on Failure {
      remoteFailed = true;
    }
    if (remoteFailed) return;
  }

  @override
  Future<void> saveSession(FastingSession session) async {
    final uid = _uidOrThrow();
    await _localDataSource.saveSession(uid: uid, session: session);
    var remoteFailed = false;
    try {
      await _remoteDataSource.saveSession(uid: uid, session: session);
    } on Failure {
      remoteFailed = true;
    }
    if (remoteFailed) return;
  }
}
