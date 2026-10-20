import 'package:flutter/material.dart';
import '../../../data/models/daily_goals.dart';
import '../../../domain/services/onboarding_service.dart';

/// ViewModel managing daily goals adjustments, boundaries, and persistence.
class DailyGoalsViewModel extends ChangeNotifier {
  final OnboardingService _onboardingService;

  DailyGoalsViewModel({OnboardingService? onboardingService})
      : _onboardingService = onboardingService ?? OnboardingService() {
    _loadExistingGoals();
  }

  int _steps = DailyGoals.defaultSteps;
  int _waterMl = DailyGoals.defaultWaterMl;
  int _caloriesKcal = DailyGoals.defaultCaloriesKcal;
  bool _isLoading = false;
  String? _errorMessage;

  int get steps => _steps;
  int get waterMl => _waterMl;
  int get caloriesKcal => _caloriesKcal;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> _loadExistingGoals() async {
    try {
      final saved = await _onboardingService.getGoals();
      if (saved != null) {
        _steps = saved.stepsGoal;
        _waterMl = saved.waterGoalMl;
        _caloriesKcal = saved.caloriesGoalKcal;
        notifyListeners();
      }
    } catch (_) {
      // Fallback to defaults
    }
  }

  // Steps Controls
  void incrementSteps() {
    _steps += DailyGoals.stepIncrement;
    notifyListeners();
  }

  void decrementSteps() {
    if (_steps - DailyGoals.stepIncrement >= DailyGoals.minSteps) {
      _steps -= DailyGoals.stepIncrement;
    } else {
      _steps = DailyGoals.minSteps;
    }
    notifyListeners();
  }

  // Water Controls
  void incrementWater() {
    _waterMl += DailyGoals.waterIncrement;
    notifyListeners();
  }

  void decrementWater() {
    if (_waterMl - DailyGoals.waterIncrement >= DailyGoals.minWaterMl) {
      _waterMl -= DailyGoals.waterIncrement;
    } else {
      _waterMl = DailyGoals.minWaterMl;
    }
    notifyListeners();
  }

  // Calories Controls
  void incrementCalories() {
    _caloriesKcal += DailyGoals.caloriesIncrement;
    notifyListeners();
  }

  void decrementCalories() {
    if (_caloriesKcal - DailyGoals.caloriesIncrement >=
        DailyGoals.minCaloriesKcal) {
      _caloriesKcal -= DailyGoals.caloriesIncrement;
    } else {
      _caloriesKcal = DailyGoals.minCaloriesKcal;
    }
    notifyListeners();
  }

  /// Saves targets to SQLite and returns true if successful.
  Future<bool> saveGoals() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final goals = DailyGoals(
        id: 1,
        stepsGoal: _steps,
        waterGoalMl: _waterMl,
        caloriesGoalKcal: _caloriesKcal,
        updatedAt: DateTime.now(),
      );

      await _onboardingService.saveGoals(goals);
      _isLoading = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isLoading = false;
      _errorMessage = 'Failed to save goals. Please try again.';
      notifyListeners();
      return false;
    }
  }
}
