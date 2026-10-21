import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/preferences/app_preferences.dart';
import 'package:healthmate/core/services/notification_service.dart';
import 'package:healthmate/core/theme/theme_controller.dart';
import 'package:healthmate/data/models/daily_goals.dart';
import 'package:healthmate/data/models/health_record.dart';
import 'package:healthmate/data/models/user_profile.dart';
import 'package:healthmate/data/repositories/health_record_repository.dart';
import 'package:healthmate/data/repositories/onboarding_repository.dart';
import 'package:healthmate/domain/services/analytics_service.dart';
import 'package:healthmate/domain/services/health_record_service.dart';
import 'package:healthmate/domain/services/onboarding_service.dart';
import 'package:healthmate/main.dart';
import 'package:healthmate/presentation/dashboard/views/dashboard_screen.dart';
import 'package:healthmate/presentation/onboarding/views/welcome_screen.dart';
import 'package:healthmate/presentation/splash/views/splash_screen.dart';

class FakeOnboardingRepo implements IOnboardingRepository {
  bool completed = false;

  @override
  Future<DailyGoals?> getDailyGoals() async => null;

  @override
  Future<UserProfile?> getUserProfile() async => null;

  @override
  Future<bool> isOnboardingCompleted() async => completed;

  @override
  Future<void> saveDailyGoals(DailyGoals g) async {}

  @override
  Future<void> saveUserProfile(UserProfile p) async {}
}

class FakeRecordsRepo implements IHealthRecordRepository {
  @override
  Future<int> deleteRecord(int id) async => 0;

  @override
  Future<List<HealthRecord>> getAllRecords() async => [];

  @override
  Future<HealthRecord?> getRecordByDate(String date) async => null;

  @override
  Future<HealthRecord?> getRecordById(int id) async => null;

  @override
  Future<List<HealthRecord>> getRecordsForDateRange(String s, String e) async => [];

  @override
  Future<void> incrementWater(String date, int amountMl) async {}

  @override
  Future<int> saveRecord(HealthRecord record) async => 1;

  @override
  Future<int> updateRecord(HealthRecord record) async => 1;
}

void main() {
  testWidgets('SplashScreen renders logo, title, tagline and navigates to Welcome if not onboarded',
      (WidgetTester tester) async {
    final fakeRepo = FakeOnboardingRepo();
    final onboardingService = OnboardingService(repository: fakeRepo);
    final fakeRecords = FakeRecordsRepo();
    final recordService = HealthRecordService(repository: fakeRecords);
    final analyticsService = AnalyticsService(repository: fakeRecords);
    final preferences = AppPreferences.createInMemory({});
    final themeController = ThemeController(preferences);
    final notificationService = NotificationService();

    await tester.pumpWidget(
      HealthMateApp(
        onboardingService: onboardingService,
        recordService: recordService,
        analyticsService: analyticsService,
        preferences: preferences,
        themeController: themeController,
        notificationService: notificationService,
        home: const SplashScreen(minDisplayDuration: Duration(milliseconds: 100)),
      ),
    );

    expect(find.text('HealthMate'), findsOneWidget);
    expect(find.text('Mindful vitality companion'), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    // Wait for the animation & startup delay
    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.byType(WelcomeScreen), findsOneWidget);
  });

  testWidgets('SplashScreen navigates to Dashboard if onboarding completed',
      (WidgetTester tester) async {
    final fakeRepo = FakeOnboardingRepo()..completed = true;
    final onboardingService = OnboardingService(repository: fakeRepo);
    final fakeRecords = FakeRecordsRepo();
    final recordService = HealthRecordService(repository: fakeRecords);
    final analyticsService = AnalyticsService(repository: fakeRecords);
    final preferences = AppPreferences.createInMemory({});
    final themeController = ThemeController(preferences);
    final notificationService = NotificationService();

    await tester.pumpWidget(
      HealthMateApp(
        onboardingService: onboardingService,
        recordService: recordService,
        analyticsService: analyticsService,
        preferences: preferences,
        themeController: themeController,
        notificationService: notificationService,
        home: const SplashScreen(minDisplayDuration: Duration(milliseconds: 100)),
      ),
    );

    await tester.pump(const Duration(milliseconds: 200));
    await tester.pumpAndSettle();

    expect(find.byType(DashboardScreen), findsOneWidget);
  });
}
