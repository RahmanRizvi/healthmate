import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

enum MeasurementUnitSystem {
  metric,
  imperial;

  String get label => this == MeasurementUnitSystem.metric
      ? 'Metric (cm, kg)'
      : 'Imperial (ft, lbs)';
  String get shortLabel =>
      this == MeasurementUnitSystem.metric ? 'Metric' : 'Imperial';
}

/// Service managing persistent user preferences in SharedPreferences with in-memory fallback.
class AppPreferences {
  static const String _keyThemeMode = 'theme_mode';
  static const String _keyDailyReminders = 'daily_reminders_enabled';
  static const String _keyMeasurementUnits = 'measurement_units';
  static const String _keyWeeklyDigest = 'weekly_digest_enabled';
  static const String _keyReminderHour = 'reminder_hour';
  static const String _keyReminderMinute = 'reminder_minute';

  final SharedPreferences? _prefs;
  final Map<String, Object> _inMemory;

  AppPreferences([this._prefs]) : _inMemory = {};

  /// Initializes SharedPreferences instance.
  static Future<AppPreferences> init() async {
    final prefs = await SharedPreferences.getInstance();
    return AppPreferences(prefs);
  }

  /// Factory creating an in-memory instance with optional initial values.
  static AppPreferences createInMemory([
    Map<String, Object> values = const {},
  ]) {
    final instance = AppPreferences(null);
    instance._inMemory.addAll(values);
    return instance;
  }

  // --- Theme Mode ---
  ThemeMode get themeMode {
    final value = _prefs?.getString(_keyThemeMode) ??
        _inMemory[_keyThemeMode] as String?;
    switch (value) {
      case 'light':
        return ThemeMode.light;
      case 'dark':
        return ThemeMode.dark;
      case 'system':
      default:
        return ThemeMode.system;
    }
  }

  Future<bool> setThemeMode(ThemeMode mode) async {
    String value;
    switch (mode) {
      case ThemeMode.light:
        value = 'light';
        break;
      case ThemeMode.dark:
        value = 'dark';
        break;
      case ThemeMode.system:
        value = 'system';
        break;
    }
    _inMemory[_keyThemeMode] = value;
    if (_prefs != null) {
      return await _prefs.setString(_keyThemeMode, value);
    }
    return true;
  }

  // --- Daily Reminders ---
  bool get dailyRemindersEnabled {
    if (_prefs != null) {
      return _prefs.getBool(_keyDailyReminders) ?? true;
    }
    return (_inMemory[_keyDailyReminders] as bool?) ?? true;
  }

  Future<bool> setDailyRemindersEnabled(bool enabled) async {
    _inMemory[_keyDailyReminders] = enabled;
    if (_prefs != null) {
      return await _prefs.setBool(_keyDailyReminders, enabled);
    }
    return true;
  }

  int get reminderHour {
    if (_prefs != null) {
      return _prefs.getInt(_keyReminderHour) ?? 9;
    }
    return (_inMemory[_keyReminderHour] as int?) ?? 9;
  }

  int get reminderMinute {
    if (_prefs != null) {
      return _prefs.getInt(_keyReminderMinute) ?? 0;
    }
    return (_inMemory[_keyReminderMinute] as int?) ?? 0;
  }

  Future<void> setReminderTime(int hour, int minute) async {
    _inMemory[_keyReminderHour] = hour;
    _inMemory[_keyReminderMinute] = minute;
    if (_prefs != null) {
      await _prefs.setInt(_keyReminderHour, hour);
      await _prefs.setInt(_keyReminderMinute, minute);
    }
  }

  // --- Measurement Units ---
  MeasurementUnitSystem get measurementUnit {
    final value = _prefs?.getString(_keyMeasurementUnits) ??
        _inMemory[_keyMeasurementUnits] as String?;
    return value == 'imperial'
        ? MeasurementUnitSystem.imperial
        : MeasurementUnitSystem.metric;
  }

  Future<bool> setMeasurementUnit(MeasurementUnitSystem unit) async {
    final str = unit == MeasurementUnitSystem.imperial ? 'imperial' : 'metric';
    _inMemory[_keyMeasurementUnits] = str;
    if (_prefs != null) {
      return await _prefs.setString(_keyMeasurementUnits, str);
    }
    return true;
  }

  // --- Weekly Health Digest ---
  bool get weeklyDigestEnabled {
    if (_prefs != null) {
      return _prefs.getBool(_keyWeeklyDigest) ?? true;
    }
    return (_inMemory[_keyWeeklyDigest] as bool?) ?? true;
  }

  Future<bool> setWeeklyDigestEnabled(bool enabled) async {
    _inMemory[_keyWeeklyDigest] = enabled;
    if (_prefs != null) {
      return await _prefs.setBool(_keyWeeklyDigest, enabled);
    }
    return true;
  }
}
