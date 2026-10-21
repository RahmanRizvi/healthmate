import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/data/models/daily_goals.dart';
import 'package:healthmate/data/models/health_record.dart';
import 'package:healthmate/data/models/user_profile.dart';
import 'package:healthmate/data/repositories/health_record_repository.dart';
import 'package:healthmate/data/repositories/onboarding_repository.dart';
import 'package:healthmate/domain/services/analytics_service.dart';
import 'package:healthmate/domain/services/health_record_service.dart';
import 'package:healthmate/domain/services/insights_service.dart';
import 'package:healthmate/domain/services/onboarding_service.dart';
import 'package:healthmate/main.dart';
import 'package:healthmate/presentation/progress/viewmodels/progress_viewmodel.dart';
import 'package:healthmate/presentation/progress/views/progress_screen.dart';

class MockOnboardingRepo implements IOnboardingRepository {
  DailyGoals? goals = DailyGoals(
    stepsGoal: 10000,
    waterGoalMl: 2500,
    caloriesGoalKcal: 500,
    updatedAt: DateTime.now(),
  );

  @override
  Future<DailyGoals?> getDailyGoals() async => goals;

  @override
  Future<UserProfile?> getUserProfile() async => null;

  @override
  Future<bool> isOnboardingCompleted() async => true;

  @override
  Future<void> saveDailyGoals(DailyGoals g) async {
    goals = g;
  }

  @override
  Future<void> saveUserProfile(UserProfile p) async {}
}

class MockRecordRepo implements IHealthRecordRepository {
  final Map<int, HealthRecord> records = {};

  @override
  Future<int> deleteRecord(int id) async {
    records.remove(id);
    return 1;
  }

  @override
  Future<List<HealthRecord>> getAllRecords() async {
    final list = records.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<HealthRecord?> getRecordByDate(String date) async {
    try {
      return records.values.firstWhere((r) => r.date == date);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<HealthRecord?> getRecordById(int id) async => records[id];

  @override
  Future<List<HealthRecord>> getRecordsForDateRange(String start, String end) async {
    return records.values
        .where((r) => r.date.compareTo(start) >= 0 && r.date.compareTo(end) <= 0)
        .toList();
  }

  @override
  Future<void> incrementWater(String date, int amountMl) async {}

  @override
  Future<int> saveRecord(HealthRecord record) async {
    final id = record.id ?? (records.length + 1);
    final saved = record.copyWith(id: id);
    records[id] = saved;
    return id;
  }

  @override
  Future<int> updateRecord(HealthRecord record) async {
    if (record.id != null) {
      records[record.id!] = record;
      return 1;
    }
    return 0;
  }
}

void main() {
  group('ProgressScreen Widget Tests', () {
    late MockRecordRepo recordRepo;
    late MockOnboardingRepo onboardingRepo;
    late AnalyticsService analyticsService;
    late InsightsService insightsService;
    late OnboardingService onboardingService;
    late HealthRecordService recordService;

    setUp(() {
      recordRepo = MockRecordRepo();
      onboardingRepo = MockOnboardingRepo();
      analyticsService = AnalyticsService(repository: recordRepo);
      insightsService = InsightsService();
      onboardingService = OnboardingService(repository: onboardingRepo);
      recordService = HealthRecordService(repository: recordRepo);

      // Seed data to reproduce Figma Screenshot:
      // Oct 14 - 20 (or current week) with:
      // 8,420 avg steps, 485 avg kcal, 2.1 L avg water
      // 5 of 6 days met steps goal, 4 of 6 met water, 5 of 6 met calories
      recordRepo.records[1] = HealthRecord(
        id: 1,
        date: '2026-10-19', // Monday
        steps: 8200,
        calories: 460,
        water: 2200,
        createdAt: DateTime(2026, 10, 19, 12, 0),
        updatedAt: DateTime(2026, 10, 19, 12, 0),
      );
      recordRepo.records[2] = HealthRecord(
        id: 2,
        date: '2026-10-20', // Tuesday
        steps: 8240,
        calories: 540,
        water: 2500,
        createdAt: DateTime(2026, 10, 20, 12, 0),
        updatedAt: DateTime(2026, 10, 20, 12, 0),
      );
      recordRepo.records[3] = HealthRecord(
        id: 3,
        date: '2026-10-21', // Wednesday
        steps: 7100,
        calories: 410,
        water: 1500,
        createdAt: DateTime(2026, 10, 21, 12, 0),
        updatedAt: DateTime(2026, 10, 21, 12, 0),
      );
      recordRepo.records[4] = HealthRecord(
        id: 4,
        date: '2026-10-22', // Thursday (Best)
        steps: 10200,
        calories: 550,
        water: 2500,
        createdAt: DateTime(2026, 10, 22, 12, 0),
        updatedAt: DateTime(2026, 10, 22, 12, 0),
      );
      recordRepo.records[5] = HealthRecord(
        id: 5,
        date: '2026-10-23', // Friday
        steps: 8930,
        calories: 510,
        water: 2100,
        createdAt: DateTime(2026, 10, 23, 12, 0),
        updatedAt: DateTime(2026, 10, 23, 12, 0),
      );
      recordRepo.records[6] = HealthRecord(
        id: 6,
        date: '2026-10-24', // Saturday
        steps: 7850,
        calories: 440,
        water: 1800,
        createdAt: DateTime(2026, 10, 24, 12, 0),
        updatedAt: DateTime(2026, 10, 24, 12, 0),
      );
    });

    Widget createTestApp({Widget? home}) {
      return HealthMateApp(
        onboardingService: onboardingService,
        recordService: recordService,
        analyticsService: analyticsService,
        insightsService: insightsService,
        home: home ??
            ProgressScreen(
              viewModel: ProgressViewModel(
                analyticsService: analyticsService,
                insightsService: insightsService,
                onboardingService: onboardingService,
                recordRepository: recordRepo,
                initialDate: DateTime(2026, 10, 24),
              ),
            ),
      );
    }

    testWidgets('ProgressScreen renders all cards, charts, and values matching Figma',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify Header & Title
      expect(find.text('HealthMate'), findsOneWidget);
      expect(find.text('Your progress'), findsOneWidget);
      expect(find.text('Small steps. Meaningful progress.'), findsOneWidget);

      // Verify Period Selector
      expect(find.text('Week'), findsOneWidget);
      expect(find.text('Month'), findsOneWidget);
      expect(find.text('Oct 19 - 25'), findsOneWidget);

      // Verify 3 Analytics Summary Cards
      expect(find.text('Avg. steps/d'), findsOneWidget);
      expect(find.text('Avg. kcal/d'), findsOneWidget);
      expect(find.text('Avg. water/d'), findsOneWidget);
      expect(find.text('8,420'), findsOneWidget); // 50520 / 6 = 8420
      expect(find.text('485'), findsOneWidget); // 2910 / 6 = 485
      expect(find.text('2.1 L'), findsOneWidget); // 12600 / 6 = 2100 ml = 2.1 L

      // Verify Steps Activity Card
      expect(find.textContaining('Steps activity'), findsOneWidget);
      expect(find.text('Daily walking distribution'), findsOneWidget);
      expect(find.text('Goal 10k'), findsOneWidget);
      final bestFinder = find.textContaining('Best:');
      expect(bestFinder, findsOneWidget);
      // ignore: avoid_print
      print('DEBUG BEST TEXT: ${(bestFinder.evaluate().first.widget as Text).data}');

      // Verify Daily Goal Completion Section
      expect(find.text('Daily goal completion'), findsOneWidget);
      expect(find.text('Days target achieved this week'), findsOneWidget);
      expect(find.text('Steps (10,000 / day)'), findsOneWidget);
      expect(find.text('Water intake (2,500 ml)'), findsOneWidget);
      expect(find.text('Active calories (500 kcal)'), findsOneWidget);

      // Verify Hydration Trend Card
      expect(find.text('Hydration trend'), findsOneWidget);
      expect(find.text('Daily fluid intake in milliliters'), findsOneWidget);
      expect(find.text('Target: 2,500 ml'), findsOneWidget);

      // Scroll down to check insights and records card
      await tester.drag(find.text('Your progress'), const Offset(0, -500));
      await tester.pumpAndSettle();

      // Verify Insight Card
      expect(find.text('Your insight'), findsOneWidget);
      expect(find.text('New'), findsOneWidget);

      // Verify View All Records Card
      expect(find.text('View all records'), findsOneWidget);
      expect(find.text('Review and manage all 6 saved daily entries'), findsOneWidget);

      // Verify Wellness Tip
      expect(find.textContaining('Walking 15 minutes after lunch'), findsOneWidget);
    });

    testWidgets('Toggling Month updates view and reloads data',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(find.text('Oct 19 - 25'), findsOneWidget);

      // Tap "Month"
      await tester.tap(find.text('Month'));
      await tester.pumpAndSettle();

      // Date badge updates to month label
      expect(find.text('Oct 2026'), findsOneWidget);

      // Tap "Day"
      await tester.tap(find.text('Day'));
      await tester.pumpAndSettle();

      // Date badge updates to day label
      expect(find.text('Oct 24, 2026'), findsOneWidget);

      // Tap Export icon to open Image Export dialog
      final exportIconFinder = find.byIcon(Icons.file_download_outlined);
      expect(exportIconFinder, findsOneWidget);
      await tester.tap(exportIconFinder);
      await tester.pumpAndSettle();

      // Verify dialog shows Save Report to Gallery and Preview Card
      expect(find.text('Save Report to Gallery'), findsOneWidget);
      expect(find.text('Save to Gallery'), findsOneWidget);
      expect(find.text('CSV'), findsOneWidget);
    });

    testWidgets('Renders cleanly on a compact mobile screen without overflow',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(360 * 2, 640 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Your progress'), findsOneWidget);

      // Scroll all the way down
      await tester.drag(find.text('Your progress'), const Offset(0, -600));
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('View all records'), findsOneWidget);
    });
  });
}
