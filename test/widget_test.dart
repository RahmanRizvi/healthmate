import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/data/models/daily_goals.dart';
import 'package:healthmate/data/models/user_profile.dart';
import 'package:healthmate/data/repositories/onboarding_repository.dart';
import 'package:healthmate/domain/services/onboarding_service.dart';
import 'package:healthmate/main.dart';
import 'package:healthmate/presentation/onboarding/views/bmi_analysis_screen.dart';
import 'package:healthmate/presentation/onboarding/views/daily_goals_screen.dart';
import 'package:healthmate/presentation/onboarding/views/personal_details_screen.dart';

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

void main() {
  testWidgets('HealthMateApp WelcomeScreen renders and navigates to Personal Details',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeRepo = FakeOnboardingRepository();
    final service = OnboardingService(repository: fakeRepo);

    await tester.pumpWidget(
      HealthMateApp(
        onboardingService: service,
      ),
    );

    // Initial pump for FutureBuilder in AppEntryRouter
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));

    // Verify Welcome Screen elements
    expect(find.text('Healthmate'), findsOneWidget);
    expect(find.text('Your wellness journey\nstarts here.'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
    expect(find.text('Your personal health companion'), findsOneWidget);
    expect(find.text('Activity'), findsOneWidget);
    expect(find.text('Hydration'), findsOneWidget);
    expect(find.text('Vitals'), findsOneWidget);

    // Tap Continue to navigate to Personal Details
    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();

    // Verify Personal Details Screen
    expect(find.text("Let's get to know you"), findsOneWidget);
    expect(find.text('STEP 1 OF 3'), findsOneWidget);
    expect(find.text('Personal Details'), findsOneWidget);
    expect(find.text('Full Name'), findsOneWidget);
    expect(find.text('Date of Birth'), findsOneWidget);
    expect(find.text('Gender'), findsOneWidget);
  });

  testWidgets('PersonalDetailsScreen renders form inputs and components',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeRepo = FakeOnboardingRepository();
    final service = OnboardingService(repository: fakeRepo);

    await tester.pumpWidget(
      HealthMateApp(
        onboardingService: service,
        home: const PersonalDetailsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text("Let's get to know you"), findsOneWidget);
    expect(find.text('Height'), findsOneWidget);
    expect(find.text('Weight'), findsOneWidget);
    expect(find.text('Age: --'), findsOneWidget);
    expect(find.text('Continue'), findsOneWidget);
  });

  testWidgets('BmiAnalysisScreen renders BMI snapshot and range components',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeRepo = FakeOnboardingRepository();
    fakeRepo.profile = UserProfile(
      id: 1,
      fullName: 'Alex Morgan',
      dateOfBirth: DateTime(1998, 5, 14),
      gender: 'Female',
      heightCm: 172.0,
      weightKg: 68.0,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    final service = OnboardingService(repository: fakeRepo);

    await tester.pumpWidget(
      HealthMateApp(
        onboardingService: service,
        home: const BmiAnalysisScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Your health snapshot'), findsOneWidget);
    expect(find.text('STEP 2 OF 3'), findsOneWidget);
    expect(find.text('BMI Analysis'), findsOneWidget);
    expect(find.text('YOUR BMI'), findsOneWidget);
    expect(find.text('Normal weight'), findsOneWidget);
    expect(find.text('23.0'), findsWidgets);
    expect(find.text('172 cm'), findsOneWidget);
    expect(find.text('68 kg'), findsOneWidget);
    expect(find.text('Edit details'), findsOneWidget);
  });

  testWidgets('DailyGoalsScreen renders step, water, and calorie cards',
      (WidgetTester tester) async {
    tester.view.physicalSize = const Size(1080, 2400);
    tester.view.devicePixelRatio = 2.0;
    addTearDown(() {
      tester.view.resetPhysicalSize();
      tester.view.resetDevicePixelRatio();
    });

    final fakeRepo = FakeOnboardingRepository();
    final service = OnboardingService(repository: fakeRepo);

    await tester.pumpWidget(
      HealthMateApp(
        onboardingService: service,
        home: const DailyGoalsScreen(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('Set your daily goals'), findsOneWidget);
    expect(find.text('STEP 3 OF 3'), findsOneWidget);
    expect(find.text('Daily Goals'), findsOneWidget);
    expect(find.text('Steps per day'), findsOneWidget);
    expect(find.text('Water per day'), findsOneWidget);
    expect(find.text('Daily calories goal'), findsOneWidget);
    expect(find.text('10,000'), findsOneWidget);
    expect(find.text('2,500'), findsOneWidget);
    expect(find.text('500'), findsOneWidget);
    expect(find.text('Start HealthMate'), findsOneWidget);
  });
}
