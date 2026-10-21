import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/utils/date_range_utils.dart';
import 'package:healthmate/data/models/daily_goals.dart';
import 'package:healthmate/data/models/health_record.dart';
import 'package:healthmate/data/models/user_profile.dart';
import 'package:healthmate/data/repositories/health_record_repository.dart';
import 'package:healthmate/data/repositories/onboarding_repository.dart';
import 'package:healthmate/domain/services/analytics_service.dart';
import 'package:healthmate/domain/services/insights_service.dart';
import 'package:healthmate/domain/services/onboarding_service.dart';
import 'package:healthmate/presentation/progress/viewmodels/progress_viewmodel.dart';

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
  group('ProgressViewModel Tests', () {
    late MockRecordRepo recordRepo;
    late MockOnboardingRepo onboardingRepo;
    late AnalyticsService analyticsService;
    late InsightsService insightsService;
    late OnboardingService onboardingService;

    setUp(() {
      recordRepo = MockRecordRepo();
      onboardingRepo = MockOnboardingRepo();
      analyticsService = AnalyticsService(repository: recordRepo);
      insightsService = InsightsService();
      onboardingService = OnboardingService(repository: onboardingRepo);

      // Seed records matching Figma screenshot
      recordRepo.records[1] = HealthRecord(
        id: 1,
        date: '2026-10-19',
        steps: 8200,
        calories: 460,
        water: 2200,
        createdAt: DateTime(2026, 10, 19, 12, 0),
        updatedAt: DateTime(2026, 10, 19, 12, 0),
      );
      recordRepo.records[2] = HealthRecord(
        id: 2,
        date: '2026-10-20',
        steps: 10240,
        calories: 540,
        water: 2500,
        createdAt: DateTime(2026, 10, 20, 12, 0),
        updatedAt: DateTime(2026, 10, 20, 12, 0),
      );
      recordRepo.records[3] = HealthRecord(
        id: 3,
        date: '2026-10-21',
        steps: 7100,
        calories: 410,
        water: 1500,
        createdAt: DateTime(2026, 10, 21, 12, 0),
        updatedAt: DateTime(2026, 10, 21, 12, 0),
      );
      recordRepo.records[4] = HealthRecord(
        id: 4,
        date: '2026-10-22',
        steps: 10500,
        calories: 550,
        water: 2500,
        createdAt: DateTime(2026, 10, 22, 12, 0),
        updatedAt: DateTime(2026, 10, 22, 12, 0),
      );
      recordRepo.records[5] = HealthRecord(
        id: 5,
        date: '2026-10-23',
        steps: 8200,
        calories: 450,
        water: 2100,
        createdAt: DateTime(2026, 10, 23, 12, 0),
        updatedAt: DateTime(2026, 10, 23, 12, 0),
      );
      recordRepo.records[6] = HealthRecord(
        id: 6,
        date: '2026-10-24', // Saturday
        steps: 7850,
        calories: 420,
        water: 1750,
        createdAt: DateTime(2026, 10, 24, 12, 0),
        updatedAt: DateTime(2026, 10, 24, 12, 0),
      );
    });

    test('initializes and calculates weekly metrics properly', () async {
      final vm = ProgressViewModel(
        analyticsService: analyticsService,
        insightsService: insightsService,
        onboardingService: onboardingService,
        recordRepository: recordRepo,
        initialDate: DateTime(2026, 10, 24),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      expect(vm.isLoading, isFalse);
      expect(vm.errorMessage, isNull);
      expect(vm.periodType, DatePeriodType.week);
      expect(vm.periodDateBadgeLabel, 'Oct 19 - 25');

      // Verify summary calculations across the 6 recorded days:
      // Steps: 8200 + 10240 + 7100 + 10500 + 8200 + 7850 = 52090. Avg: (52090 / 6) = 8682
      expect(vm.analyticsData, isNotNull);
      expect(vm.analyticsData!.summary.totalRecords, 6);
      expect(vm.analyticsData!.summary.averageSteps, 8682);
      expect(vm.totalAllRecordsCount, 6);

      // Verify insight
      expect(vm.currentInsight, isNotNull);
      expect(vm.currentInsight!.isNew, isTrue);

      // Verify selected day point defaults to active/today
      expect(vm.selectedDayPoint, isNotNull);
    });

    test('switching between Week and Month updates period range and reloads', () async {
      final vm = ProgressViewModel(
        analyticsService: analyticsService,
        insightsService: insightsService,
        onboardingService: onboardingService,
        recordRepository: recordRepo,
        initialDate: DateTime(2026, 10, 24),
      );

      await Future.delayed(const Duration(milliseconds: 50));
      expect(vm.periodType, DatePeriodType.week);

      // Switch to Month
      await vm.setPeriodType(DatePeriodType.month);
      expect(vm.periodType, DatePeriodType.month);
      expect(vm.periodDateBadgeLabel, contains('2026'));

      // Switch back to Week
      await vm.setPeriodType(DatePeriodType.week);
      expect(vm.periodType, DatePeriodType.week);
    });

    test('navigating to previous and next period works within boundaries', () async {
      final vm = ProgressViewModel(
        analyticsService: analyticsService,
        insightsService: insightsService,
        onboardingService: onboardingService,
        recordRepository: recordRepo,
        initialDate: DateTime(2026, 10, 24),
      );

      await Future.delayed(const Duration(milliseconds: 50));
      final initialLabel = vm.periodDateBadgeLabel;

      // Go to previous week
      await vm.goToPreviousPeriod();
      expect(vm.periodDateBadgeLabel, isNot(initialLabel));
      expect(vm.canGoNext, isTrue);

      // Go back to current week
      await vm.goToNextPeriod();
      expect(vm.periodDateBadgeLabel, initialLabel);
    });

    test('generates valid CSV report with header and records', () async {
      final vm = ProgressViewModel(
        analyticsService: analyticsService,
        insightsService: insightsService,
        onboardingService: onboardingService,
        recordRepository: recordRepo,
        initialDate: DateTime(2026, 10, 24),
      );

      await Future.delayed(const Duration(milliseconds: 50));

      final csv = vm.generateCsvReport();
      expect(csv, contains('Date,Weekday,Steps,Calories (kcal),Water (ml)'));
      expect(csv, contains('2026-10-19'));
      expect(csv, contains('2026-10-24'));
    });
  });
}
