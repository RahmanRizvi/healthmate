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
import 'package:healthmate/presentation/records/views/records_screen.dart';

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
  Future<List<HealthRecord>> getRecordsForDateRange(String s, String e) async =>
      records.values.where((r) => r.date.compareTo(s) >= 0 && r.date.compareTo(e) <= 0).toList();

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
  group('Records and Record Details Widget Tests', () {
    late MockRecordRepo recordRepo;
    late MockOnboardingRepo onboardingRepo;
    late HealthRecordService recordService;
    late OnboardingService onboardingService;

    setUp(() {
      recordRepo = MockRecordRepo();
      onboardingRepo = MockOnboardingRepo();
      recordService = HealthRecordService(repository: recordRepo);
      onboardingService = OnboardingService(repository: onboardingRepo);

      // Seed records matching Figma Screenshots 1 & 2
      recordRepo.records[1] = HealthRecord(
        id: 1,
        date: '2026-10-24',
        steps: 7850,
        calories: 420,
        water: 1750,
        createdAt: DateTime(2026, 10, 24, 20, 45),
        updatedAt: DateTime(2026, 10, 24, 21, 12),
      );

      recordRepo.records[2] = HealthRecord(
        id: 2,
        date: '2026-10-23',
        steps: 10240,
        calories: 560,
        water: 2500,
        createdAt: DateTime(2026, 10, 23, 19, 0),
        updatedAt: DateTime(2026, 10, 23, 19, 30),
      );

      recordRepo.records[3] = HealthRecord(
        id: 3,
        date: '2026-10-22',
        steps: 6410,
        calories: 380,
        water: 1500,
        createdAt: DateTime(2026, 10, 22, 18, 0),
        updatedAt: DateTime(2026, 10, 22, 18, 0),
      );
    });

    Widget createTestApp({Widget? home}) {
      return HealthMateApp(
        onboardingService: onboardingService,
        recordService: recordService,
        home: home ?? const RecordsScreen(),
      );
    }

    testWidgets('RecordsScreen renders header, statistics, filters, search, and history cards',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Verify header & titles
      expect(find.text('HealthMate'), findsOneWidget);
      expect(find.text('Your records'), findsOneWidget);
      expect(find.text('Review your daily health activity.'), findsOneWidget);

      // Verify 3 summary statistics cards
      expect(find.text('3'), findsOneWidget); // Total records
      expect(find.text('Total records'), findsOneWidget);
      expect(find.text('8,167'), findsOneWidget); // Average steps
      expect(find.text('Avg steps'), findsOneWidget);
      expect(find.text('5.8L'), findsOneWidget); // Total water
      expect(find.text('Total water'), findsOneWidget);

      // Verify Search bar
      expect(find.text('Search records by date (e.g. Oct 24)'), findsOneWidget);

      // Verify Filter chips
      expect(find.text('Filter by date'), findsOneWidget);
      expect(find.text('All'), findsOneWidget);
      expect(find.text('Today'), findsOneWidget);
      expect(find.text('This week'), findsOneWidget);
      expect(find.text('This month'), findsOneWidget);

      // Verify + Add Record button
      expect(find.text('Add Record'), findsWidgets);

      // Verify section header
      expect(find.text('Daily history'), findsOneWidget);
      expect(find.text('3 records'), findsOneWidget);
      expect(find.text('Newest first'), findsOneWidget);

      // Verify cards exist
      expect(find.text('24 October 2026'), findsOneWidget);
      expect(find.text('23 October 2026'), findsOneWidget);
      expect(find.text('22 October 2026'), findsOneWidget);
      expect(find.text('View details'), findsNWidgets(3));
    });

    testWidgets('Search field dynamically filters records', (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Enter search query "24"
      await tester.enterText(
        find.widgetWithText(TextField, 'Search records by date (e.g. Oct 24)'),
        '24',
      );
      await tester.pumpAndSettle();

      expect(find.text('24 October 2026'), findsOneWidget);
      expect(find.text('23 October 2026'), findsNothing);
      expect(find.text('22 October 2026'), findsNothing);
      expect(find.text('1 records'), findsOneWidget);

      // Clear search
      await tester.tap(find.byIcon(Icons.close_rounded));
      await tester.pumpAndSettle();

      expect(find.text('3 records'), findsOneWidget);
    });

    testWidgets('Tapping View details navigates to RecordDetailsScreen and displays metrics',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Tap first "View details" (for 24 October 2026)
      await tester.tap(find.text('View details').first);
      await tester.pumpAndSettle();

      // Verify Record Details screen is open
      expect(find.text('Record Details'), findsOneWidget);
      expect(find.text('24 October 2026'), findsOneWidget);
      expect(find.text('Saturday'), findsOneWidget);
      expect(find.text('Daily summary'), findsOneWidget);

      // Verify Steps card
      expect(find.text('Steps walked'), findsOneWidget);
      expect(find.text('Goal: 10,000'), findsOneWidget);
      expect(find.text('7,850'), findsWidgets);
      expect(find.text('78.5% completed'), findsOneWidget);
      expect(find.text('2,150 steps remaining'), findsOneWidget);

      // Verify Calories card
      expect(find.text('Calories burned'), findsOneWidget);
      expect(find.text('Goal: 500 kcal'), findsOneWidget);
      expect(find.text('420'), findsWidgets);
      expect(find.text('84% of daily burn target'), findsOneWidget);
      expect(find.text('80 kcal remaining'), findsOneWidget);

      // Verify Water card
      expect(find.text('Water intake'), findsOneWidget);
      expect(find.text('Goal: 2,500 ml'), findsOneWidget);
      expect(find.text('1,750'), findsWidgets);
      expect(find.text('70% of hydration target'), findsOneWidget);
      expect(find.text('750 ml remaining'), findsOneWidget);

      // Verify Daily progress breakdown & Overall 78%
      expect(find.text('Daily progress'), findsOneWidget);
      expect(find.text('Overall 78%'), findsOneWidget);

      // Verify Action buttons
      expect(find.text('Edit Record'), findsOneWidget);
      expect(find.text('Delete Record'), findsOneWidget);

      // Verify Timestamps
      expect(find.textContaining('Recorded on 24 Oct 2026'), findsOneWidget);
      expect(find.textContaining('Last updated 24 Oct 2026'), findsOneWidget);
    });

    testWidgets('Delete Record shows confirmation dialog and removes record when confirmed',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Open details for record 1
      await tester.tap(find.text('View details').first);
      await tester.pumpAndSettle();

      // Tap "Delete Record" button
      await tester.tap(find.text('Delete Record'));
      await tester.pumpAndSettle();

      // Verify Confirmation Dialog
      expect(find.text('Delete record?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);

      // Cancel first
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();
      expect(recordRepo.records.containsKey(1), isTrue);

      // Tap Delete again and confirm
      await tester.tap(find.text('Delete Record'));
      await tester.pumpAndSettle();

      // Tap confirm Delete inside Dialog
      final confirmBtn = find.descendant(
        of: find.byType(Dialog),
        matching: find.text('Delete Record'),
      );
      await tester.tap(confirmBtn);
      await tester.pumpAndSettle();

      // Verify returned to Records screen and record 1 is removed
      expect(find.text('Your records'), findsOneWidget);
      expect(find.text('2 records'), findsOneWidget);
      expect(recordRepo.records.containsKey(1), isFalse);
    });

    testWidgets('Tapping Edit Record opens AddRecordScreen in edit mode and updates record',
        (WidgetTester tester) async {
      tester.view.physicalSize = const Size(1080, 2400);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      // Open details
      await tester.tap(find.text('View details').first);
      await tester.pumpAndSettle();

      // Tap "Edit Record"
      await tester.tap(find.text('Edit Record'));
      await tester.pumpAndSettle();

      // Verify form is in Edit Mode
      expect(find.text('Edit Record'), findsOneWidget);
      expect(find.text('Edit your daily activity'), findsOneWidget);
      expect(find.text('Update Record'), findsOneWidget);

      // Pre-populated values check
      expect(find.text('7850'), findsOneWidget);
      expect(find.text('420'), findsOneWidget);
      expect(find.text('1750'), findsOneWidget);

      // Tap Update Record
      await tester.tap(find.text('Update Record'));
      await tester.pumpAndSettle();

      // Returned to Record Details
      expect(find.text('Record Details'), findsOneWidget);
    });

    testWidgets('Renders properly without overflow on a compact mobile screen',
        (WidgetTester tester) async {
      // Small Android viewport: 360 x 640
      tester.view.physicalSize = const Size(360 * 2, 640 * 2);
      tester.view.devicePixelRatio = 2.0;
      addTearDown(() {
        tester.view.resetPhysicalSize();
        tester.view.resetDevicePixelRatio();
      });

      await tester.pumpWidget(createTestApp());
      await tester.pumpAndSettle();

      expect(tester.takeException(), isNull);
      expect(find.text('Your records'), findsOneWidget);

      // Scroll down
      await tester.drag(find.text('Your records'), const Offset(0, -300));
      await tester.pumpAndSettle();
      expect(tester.takeException(), isNull);
    });
  });
}
