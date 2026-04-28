import 'dart:async';

import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:flutter/foundation.dart';

class FeatureFlagsService {
  FeatureFlagsService(this._remoteConfig);

  final FirebaseRemoteConfig _remoteConfig;
  static const _enableDarkModeMenuKey = 'enable_dark_mode_menu';
  static const _enableRecoverPasswordKey = 'enable_recover_password';
  var _isConfigured = false;

  Future<void> configure() async {
    if (_isConfigured) return;
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: kDebugMode
            ? Duration.zero
            : const Duration(minutes: 5),
      ),
    );
    await _remoteConfig.setDefaults({
      _enableDarkModeMenuKey: false,
      _enableRecoverPasswordKey: false,
    });
    _isConfigured = true;
  }

  Future<void> initialize() async {
    await configure();
    await _remoteConfig.fetchAndActivate();
  }

  Future<void> warmUp({
    Duration timeout = const Duration(seconds: 3),
  }) async {
    await configure();
    try {
      await _remoteConfig.fetchAndActivate().timeout(timeout);
    } catch (_) {}
  }

  Future<void> refreshInBackground() async {
    await configure();
    unawaited(
      _remoteConfig.fetchAndActivate().catchError((_) => false),
    );
  }

  bool get enableDarkModeMenu => _remoteConfig.getBool(_enableDarkModeMenuKey);

  bool get enableRecoverPassword =>
      _remoteConfig.getBool(_enableRecoverPasswordKey);

  bool get hasRequiredFlags {
    final values = _remoteConfig.getAll();
    return values.containsKey(_enableDarkModeMenuKey) &&
        values.containsKey(_enableRecoverPasswordKey);
  }

  String get darkModeMenuSource =>
      _sourceLabel(_remoteConfig.getValue(_enableDarkModeMenuKey).source);

  String get recoverPasswordSource =>
      _sourceLabel(_remoteConfig.getValue(_enableRecoverPasswordKey).source);

  RemoteConfigFetchStatus get lastFetchStatus => _remoteConfig.lastFetchStatus;

  DateTime? get lastFetchTime => _remoteConfig.lastFetchTime;

  String _sourceLabel(ValueSource source) {
    return switch (source) {
      ValueSource.valueStatic => 'static',
      ValueSource.valueDefault => 'default',
      ValueSource.valueRemote => 'remote',
    };
  }
}
