import 'package:flutter/material.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/daily_goals.dart';
import '../../../data/models/health_record.dart';
import '../../../domain/services/health_record_service.dart';
import '../../../domain/services/onboarding_service.dart';

/// ViewModel managing state, validation, and persistence for adding or editing a health record.
class AddRecordViewModel extends ChangeNotifier {
  final HealthRecordService _recordService;
  final OnboardingService _onboardingService;

  AddRecordViewModel({
    required DateTime initialDate,
    HealthRecordService? recordService,
    OnboardingService? onboardingService,
  })  : _selectedDate = initialDate,
        _recordService = recordService ?? HealthRecordService(),
        _onboardingService = onboardingService ?? OnboardingService() {
    loadGoalsAndRecord();
  }

  DateTime _selectedDate;
  DailyGoals? _goals;
  int _steps = 0;
  int _calories = 0;
  int _water = 0;
  bool _isLoading = false;
  bool _isSaving = false;
  String? _errorMessage;
  int? _existingRecordId;

  // Getters
  DateTime get selectedDate => _selectedDate;
  DailyGoals? get goals => _goals;
  int get steps => _steps;
  int get calories => _calories;
  int get water => _water;
  bool get isLoading => _isLoading;
  bool get isSaving => _isSaving;
  String? get errorMessage => _errorMessage;

  int get stepsGoal => _goals?.stepsGoal ?? DailyGoals.defaultSteps;
  int get caloriesGoal => _goals?.caloriesGoalKcal ?? DailyGoals.defaultCaloriesKcal;
  int get waterGoalMl => _goals?.waterGoalMl ?? DailyGoals.defaultWaterMl;

  int get stepsProgressPercent =>
      stepsGoal > 0 ? ((steps / stepsGoal) * 100).round() : 0;

  int get waterProgressPercent =>
      waterGoalMl > 0 ? ((water / waterGoalMl) * 100).round() : 0;

  String get formattedDateOfActivity =>
      DateFormatter.formatDateOfActivity(_selectedDate);

  Future<void> loadGoalsAndRecord() async {
    _isLoading = true;
    notifyListeners();

    try {
      _goals = await _onboardingService.getGoals();
      await _loadRecordForSelectedDate();
    } catch (_) {
      // Graceful fallback
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> _loadRecordForSelectedDate() async {
    final existing = await _recordService.getRecordForDate(_selectedDate);
    if (existing != null) {
      _existingRecordId = existing.id;
      _steps = existing.steps;
      _calories = existing.calories;
      _water = existing.water;
    } else {
      _existingRecordId = null;
      _steps = 0;
      _calories = 0;
      _water = 0;
    }
  }

  Future<void> setDate(DateTime date) async {
    if (DateFormatter.isSameDay(_selectedDate, date)) return;

    _selectedDate = date;
    _isLoading = true;
    notifyListeners();

    await _loadRecordForSelectedDate();
    _isLoading = false;
    notifyListeners();
  }

  void setSteps(int value) {
    _steps = value < 0 ? 0 : value;
    notifyListeners();
  }

  void incrementSteps([int increment = 250]) {
    _steps += increment;
    notifyListeners();
  }

  void decrementSteps([int decrement = 250]) {
    _steps = (_steps - decrement) < 0 ? 0 : (_steps - decrement);
    notifyListeners();
  }

  void setCalories(int value) {
    _calories = value < 0 ? 0 : value;
    notifyListeners();
  }

  void setWater(int value) {
    _water = value < 0 ? 0 : value;
    notifyListeners();
  }

  void addWater(int amountMl) {
    _water += amountMl;
    notifyListeners();
  }

  /// Validates and saves the current record to SQLite.
  Future<bool> saveRecord() async {
    if (_steps < 0 || _calories < 0 || _water < 0) {
      _errorMessage = 'Measurements cannot be negative.';
      notifyListeners();
      return false;
    }

    _isSaving = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final now = DateTime.now();
      final record = HealthRecord(
        id: _existingRecordId,
        date: DateFormatter.toIsoDateString(_selectedDate),
        steps: _steps,
        calories: _calories,
        water: _water,
        createdAt: now,
        updatedAt: now,
      );

      await _recordService.saveRecord(record);
      _isSaving = false;
      notifyListeners();
      return true;
    } catch (e) {
      _isSaving = false;
      _errorMessage = 'Failed to save health record. Please try again.';
      notifyListeners();
      return false;
    }
  }
}
