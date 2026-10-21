import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/preferences/app_preferences.dart';
import 'package:healthmate/core/theme/theme_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('ThemeController and Preferences Persistence Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Initializes with default System theme mode', () async {
      final prefs = await AppPreferences.init();
      final controller = ThemeController(prefs);

      expect(controller.themeMode, ThemeMode.system);
    });

    test('Changes theme mode, notifies listeners, and persists across restarts', () async {
      final prefs = await AppPreferences.init();
      final controller = ThemeController(prefs);

      int notifyCount = 0;
      controller.addListener(() {
        notifyCount++;
      });

      // Switch to Dark Mode
      await controller.setThemeMode(ThemeMode.dark);
      expect(controller.themeMode, ThemeMode.dark);
      expect(notifyCount, 1);

      // Simulate app restart by re-initializing AppPreferences
      final restartedPrefs = await AppPreferences.init();
      final restartedController = ThemeController(restartedPrefs);

      expect(restartedController.themeMode, ThemeMode.dark);

      // Switch to Light Mode
      await restartedController.setThemeMode(ThemeMode.light);
      expect(restartedController.themeMode, ThemeMode.light);

      // Simulate second app restart
      final restartedPrefs2 = await AppPreferences.init();
      final restartedController2 = ThemeController(restartedPrefs2);
      expect(restartedController2.themeMode, ThemeMode.light);
    });

    test('Measurement units persist and restore on app restart', () async {
      final prefs = await AppPreferences.init();
      expect(prefs.measurementUnit, MeasurementUnitSystem.metric);

      await prefs.setMeasurementUnit(MeasurementUnitSystem.imperial);
      expect(prefs.measurementUnit, MeasurementUnitSystem.imperial);

      // Simulate restart
      final restartedPrefs = await AppPreferences.init();
      expect(restartedPrefs.measurementUnit, MeasurementUnitSystem.imperial);
    });

    test('Daily reminders and weekly digest preferences persist', () async {
      final prefs = await AppPreferences.init();
      expect(prefs.dailyRemindersEnabled, isTrue);
      expect(prefs.weeklyDigestEnabled, isTrue);

      await prefs.setDailyRemindersEnabled(false);
      await prefs.setWeeklyDigestEnabled(false);

      expect(prefs.dailyRemindersEnabled, isFalse);
      expect(prefs.weeklyDigestEnabled, isFalse);

      // Simulate restart
      final restartedPrefs = await AppPreferences.init();
      expect(restartedPrefs.dailyRemindersEnabled, isFalse);
      expect(restartedPrefs.weeklyDigestEnabled, isFalse);
    });
  });
}
