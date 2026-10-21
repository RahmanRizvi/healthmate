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

  final int? initialRecordId;
  final HealthRecord? initialRecord;
  final bool _isEditMode;

  AddRecordViewModel({
    required DateTime initialDate,
    this.initialRecordId,
    this.initialRecord,
    bool isEditMode = false,
    HealthRecordService? recordService,
    OnboardingService? onboardingService,
  })  : _selectedDate = initialRecord?.dateTime ?? initialDate,
        _existingRecordId = initialRecord?.id ?? initialRecordId,
        _steps = initialRecord?.steps ?? 0,
        _calories = initialRecord?.calories ?? 0,
        _water = initialRecord?.water ?? 0,
        _createdAt = initialRecord?.createdAt,
        _isEditMode = isEditMode || initialRecord != null || initialRecordId != null,
        _recordService = recordService ?? HealthRecordService(),
        _onboardingService = onboardingService ?? OnboardingService() {
    loadGoalsAndRecord();
  }

  DateTime _selectedDate;
  DailyGoals? _goals;
  int _steps = 0;
  int _calories = 0;
  int _water = 0;
  DateTime? _createdAt;
  bool _isLoading = false;
  bool _isSaving = false;
  bool _hasDateConflict = false;
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
  bool get isEditMode => _isEditMode;
  bool get hasDateConflict => _hasDateConflict;
  String? get errorMessage => _errorMessage;

  String get screenTitle => _isEditMode ? 'Edit Record' : 'Add Record';
  String get headingText => _isEditMode ? 'Edit your daily activity' : 'Log your daily activity';
  String get submitButtonLabel => _isEditMode ? 'Update Record' : 'Save Record';
  String get savingButtonLabel => _isEditMode ? 'Updating...' : 'Saving...';
  String get successMessage => _isEditMode ? 'Record updated successfully!' : 'Record saved successfully!';

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

      if (initialRecord != null) {
        _existingRecordId = initialRecord!.id;
        _steps = initialRecord!.steps;
        _calories = initialRecord!.calories;
        _water = initialRecord!.water;
        _createdAt = initialRecord!.createdAt;
      } else if (initialRecordId != null) {
        final fetched = await _recordService.getRecordById(initialRecordId!);
        if (fetched != null) {
          _existingRecordId = fetched.id;
          _steps = fetched.steps;
          _calories = fetched.calories;
          _water = fetched.water;
          _createdAt = fetched.createdAt;
          _selectedDate = fetched.dateTime;
        }
      } else {
        await _loadRecordForSelectedDate();
      }
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
      _createdAt = existing.createdAt;
    } else {
      _existingRecordId = null;
      _steps = 0;
      _calories = 0;
      _water = 0;
      _createdAt = null;
    }
  }

  Future<void> setDate(DateTime date) async {
    if (DateFormatter.isSameDay(_selectedDate, date)) return;

    if (_isEditMode && _existingRecordId != null) {
      final other = await _recordService.getRecordForDate(date);
      if (other != null && other.id != null && other.id != _existingRecordId) {
        _hasDateConflict = true;
        _errorMessage = 'A record already exists for ${DateFormatter.formatFullDate(date)}. Please select another date.';
        _selectedDate = date;
        notifyListeners();
        return;
      }
    }

    _hasDateConflict = false;
    _errorMessage = null;
    _selectedDate = date;
    _isLoading = true;
    notifyListeners();

    if (!_isEditMode) {
      await _loadRecordForSelectedDate();
    }
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

  /// Validates and saves or updates the record in SQLite.
  Future<bool> saveRecord() async {
    if (_hasDateConflict) {
      _errorMessage = 'A record already exists for this date. Please select another date.';
      notifyListeners();
      return false;
    }

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
        createdAt: _createdAt ?? now,
        updatedAt: now,
      );

      if (_isEditMode && _existingRecordId != null) {
        await _recordService.updateRecord(record);
      } else {
        await _recordService.saveRecord(record);
      }

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
