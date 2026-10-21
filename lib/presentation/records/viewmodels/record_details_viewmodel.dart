import 'package:flutter/material.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/daily_goals.dart';
import '../../../data/models/health_record.dart';
import '../../../domain/services/health_record_service.dart';
import '../../../domain/services/onboarding_service.dart';

/// ViewModel managing state, calculations, reload, and deletion for Record Details.
class RecordDetailsViewModel extends ChangeNotifier {
  final int recordId;
  final HealthRecordService _recordService;
  final OnboardingService _onboardingService;

  HealthRecord? _record;
  DailyGoals? _goals;
  bool _isLoading = true;
  bool _isDeleted = false;
  String? _errorMessage;

  RecordDetailsViewModel({
    required this.recordId,
    HealthRecord? initialRecord,
    DailyGoals? initialGoals,
    HealthRecordService? recordService,
    OnboardingService? onboardingService,
  })  : _record = initialRecord,
        _goals = initialGoals,
        _recordService = recordService ?? HealthRecordService(),
        _onboardingService = onboardingService ?? OnboardingService() {
    loadRecord();
  }

  HealthRecord? get record => _record;
  DailyGoals get goals => _goals ?? DailyGoals.defaults();
  bool get isLoading => _isLoading;
  bool get isDeleted => _isDeleted;
  String? get errorMessage => _errorMessage;

  // Progress Calculations
  double get stepsProgressRatio => goals.stepsGoal > 0
      ? ((_record?.steps ?? 0) / goals.stepsGoal).clamp(0.0, 1.0)
      : 0.0;

  double get stepsPercentage => goals.stepsGoal > 0
      ? (((_record?.steps ?? 0) / goals.stepsGoal) * 100.0)
      : 0.0;

  int get remainingSteps {
    final recorded = _record?.steps ?? 0;
    final diff = goals.stepsGoal - recorded;
    return diff < 0 ? 0 : diff;
  }

  double get caloriesProgressRatio => goals.caloriesGoalKcal > 0
      ? ((_record?.calories ?? 0) / goals.caloriesGoalKcal).clamp(0.0, 1.0)
      : 0.0;

  double get caloriesPercentage => goals.caloriesGoalKcal > 0
      ? (((_record?.calories ?? 0) / goals.caloriesGoalKcal) * 100.0)
      : 0.0;

  int get remainingCalories {
    final recorded = _record?.calories ?? 0;
    final diff = goals.caloriesGoalKcal - recorded;
    return diff < 0 ? 0 : diff;
  }

  double get waterProgressRatio => goals.waterGoalMl > 0
      ? ((_record?.water ?? 0) / goals.waterGoalMl).clamp(0.0, 1.0)
      : 0.0;

  double get waterPercentage => goals.waterGoalMl > 0
      ? (((_record?.water ?? 0) / goals.waterGoalMl) * 100.0)
      : 0.0;

  int get remainingWater {
    final recorded = _record?.water ?? 0;
    final diff = goals.waterGoalMl - recorded;
    return diff < 0 ? 0 : diff;
  }

  int get overallProgressPercentage {
    if (_record == null) return 0;
    return _recordService.calculateOverallProgressPercentage(_record!, goals).round();
  }

  int get goalsMetCount {
    if (_record == null) return 0;
    return _recordService.countGoalsMet(_record!, goals);
  }

  bool get isAllGoalsCompleted {
    if (_record == null) return false;
    return _recordService.isAllGoalsMet(_record!, goals);
  }

  String get formattedActivityDate {
    if (_record == null) return '';
    return DateFormatter.formatFullDate(_record!.dateTime);
  }

  String get weekdayName {
    if (_record == null) return '';
    return DateFormatter.formatWeekday(_record!.dateTime);
  }

  String get recordedAtTimestamp {
    if (_record == null) return '';
    return DateFormatter.formatRecordedAt(_record!.createdAt);
  }

  String get lastUpdatedTimestamp {
    if (_record == null) return '';
    return DateFormatter.formatLastUpdated(_record!.updatedAt);
  }

  Future<void> loadRecord() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _goals = await _onboardingService.getGoals();
      final fetched = await _recordService.getRecordById(recordId);
      if (fetched != null) {
        _record = fetched;
      }
    } catch (e) {
      _errorMessage = 'Could not load record details.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<bool> deleteRecord() async {
    try {
      await _recordService.deleteRecord(recordId);
      _isDeleted = true;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete record. Please try again.';
      notifyListeners();
      return false;
    }
  }
}