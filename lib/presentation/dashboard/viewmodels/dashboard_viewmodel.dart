import 'package:flutter/material.dart';
import '../../../data/models/daily_goals.dart';
import '../../../data/models/user_profile.dart';
import '../../../domain/services/onboarding_service.dart';

/// ViewModel for the main dashboard screen.
class DashboardViewModel extends ChangeNotifier {
  final OnboardingService _onboardingService;

  DashboardViewModel({OnboardingService? onboardingService})
      : _onboardingService = onboardingService ?? OnboardingService() {
    loadDashboardData();
  }

  UserProfile? _profile;
  DailyGoals? _goals;
  bool _isLoading = true;

  UserProfile? get profile => _profile;
  DailyGoals? get goals => _goals;
  bool get isLoading => _isLoading;

  String get greetingName {
    if (_profile != null && _profile!.fullName.trim().isNotEmpty) {
      final firstName = _profile!.fullName.trim().split(' ').first;
      return firstName;
    }
    return 'Rahman';
  }

  int get stepsGoal => _goals?.stepsGoal ?? DailyGoals.defaultSteps;
  int get waterGoalMl => _goals?.waterGoalMl ?? DailyGoals.defaultWaterMl;
  int get caloriesGoalKcal =>
      _goals?.caloriesGoalKcal ?? DailyGoals.defaultCaloriesKcal;

  Future<void> loadDashboardData() async {
    _isLoading = true;
    notifyListeners();

    try {
      _profile = await _onboardingService.getProfile();
      _goals = await _onboardingService.getGoals();
    } catch (_) {
      // Fallback
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
