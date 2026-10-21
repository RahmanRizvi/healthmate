import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/preferences/app_preferences.dart';
import 'package:healthmate/core/services/notification_service.dart';
import 'package:healthmate/core/theme/theme_controller.dart';
import 'package:healthmate/data/models/daily_goals.dart';
import 'package:healthmate/data/models/user_profile.dart';
import 'package:healthmate/data/repositories/onboarding_repository.dart';
import 'package:healthmate/domain/services/onboarding_service.dart';
import 'package:healthmate/main.dart';
import 'package:healthmate/presentation/settings/views/about_screen.dart';
import 'package:healthmate/presentation/settings/views/bmi_details_screen.dart';
import 'package:healthmate/presentation/settings/views/edit_goals_screen.dart';
import 'package:healthmate/presentation/settings/views/edit_profile_screen.dart';
import 'package:healthmate/presentation/settings/views/privacy_security_screen.dart';
import 'package:healthmate/presentation/settings/views/settings_screen.dart';
import 'package:healthmate/presentation/settings/views/terms_of_service_screen.dart';
import 'package:healthmate/presentation/settings/views/weekly_digest_screen.dart';

import 'package:healthmate/data/models/health_record.dart';
import 'package:healthmate/data/repositories/health_record_repository.dart';
import 'package:healthmate/domain/services/analytics_service.dart';
import 'package:healthmate/domain/services/health_record_service.dart';

class FakeHealthRecordRepository implements IHealthRecordRepository {
  final Map<String, HealthRecord> records = {};

  @override
  Future<int> deleteRecord(int id) async {
    records.removeWhere((_, r) => r.id == id);
    return 1;
  }

  @override
  Future<List<HealthRecord>> getAllRecords() async {
    final list = records.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<HealthRecord?> getRecordByDate(String date) async => records[date];

  @override
  Future<HealthRecord?> getRecordById(int id) async =>
      records.values.firstWhere((r) => r.id == id);

  @override
  Future<List<HealthRecord>> getRecordsForDateRange(String s, String e) async =>
      records.values.where((r) => r.date.compareTo(s) >= 0 && r.date.compareTo(e) <= 0).toList();

  @override
  Future<void> incrementWater(String date, int amountMl) async {
    final existing = records[date];
    if (existing != null) {
      records[date] = existing.copyWith(water: existing.water + amountMl);
    } else {
      records[date] = HealthRecord(
        date: date,
        steps: 0,
        calories: 0,
        water: amountMl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<int> saveRecord(HealthRecord record) async {
    records[record.date] = record;
    return 1;
  }

  @override
  Future<int> updateRecord(HealthRecord record) async {
    records[record.date] = record;
    return 1;
  }
}

class FakeOnboardingRepository implements IOnboardingRepository {
  UserProfile? profile;
  DailyGoals? goals;

  @override
  Future<UserProfile?> getUserProfile() async => profile;

  @override
  Future<void> saveUserProfile(UserProfile p) async {
    profile = p;
  }

  @override
  Future<DailyGoals?> getDailyGoals() async => goals;

  @override
  Future<void> saveDailyGoals(DailyGoals g) async {
    goals = g;
  }

  @override
  Future<bool> isOnboardingCompleted() async => profile != null && goals != null;
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late FakeOnboardingRepository fakeRepo;
  late FakeHealthRecordRepository fakeRecordRepo;
  late OnboardingService onboardingService;
  late HealthRecordService recordService;
  late AnalyticsService analyticsService;
  late AppPreferences preferences;
  late ThemeController themeController;
  late NotificationService notificationService;

  setUp(() {
    fakeRepo = FakeOnboardingRepository();
    fakeRecordRepo = FakeHealthRecordRepository();
    fakeRepo.profile = UserProfile(
      id: 1,
      fullName: 'Alex Morgan',
      dateOfBirth: DateTime(1998, 5, 14),
      gender: 'Male',
      heightCm: 178.0,
      weightKg: 72.4,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );
    fakeRepo.goals = DailyGoals(
      id: 1,
      stepsGoal: 10000,
      waterGoalMl: 2500,
      caloriesGoalKcal: 500,
      updatedAt: DateTime(2026, 1, 1),
    );

    onboardingService = OnboardingService(repository: fakeRepo);
    recordService = HealthRecordService(repository: fakeRecordRepo);
    analyticsService = AnalyticsService(repository: fakeRecordRepo);
    preferences = AppPreferences.createInMemory({
      'theme_mode': 'system',
      'measurement_units': 'metric',
      'daily_reminders_enabled': true,
      'weekly_digest_enabled': true,
    });
    themeController = ThemeController(preferences);
    notificationService = NotificationService();
  });

  Widget createTestWidget({Widget? child}) {
    return HealthMateApp(
      onboardingService: onboardingService,
      recordService: recordService,
      analyticsService: analyticsService,
      preferences: preferences,
      themeController: themeController,
      notificationService: notificationService,
      home: child ?? const SettingsScreen(),
    );
  }

  group('SettingsScreen Widget Tests', () {
    testWidgets('Renders all cards and elements matching Figma screenshot',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Heading & Subtitle
      expect(find.text('Settings'), findsNWidgets(2)); // Title and bottom nav
      expect(find.text('Manage your profile and preferences.'), findsOneWidget);

      // Profile Card
      expect(find.text('AM'), findsOneWidget); // Avatar initials
      expect(find.text('Alex Morgan'), findsOneWidget);
      expect(find.textContaining('Male • 28 yrs'), findsOneWidget);
      expect(find.text('178'), findsOneWidget);
      expect(find.text('72.4'), findsOneWidget);
      expect(find.text('28'), findsOneWidget);

      // BMI Card
      expect(find.text('Body Mass Index'), findsOneWidget);
      expect(find.text('22.9'), findsOneWidget);
      expect(find.textContaining('Normal (22.9)'), findsOneWidget);
      expect(find.text('Based on 178 cm & 72.4 kg'), findsOneWidget);
      expect(find.text('Details'), findsOneWidget);

      // Daily Goals Card
      expect(find.text('Daily goals'), findsOneWidget);
      expect(find.text('Steps per day'), findsOneWidget);
      expect(find.text('10,000'), findsOneWidget);
      expect(find.text('Water intake'), findsOneWidget);
      expect(find.text('2,500'), findsOneWidget);
      expect(find.text('Active burn'), findsOneWidget);
      expect(find.text('500'), findsOneWidget);

      // Preferences Card
      expect(find.text('Preferences'), findsOneWidget);
      expect(find.text('Daily reminders'), findsOneWidget);
      expect(find.text('Measurement units'), findsOneWidget);
      expect(find.text('Weekly health digest'), findsOneWidget);
      expect(find.text('Theme'), findsNothing);

      // About Card
      expect(find.text('Mindful vitality companion'), findsOneWidget);

      // Legal & Security
      expect(find.text('Privacy & Data Security'), findsOneWidget);
      expect(find.text('Terms of Service'), findsOneWidget);
      expect(
        find.textContaining('Your health data is securely encrypted on this device'),
        findsOneWidget,
      );
    });

    testWidgets('ThemeController updates themeMode and persists setting',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(themeController.themeMode, ThemeMode.system);

      themeController.setThemeMode(ThemeMode.dark);
      await tester.pumpAndSettle();
      expect(themeController.themeMode, ThemeMode.dark);
      expect(preferences.themeMode, ThemeMode.dark);

      themeController.setThemeMode(ThemeMode.light);
      await tester.pumpAndSettle();
      expect(themeController.themeMode, ThemeMode.light);
      expect(preferences.themeMode, ThemeMode.light);

      themeController.setThemeMode(ThemeMode.system);
      await tester.pumpAndSettle();
      expect(themeController.themeMode, ThemeMode.system);
    });

    testWidgets('Tapping Edit Profile allows updating profile and persists to SQLite',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Edit Profile
      await tester.tap(find.byKey(const Key('edit_profile_button')));
      await tester.pumpAndSettle();

      expect(find.byType(EditProfileScreen), findsOneWidget);
      expect(find.text('Update Personal Details'), findsOneWidget);

      // Modify Name
      final nameFinder = find.widgetWithText(TextFormField, 'Alex Morgan');
      await tester.enterText(nameFinder, 'Taylor Swift');

      // Tap Save Changes
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
      await tester.pumpAndSettle();

      // Returned to SettingsScreen and updated name is reflected
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('Taylor Swift'), findsOneWidget);
      expect(find.text('TS'), findsOneWidget); // Avatar updated to TS
      expect(fakeRepo.profile!.fullName, 'Taylor Swift');
      expect(fakeRepo.profile!.id, 1); // ID preserved
    });

    testWidgets('Tapping Edit Goals allows updating targets and persists to SQLite',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Edit Goals
      await tester.tap(find.byKey(const Key('edit_goals_button')));
      await tester.pumpAndSettle();

      expect(find.byType(EditGoalsScreen), findsOneWidget);

      // Increment steps (+500)
      final plusButtons = find.widgetWithIcon(InkWell, Icons.add_rounded);
      await tester.tap(plusButtons.first);
      await tester.pumpAndSettle();

      // Tap Save Changes
      await tester.tap(find.widgetWithText(ElevatedButton, 'Save Changes'));
      await tester.pumpAndSettle();

      // Returned to SettingsScreen and steps updated to 10,500
      expect(find.byType(SettingsScreen), findsOneWidget);
      expect(find.text('10,500'), findsOneWidget);
      expect(fakeRepo.goals!.stepsGoal, 10500);
      expect(fakeRepo.goals!.id, 1);
    });

    testWidgets('Tapping BMI Details opens BmiDetailsScreen with complete information',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // Tap Details
      await tester.tap(find.byKey(const Key('bmi_details_button')));
      await tester.pumpAndSettle();

      expect(find.byType(BmiDetailsScreen), findsOneWidget);
      expect(find.text('BMI Information'), findsOneWidget);
      expect(find.text('BMI = Weight (kg) / [Height (m)]²'), findsOneWidget);
      expect(find.text('Screening Tool, Not Diagnosis'), findsOneWidget);
      expect(find.text('Pediatric Considerations'), findsOneWidget);
    });

    testWidgets('Informational screens (About, Privacy, Terms, Weekly Digest) open properly',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      // 1. Weekly Digest
      await tester.scrollUntilVisible(find.byKey(const Key('weekly_digest_tile')), 100);
      await tester.tap(find.byKey(const Key('weekly_digest_tile')));
      await tester.pumpAndSettle();
      expect(find.byType(WeeklyDigestScreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back).first);
      await tester.pumpAndSettle();

      // 2. About
      await tester.scrollUntilVisible(find.byKey(const Key('about_card_tap')), 100);
      await tester.tap(find.byKey(const Key('about_card_tap')));
      await tester.pumpAndSettle();
      expect(find.byType(AboutScreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back).first);
      await tester.pumpAndSettle();

      // 3. Privacy
      await tester.scrollUntilVisible(find.byKey(const Key('privacy_security_tile')), 100);
      await tester.tap(find.byKey(const Key('privacy_security_tile')));
      await tester.pumpAndSettle();
      expect(find.byType(PrivacySecurityScreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back).first);
      await tester.pumpAndSettle();

      // 4. Terms
      await tester.scrollUntilVisible(find.byKey(const Key('terms_of_service_tile')), 100);
      await tester.tap(find.byKey(const Key('terms_of_service_tile')));
      await tester.pumpAndSettle();
      expect(find.byType(TermsOfServiceScreen), findsOneWidget);
      await tester.tap(find.byIcon(Icons.arrow_back).first);
      await tester.pumpAndSettle();
    });

    testWidgets('Renders cleanly on a compact mobile screen without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360, 640);
      tester.view.devicePixelRatio = 1.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestWidget());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
    });
  });
}
