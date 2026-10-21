import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/data/models/daily_goals.dart';
import 'package:healthmate/data/models/health_record.dart';
import 'package:healthmate/data/models/user_profile.dart';
import 'package:healthmate/data/repositories/health_record_repository.dart';
import 'package:healthmate/data/repositories/onboarding_repository.dart';
import 'package:healthmate/domain/services/health_record_service.dart';
import 'package:healthmate/domain/services/onboarding_service.dart';
import 'package:healthmate/presentation/records/viewmodels/record_details_viewmodel.dart';

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
  Future<List<HealthRecord>> getAllRecords() async => records.values.toList();

  @override
  Future<HealthRecord?> getRecordByDate(String date) async =>
      records.values.cast<HealthRecord?>().firstWhere((r) => r?.date == date, orElse: () => null);

  @override
  Future<HealthRecord?> getRecordById(int id) async => records[id];

  @override
  Future<List<HealthRecord>> getRecordsForDateRange(String s, String e) async => [];

  @override
  Future<void> incrementWater(String date, int amountMl) async {}

  @override
  Future<int> saveRecord(HealthRecord record) async {
    records[record.id ?? 1] = record;
    return 1;
  }

  @override
  Future<int> updateRecord(HealthRecord record) async {
    records[record.id ?? 1] = record;
    return 1;
  }
}

void main() {
  group('RecordDetailsViewModel Tests', () {
    late MockRecordRepo recordRepo;
    late MockOnboardingRepo onboardingRepo;
    late HealthRecordService recordService;
    late OnboardingService onboardingService;
    late HealthRecord sampleRecord;

    setUp(() {
      recordRepo = MockRecordRepo();
      onboardingRepo = MockOnboardingRepo();
      recordService = HealthRecordService(repository: recordRepo);
      onboardingService = OnboardingService(repository: onboardingRepo);

      // Matches Figma Screenshot 1 values:
      // Steps: 7,850 / 10,000 = 78.5%
      // Calories: 420 / 500 = 84%
      // Water: 1,750 / 2,500 = 70%
      sampleRecord = HealthRecord(
        id: 10,
        date: '2026-10-24',
        steps: 7850,
        calories: 420,
        water: 1750,
        createdAt: DateTime(2026, 10, 24, 20, 45),
        updatedAt: DateTime(2026, 10, 24, 21, 12),
      );
      recordRepo.records[10] = sampleRecord;
    });

    test('calculates individual and overall progress percentages correctly', () async {
      final vm = RecordDetailsViewModel(
        recordId: 10,
        initialRecord: sampleRecord,
        recordService: recordService,
        onboardingService: onboardingService,
      );
      await vm.loadRecord();

      // Steps: 7850 / 10000 = 78.5%
      expect(vm.stepsPercentage, equals(78.5));
      expect(vm.remainingSteps, equals(2150));

      // Calories: 420 / 500 = 84%
      expect(vm.caloriesPercentage, equals(84.0));
      expect(vm.remainingCalories, equals(80));

      // Water: 1750 / 2500 = 70%
      expect(vm.waterPercentage, equals(70.0));
      expect(vm.remainingWater, equals(750));

      // Overall: (78.5% + 84% + 70%) / 3 = 77.5% -> round 78%
      expect(vm.overallProgressPercentage, equals(78));

      // Goals met: none reached full 100%, but all have positive progress
      expect(vm.isAllGoalsCompleted, isFalse);
    });

    test('remaining metrics never return negative values when exceeding goal', () async {
      final exceedingRecord = sampleRecord.copyWith(
        steps: 12000,
        calories: 600,
        water: 3000,
      );
      recordRepo.records[10] = exceedingRecord;

      final vm = RecordDetailsViewModel(
        recordId: 10,
        initialRecord: exceedingRecord,
        recordService: recordService,
        onboardingService: onboardingService,
      );
      await vm.loadRecord();

      expect(vm.remainingSteps, equals(0));
      expect(vm.remainingCalories, equals(0));
      expect(vm.remainingWater, equals(0));
      expect(vm.isAllGoalsCompleted, isTrue);
      expect(vm.goalsMetCount, equals(3));
      // Capped arithmetic mean: (1.0 + 1.0 + 1.0) / 3 = 100%
      expect(vm.overallProgressPercentage, equals(100));
    });

    test('deletes record successfully via ViewModel', () async {
      final vm = RecordDetailsViewModel(
        recordId: 10,
        initialRecord: sampleRecord,
        recordService: recordService,
        onboardingService: onboardingService,
      );

      final deleted = await vm.deleteRecord();
      expect(deleted, isTrue);
      expect(vm.isDeleted, isTrue);
      expect(recordRepo.records.containsKey(10), isFalse);
    });
  });
}
