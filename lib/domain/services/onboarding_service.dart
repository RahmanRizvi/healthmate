import '../../data/models/user_profile.dart';
import '../../data/models/daily_goals.dart';
import '../../data/repositories/onboarding_repository.dart';

enum OnboardingResumeStep {
  welcome,
  personalDetails,
  bmiAnalysis,
  dailyGoals,
  completed,
}

/// Domain service coordinating onboarding flow state and persistence.
class OnboardingService {
  final IOnboardingRepository _repository;

  OnboardingService({IOnboardingRepository? repository})
      : _repository = repository ?? OnboardingRepository();

  Future<bool> isOnboardingCompleted() async {
    return await _repository.isOnboardingCompleted();
  }

  Future<UserProfile?> getProfile() async {
    return await _repository.getUserProfile();
  }

  Future<void> saveProfile(UserProfile profile) async {
    await _repository.saveUserProfile(profile);
  }

  Future<DailyGoals?> getGoals() async {
    return await _repository.getDailyGoals();
  }

  Future<void> saveGoals(DailyGoals goals) async {
    await _repository.saveDailyGoals(goals);
  }

  /// Determines where the user should resume if they closed the app mid-onboarding.
  Future<OnboardingResumeStep> getResumeStep() async {
    final isCompleted = await _repository.isOnboardingCompleted();
    if (isCompleted) {
      return OnboardingResumeStep.completed;
    }

    final profile = await _repository.getUserProfile();
    if (profile != null &&
        profile.fullName.trim().isNotEmpty &&
        profile.heightCm > 0 &&
        profile.weightKg > 0) {
      // Profile is filled, next step is BMI or Goals
      final goals = await _repository.getDailyGoals();
      if (goals != null) {
        return OnboardingResumeStep.dailyGoals;
      }
      return OnboardingResumeStep.bmiAnalysis;
    }

    return OnboardingResumeStep.welcome;
  }
}
