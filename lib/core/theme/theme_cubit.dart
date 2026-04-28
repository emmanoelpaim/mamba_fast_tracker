import 'package:bloc/bloc.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeCubit extends Cubit<ThemeMode> {
  ThemeCubit(this._preferences) : super(ThemeMode.system);

  final SharedPreferences _preferences;
  static const _key = 'theme_mode';

  Future<void> load() async {
    final raw = _preferences.getString(_key);
    if (raw == 'light') emit(ThemeMode.light);
    if (raw == 'dark') emit(ThemeMode.dark);
    if (raw == 'system' || raw == null) emit(ThemeMode.system);
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    emit(mode);
    await _preferences.setString(_key, switch (mode) {
      ThemeMode.light => 'light',
      ThemeMode.dark => 'dark',
      ThemeMode.system => 'system',
    });
  }
}
