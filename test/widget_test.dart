import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/data/models/daily_goals.dart';
import 'package:healthmate/data/models/health_record.dart';
import 'package:healthmate/data/models/user_profile.dart';
import 'package:healthmate/data/repositories/health_record_repository.dart';
import 'package:healthmate/data/repositories/onboarding_repository.dart';
import 'package:healthmate/domain/services/health_record_service.dart';
import 'package:healthmate/domain/services/onboarding_service.dart';
import 'package:healthmate/main.dart';
import 'package:healthmate/presentation/dashboard/views/dashboard_screen.dart';
import 'package:healthmate/presentation/records/views/add_record_screen.dart';

class FakeOnboardingRepository implements IOnboardingRepository {
  UserProfile? profile;
  DailyGoals? goals;

  @override
  Future<DailyGoals?> getDailyGoals() async => goals;

  @override
  Future<UserProfile?> getUserProfile() async => profile;

  @override
  Future<bool> isOnboardingCompleted() async =>
      profile != null && goals != null;

  @override
  Future<void> saveDailyGoals(DailyGoals g) async {
    goals = g;
  }

  @override
  Future<void> saveUserProfile(UserProfile p) async {
    profile = p;
  }
}

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
}

void main() {
  testWidgets('Dashboard renders user greeting, today activity, and opens Add Record screen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeOnboarding = FakeOnboardingRepository();
    fakeOnboarding.profile = UserProfile(
      id: 1,
      fullName: 'Alex Morgan',
      dateOfBirth: DateTime(1998, 5, 14),
      gender: 'Female',
      heightCm: 172.0,
      weightKg: 68.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    fakeOnboarding.goals = DailyGoals.defaults();

    final fakeRecords = FakeHealthRecordRepository();
    final onboardingService = OnboardingService(repository: fakeOnboarding);
    final recordService = HealthRecordService(repository: fakeRecords);

    await tester.pumpWidget(
      HealthMateApp(
        onboardingService: onboardingService,
        recordService: recordService,
        home: const DashboardScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Verify Greeting with personalized user name
    expect(find.textContaining('Alex'), findsOneWidget);
    expect(find.text('Your health, at a glance.'), findsOneWidget);
    expect(find.text("Today's activity"), findsOneWidget);
    expect(find.text('Steps walked'), findsOneWidget);
    expect(find.text('Calories'), findsOneWidget);
    expect(find.text('Water intake'), findsOneWidget);
    expect(find.text("Add today's record"), findsOneWidget);

    // Verify tapping "Add today's record" navigates to AddRecordScreen
    await tester.tap(find.text("Add today's record"));
    await tester.pumpAndSettle();

    expect(find.text('Add Record'), findsOneWidget);
    expect(find.text('Log your daily activity'), findsOneWidget);
    expect(find.text('Date of activity'), findsOneWidget);
    expect(find.text('Cancel'), findsOneWidget);
    expect(find.text('Save Record'), findsOneWidget);
  });

  testWidgets('AddRecordScreen steppers and quick-add water chips function properly',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeOnboarding = FakeOnboardingRepository();
    fakeOnboarding.goals = DailyGoals.defaults();
    final fakeRecords = FakeHealthRecordRepository();

    final onboardingService = OnboardingService(repository: fakeOnboarding);
    final recordService = HealthRecordService(repository: fakeRecords);

    await tester.pumpWidget(
      HealthMateApp(
        onboardingService: onboardingService,
        recordService: recordService,
        home: AddRecordScreen(selectedDate: DateTime.now()),
      ),
    );
    await tester.pumpAndSettle();

    // Verify quick-add water chips exist
    expect(find.text('+150 ml'), findsOneWidget);
    expect(find.text('+250 ml'), findsOneWidget);
    expect(find.text('+350 ml'), findsOneWidget);
    expect(find.text('+500 ml'), findsOneWidget);

    // Tap +250 ml quick add
    await tester.tap(find.text('+250 ml'));
    await tester.pumpAndSettle();

    // Verify Save Record persists
    await tester.tap(find.text('Save Record'));
    await tester.pumpAndSettle();

    expect(fakeRecords.records.isNotEmpty, isTrue);
    expect(fakeRecords.records.values.first.water, equals(250));
  });

  testWidgets('Dashboard quick water button adds 250ml directly',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeOnboarding = FakeOnboardingRepository();
    fakeOnboarding.profile = UserProfile(
      id: 1,
      fullName: 'Alex Morgan',
      dateOfBirth: DateTime(1998, 5, 14),
      gender: 'Female',
      heightCm: 172.0,
      weightKg: 68.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    fakeOnboarding.goals = DailyGoals.defaults();

    final fakeRecords = FakeHealthRecordRepository();
    final onboardingService = OnboardingService(repository: fakeOnboarding);
    final recordService = HealthRecordService(repository: fakeRecords);

    await tester.pumpWidget(
      HealthMateApp(
        onboardingService: onboardingService,
        recordService: recordService,
        home: const DashboardScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Find and tap the +250 ml button on dashboard
    final quickAddButton = find.text('250 ml');
    expect(quickAddButton, findsOneWidget);

    await tester.tap(quickAddButton);
    await tester.pumpAndSettle();

    expect(fakeRecords.records.isNotEmpty, isTrue);
    expect(fakeRecords.records.values.first.water, equals(250));
  });

  testWidgets('Dashboard top bar plus icon opens Add Record screen',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeOnboarding = FakeOnboardingRepository();
    fakeOnboarding.profile = UserProfile(
      id: 1,
      fullName: 'Alex Morgan',
      dateOfBirth: DateTime(1998, 5, 14),
      gender: 'Female',
      heightCm: 172.0,
      weightKg: 68.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    fakeOnboarding.goals = DailyGoals.defaults();

    final fakeRecords = FakeHealthRecordRepository();
    final onboardingService = OnboardingService(repository: fakeOnboarding);
    final recordService = HealthRecordService(repository: fakeRecords);

    await tester.pumpWidget(
      HealthMateApp(
        onboardingService: onboardingService,
        recordService: recordService,
        home: const DashboardScreen(),
      ),
    );
    await tester.pumpAndSettle();

    // Find the circular plus button in the topbar
    final plusButton = find.byKey(const Key('dashboard_add_record_button'));
    expect(plusButton, findsOneWidget);

    await tester.tap(plusButton);
    await tester.pumpAndSettle();

    // Verify Add Record screen is opened
    expect(find.text('Add Record'), findsOneWidget);
    expect(find.text('Log your daily activity'), findsOneWidget);
    expect(find.text('Save Record'), findsOneWidget);
  });
}
