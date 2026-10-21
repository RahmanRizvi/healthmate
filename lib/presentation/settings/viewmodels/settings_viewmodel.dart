import 'package:flutter/material.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../data/models/daily_goals.dart';
import '../../../data/models/user_profile.dart';
import '../../../domain/services/bmi_service.dart';
import '../../../domain/services/onboarding_service.dart';

/// ViewModel managing state, SQLite data loading, preferences, and notifications for Settings.
class SettingsViewModel extends ChangeNotifier {
  final OnboardingService onboardingService;
  final BmiService bmiService;
  final AppPreferences preferences;
  final ThemeController themeController;
  final NotificationService notificationService;

  UserProfile? _profile;
  DailyGoals? _goals;
  BmiResult? _bmiResult;
  bool _isLoading = true;
  String? _errorMessage;

  SettingsViewModel({
    required this.onboardingService,
    required this.bmiService,
    required this.preferences,
    required this.themeController,
    required this.notificationService,
  });

  // Getters
  UserProfile? get profile => _profile;
  DailyGoals? get goals => _goals;
  BmiResult? get bmiResult => _bmiResult;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  ThemeMode get themeMode => themeController.themeMode;
  MeasurementUnitSystem get measurementUnit => preferences.measurementUnit;
  bool get dailyRemindersEnabled => preferences.dailyRemindersEnabled;
  bool get weeklyDigestEnabled => preferences.weeklyDigestEnabled;

  /// Initials derived from the saved user profile name (e.g., "Alex Morgan" -> "AM").
  String get initials {
    if (_profile == null || _profile!.fullName.trim().isEmpty) {
      return 'HM';
    }
    final parts = _profile!.fullName.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      final first = parts[0].isNotEmpty ? parts[0][0].toUpperCase() : '';
      final second = parts[1].isNotEmpty ? parts[1][0].toUpperCase() : '';
      return '$first$second';
    } else if (parts.isNotEmpty && parts[0].isNotEmpty) {
      return parts[0][0].toUpperCase();
    }
    return 'HM';
  }

  /// Loads the saved profile, goals, and recalculates BMI.
  Future<void> loadSettings() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final p = await onboardingService.getProfile();
      final g = await onboardingService.getGoals();

      _profile = p;
      _goals = g ?? DailyGoals.defaults();

      if (_profile != null && _profile!.heightCm > 0 && _profile!.weightKg > 0) {
        _bmiResult = bmiService.assess(_profile!);
      } else {
        _bmiResult = BmiResult.empty();
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to load settings data: $e';
      notifyListeners();
    }
  }

  /// Sets the application-wide theme mode (System, Light, Dark).
  Future<void> setThemeMode(ThemeMode mode) async {
    await themeController.setThemeMode(mode);
    notifyListeners();
  }

  /// Toggles or updates measurement unit system (Metric <-> Imperial).
  Future<void> setMeasurementUnit(MeasurementUnitSystem unit) async {
    await preferences.setMeasurementUnit(unit);
    notifyListeners();
  }

  /// Toggles daily reminder notifications with permission checks and persistent state.
  Future<bool> setDailyRemindersEnabled(bool enabled) async {
    if (enabled) {
      final granted = await notificationService.requestPermissions();
      if (!granted) {
        // Permission denied by OS
        await preferences.setDailyRemindersEnabled(false);
        await notificationService.cancelDailyReminder();
        notifyListeners();
        return false;
      }
      await preferences.setDailyRemindersEnabled(true);
      await notificationService.scheduleDailyReminder(
        hour: preferences.reminderHour,
        minute: preferences.reminderMinute,
      );
      await notificationService.showInstantNotification(
        title: 'HealthMate Reminders Enabled',
        body: 'Daily check-in alerts are active! Stay hydrated and keep moving.',
      );
    } else {
      await preferences.setDailyRemindersEnabled(false);
      await notificationService.cancelDailyReminder();
    }
    notifyListeners();
    return true;
  }

  /// Toggles weekly digest notification schedule with persistent state.
  Future<bool> setWeeklyDigestEnabled(bool enabled) async {
    if (enabled) {
      final granted = await notificationService.requestPermissions();
      if (!granted) {
        await preferences.setWeeklyDigestEnabled(false);
        await notificationService.cancelWeeklyDigest();
        notifyListeners();
        return false;
      }
      await preferences.setWeeklyDigestEnabled(true);
      await notificationService.scheduleWeeklyDigest();
      await notificationService.showInstantNotification(
        title: 'Weekly Health Digest Enabled',
        body: 'Your weekly activity and hydration digest will arrive every Monday!',
      );
    } else {
      await preferences.setWeeklyDigestEnabled(false);
      await notificationService.cancelWeeklyDigest();
    }
    notifyListeners();
    return true;
  }
}
