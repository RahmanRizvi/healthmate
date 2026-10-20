import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/data/models/daily_goals.dart';
import 'package:healthmate/data/models/health_record.dart';
import 'package:healthmate/data/models/user_profile.dart';
import 'package:healthmate/data/repositories/health_record_repository.dart';
import 'package:healthmate/data/repositories/onboarding_repository.dart';
import 'package:healthmate/domain/services/health_record_service.dart';
import 'package:healthmate/domain/services/onboarding_service.dart';
import 'package:healthmate/presentation/records/viewmodels/add_record_viewmodel.dart';

class MockOnboardingRepo implements IOnboardingRepository {
  DailyGoals? goals = DailyGoals.defaults();
  UserProfile? profile;

  @override
  Future<DailyGoals?> getDailyGoals() async => goals;
  @override
  Future<UserProfile?> getUserProfile() async => profile;
  @override
  Future<bool> isOnboardingCompleted() async => true;
  @override
  Future<void> saveDailyGoals(DailyGoals g) async {
    goals = g;
  }
  @override
  Future<void> saveUserProfile(UserProfile p) async {
    profile = p;
  }
}

class MockRecordRepo implements IHealthRecordRepository {
  HealthRecord? saved;

  @override
  Future<int> deleteRecord(int id) async => 1;
  @override
  Future<List<HealthRecord>> getAllRecords() async => saved != null ? [saved!] : [];
  @override
  Future<HealthRecord?> getRecordByDate(String date) async => saved?.date == date ? saved : null;
  @override
  Future<HealthRecord?> getRecordById(int id) async => saved;
  @override
  Future<List<HealthRecord>> getRecordsForDateRange(String s, String e) async =>
      saved != null ? [saved!] : [];
  @override
  Future<void> incrementWater(String date, int amountMl) async {}
  @override
  Future<int> saveRecord(HealthRecord record) async {
    saved = record;
    return 1;
  }
}

void main() {
  group('AddRecordViewModel Tests', () {
    late MockOnboardingRepo onboardingRepo;
    late MockRecordRepo recordRepo;
    late HealthRecordService recordService;
    late OnboardingService onboardingService;
    late AddRecordViewModel viewModel;

    setUp(() {
      onboardingRepo = MockOnboardingRepo();
      recordRepo = MockRecordRepo();
      recordService = HealthRecordService(repository: recordRepo);
      onboardingService = OnboardingService(repository: onboardingRepo);

      viewModel = AddRecordViewModel(
        initialDate: DateTime(2026, 10, 24),
        recordService: recordService,
        onboardingService: onboardingService,
      );
    });

    test('increments and decrements steps', () {
      viewModel.setSteps(1000);
      viewModel.incrementSteps(250);
      expect(viewModel.steps, equals(1250));

      viewModel.decrementSteps(250);
      expect(viewModel.steps, equals(1000));

      viewModel.decrementSteps(2000);
      expect(viewModel.steps, equals(0)); // Cannot be negative
    });

    test('adds water intake via quick-add chips', () {
      viewModel.setWater(500);
      viewModel.addWater(250);
      expect(viewModel.water, equals(750));

      viewModel.addWater(150);
      expect(viewModel.water, equals(900));
    });

    test('calculates progress percentages correctly', () {
      viewModel.setSteps(7850);
      // Step goal is 10,000 -> 78.5% -> round 79% (or 78% depending on formula)
      expect(viewModel.stepsProgressPercent, inInclusiveRange(78, 79));

      viewModel.setWater(1750);
      // Water goal is 2500 -> 1750/2500 = 70%
      expect(viewModel.waterProgressPercent, equals(70));
    });

    test('saves health record to repository successfully', () async {
      viewModel.setSteps(6420);
      viewModel.setCalories(1480);
      viewModel.setWater(1750);

      final success = await viewModel.saveRecord();
      expect(success, isTrue);

      expect(recordRepo.saved, isNotNull);
      expect(recordRepo.saved!.steps, equals(6420));
      expect(recordRepo.saved!.calories, equals(1480));
      expect(recordRepo.saved!.water, equals(1750));
    });
  });
}
