import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/preferences/app_preferences.dart';
import 'core/services/notification_service.dart';
import 'core/theme/app_theme.dart';
import 'core/theme/theme_controller.dart';
import 'data/database/app_database.dart';
import 'data/repositories/health_record_repository.dart';
import 'data/repositories/onboarding_repository.dart';
import 'domain/services/analytics_service.dart';
import 'domain/services/bmi_service.dart';
import 'domain/services/health_record_service.dart';
import 'domain/services/insights_service.dart';
import 'domain/services/onboarding_service.dart';
import 'presentation/splash/views/splash_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  AppPreferences? preferences;
  try {
    preferences = await AppPreferences.init();
  } catch (e) {
    debugPrint('AppPreferences init error: $e');
  }

  final effectivePrefs = preferences ?? AppPreferences();
  final themeController = ThemeController(effectivePrefs);
  final notificationService = NotificationService();

  try {
    await notificationService.initialize();
    if (effectivePrefs.dailyRemindersEnabled) {
      await notificationService.scheduleDailyReminder(
        hour: effectivePrefs.reminderHour,
        minute: effectivePrefs.reminderMinute,
      );
    }
    if (effectivePrefs.weeklyDigestEnabled) {
      await notificationService.scheduleWeeklyDigest();
    }
  } catch (e) {
    debugPrint('NotificationService startup error: $e');
  }

  runApp(
    HealthMateApp(
      preferences: effectivePrefs,
      themeController: themeController,
      notificationService: notificationService,
    ),
  );
}

/// Root widget of the HealthMate application.
class HealthMateApp extends StatelessWidget {
  final OnboardingService? onboardingService;
  final HealthRecordService? recordService;
  final AnalyticsService? analyticsService;
  final InsightsService? insightsService;
  final AppPreferences? preferences;
  final ThemeController? themeController;
  final NotificationService? notificationService;
  final Widget? home;

  const HealthMateApp({
    super.key,
    this.onboardingService,
    this.recordService,
    this.analyticsService,
    this.insightsService,
    this.preferences,
    this.themeController,
    this.notificationService,
    this.home,
  });

  @override
  Widget build(BuildContext context) {
    final effectivePrefs = preferences ?? AppPreferences();
    final effectiveThemeController =
        themeController ?? ThemeController(effectivePrefs);
    final effectiveNotificationService =
        notificationService ?? NotificationService();

    return MultiProvider(
      providers: [
        Provider<AppDatabase>(
          create: (_) => AppDatabase(),
          dispose: (_, db) => db.close(),
        ),
        ProxyProvider<AppDatabase, IOnboardingRepository>(
          update: (context, db, previous) => OnboardingRepository(db: db),
        ),
        ProxyProvider<IOnboardingRepository, OnboardingService>(
          update: (context, repo, previous) =>
              onboardingService ?? OnboardingService(repository: repo),
        ),
        Provider<BmiService>(
          create: (_) => BmiService(),
        ),
        ProxyProvider<AppDatabase, IHealthRecordRepository>(
          update: (context, db, previous) => HealthRecordRepository(db: db),
        ),
        ProxyProvider<IHealthRecordRepository, HealthRecordService>(
          update: (context, repo, previous) =>
              recordService ?? HealthRecordService(repository: repo),
        ),
        ProxyProvider<IHealthRecordRepository, AnalyticsService>(
          update: (context, repo, previous) =>
              analyticsService ?? AnalyticsService(repository: repo),
        ),
        Provider<InsightsService>(
          create: (_) => insightsService ?? InsightsService(),
        ),
        Provider<AppPreferences>.value(
          value: effectivePrefs,
        ),
        ChangeNotifierProvider<ThemeController>.value(
          value: effectiveThemeController,
        ),
        Provider<NotificationService>.value(
          value: effectiveNotificationService,
        ),
      ],
      child: Consumer<ThemeController>(
        builder: (context, controller, child) {
          return MaterialApp(
            debugShowCheckedModeBanner: false,
            title: 'HealthMate',
            theme: AppTheme.lightTheme,
            darkTheme: AppTheme.darkTheme,
            themeMode: controller.themeMode,
            home: home ?? const AppEntryRouter(),
          );
        },
      ),
    );
  }
}

/// Determines the starting screen based on SQLite onboarding persistence state with branded splash.
class AppEntryRouter extends StatelessWidget {
  const AppEntryRouter({super.key});

  @override
  Widget build(BuildContext context) {
    return const SplashScreen();
  }
}
