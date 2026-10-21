import 'package:flutter/material.dart';
import '../preferences/app_preferences.dart';

/// Application-wide theme controller that notifies listeners when theme mode changes.
class ThemeController extends ChangeNotifier {
  final AppPreferences _preferences;

  ThemeController(this._preferences);

  /// Current theme mode (system, light, or dark).
  ThemeMode get themeMode => _preferences.themeMode;

  /// Updates theme mode, persists preference, and notifies listeners across the app.
  Future<void> setThemeMode(ThemeMode mode) async {
    if (themeMode == mode) return;
    await _preferences.setThemeMode(mode);
    notifyListeners();
  }

  /// Convenience helper to check if dark mode is active in the current context.
  bool isDark(BuildContext context) {
    if (themeMode == ThemeMode.dark) return true;
    if (themeMode == ThemeMode.light) return false;
    return MediaQuery.platformBrightnessOf(context) == Brightness.dark;
  }
}
