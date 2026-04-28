import 'dart:convert';

import 'package:mamba_fast_tracker/features/auth/data/datasources/user_profile_local_data_source.dart';
import 'package:mamba_fast_tracker/features/auth/domain/entities/app_user.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SharedPrefsUserProfileLocalDataSource
    implements UserProfileLocalDataSource {
  SharedPrefsUserProfileLocalDataSource(this._preferences);

  final SharedPreferences _preferences;
  static const _key = 'cached_profile';

  @override
  Future<void> cacheProfile(AppUser user) async {
    await _preferences.setString(
      _key,
      jsonEncode({
        'uid': user.uid,
        'email': user.email,
        'name': user.name,
      }),
    );
  }

  @override
  Future<AppUser?> getCachedProfile() async {
    final raw = _preferences.getString(_key);
    if (raw == null) return null;
    final data = jsonDecode(raw) as Map<String, dynamic>;
    return AppUser(
      uid: data['uid'] as String? ?? '',
      email: data['email'] as String? ?? '',
      name: data['name'] as String? ?? '',
    );
  }
}
