import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/data/models/daily_goals.dart';
import 'package:healthmate/data/models/user_profile.dart';
import 'package:healthmate/data/repositories/onboarding_repository.dart';
import 'package:healthmate/domain/services/onboarding_service.dart';
import 'package:healthmate/presentation/onboarding/viewmodels/daily_goals_viewmodel.dart';

class MockOnboardingRepository implements IOnboardingRepository {
  DailyGoals? savedGoals;
  UserProfile? savedProfile;

  @override
  Future<DailyGoals?> getDailyGoals() async => savedGoals;

  @override
  Future<UserProfile?> getUserProfile() async => savedProfile;

  @override
  Future<bool> isOnboardingCompleted() async =>
      savedProfile != null && savedGoals != null;

  @override
  Future<void> saveDailyGoals(DailyGoals goals) async {
    savedGoals = goals;
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    savedProfile = profile;
  }
}

void main() {
  group('DailyGoalsViewModel Tests', () {
    late MockOnboardingRepository mockRepo;
    late OnboardingService onboardingService;
    late DailyGoalsViewModel viewModel;

    setUp(() {
      mockRepo = MockOnboardingRepository();
      onboardingService = OnboardingService(repository: mockRepo);
      viewModel = DailyGoalsViewModel(onboardingService: onboardingService);
    });

    test('initializes with default goals values', () {
      expect(viewModel.steps, equals(10000));
      expect(viewModel.waterMl, equals(2500));
      expect(viewModel.caloriesKcal, equals(500));
    });

    test('increments and decrements steps in 500 step units with minimum boundary of 500', () {
      viewModel.incrementSteps();
      expect(viewModel.steps, equals(10500));

      viewModel.decrementSteps();
      expect(viewModel.steps, equals(10000));

      // Decrement repeatedly toward boundary
      for (int i = 0; i < 30; i++) {
        viewModel.decrementSteps();
      }
      expect(viewModel.steps, equals(DailyGoals.minSteps)); // Cannot go below 500
    });

    test('increments and decrements water in 250ml units with minimum boundary of 250ml', () {
      viewModel.incrementWater();
      expect(viewModel.waterMl, equals(2750));

      viewModel.decrementWater();
      expect(viewModel.waterMl, equals(2500));

      for (int i = 0; i < 20; i++) {
        viewModel.decrementWater();
      }
      expect(viewModel.waterMl, equals(DailyGoals.minWaterMl)); // 250 ml
    });

    test('increments and decrements calories in 50kcal units with minimum boundary of 50kcal', () {
      viewModel.incrementCalories();
      expect(viewModel.caloriesKcal, equals(550));

      viewModel.decrementCalories();
      expect(viewModel.caloriesKcal, equals(500));

      for (int i = 0; i < 20; i++) {
        viewModel.decrementCalories();
      }
      expect(viewModel.caloriesKcal, equals(DailyGoals.minCaloriesKcal)); // 50 kcal
    });

    test('saveGoals persists target values to repository successfully', () async {
      viewModel.incrementSteps(); // 10500
      final success = await viewModel.saveGoals();

      expect(success, isTrue);
      expect(mockRepo.savedGoals, isNotNull);
      expect(mockRepo.savedGoals!.stepsGoal, equals(10500));
    });
  });
}
