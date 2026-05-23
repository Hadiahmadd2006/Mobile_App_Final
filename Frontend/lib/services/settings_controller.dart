import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// User-tunable settings that aren't tied to an account row.
///
/// Currently holds the theme override (`system` / `light` / `dark`) which
/// lets the user pick a mode independent of the iOS appearance setting.
/// Persisted in SharedPreferences so the choice survives restarts.
class SettingsController extends ChangeNotifier {
  static const String _kThemeMode = 'terrabite_theme_mode';

  ThemeMode _themeMode = ThemeMode.system;
  ThemeMode get themeMode => _themeMode;

  Future<void> load() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      _themeMode = _parse(prefs.getString(_kThemeMode));
    } catch (_) {
      _themeMode = ThemeMode.system;
    }
    notifyListeners();
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    if (mode == _themeMode) return;
    _themeMode = mode;
    notifyListeners();
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_kThemeMode, _stringify(mode));
    } catch (_) {
      // Best-effort.
    }
  }

  ThemeMode _parse(String? raw) {
    switch (raw) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      default:
        return ThemeMode.system;
    }
  }

  String _stringify(ThemeMode mode) {
    switch (mode) {
      case ThemeMode.light:
        return 'light';
      case ThemeMode.dark:
        return 'dark';
      case ThemeMode.system:
        return 'system';
    }
  }
}
