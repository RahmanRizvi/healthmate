import 'package:flutter/material.dart';
import '../../../data/models/daily_goals.dart';
import '../../../data/models/health_record.dart';
import '../../../domain/services/health_record_service.dart';
import '../../../domain/services/onboarding_service.dart';

/// ViewModel managing historical records display, sorting, and deletion.
class RecordsViewModel extends ChangeNotifier {
  final HealthRecordService _recordService;
  final OnboardingService _onboardingService;

  RecordsViewModel({
    HealthRecordService? recordService,
    OnboardingService? onboardingService,
  })  : _recordService = recordService ?? HealthRecordService(),
        _onboardingService = onboardingService ?? OnboardingService() {
    loadRecords();
  }

  List<HealthRecord> _records = [];
  DailyGoals? _goals;
  bool _isLoading = true;

  List<HealthRecord> get records => _records;
  DailyGoals? get goals => _goals;
  bool get isLoading => _isLoading;

  RecordGoalStatus getRecordStatus(HealthRecord record) {
    final effectiveGoals = _goals ?? DailyGoals.defaults();
    return _recordService.evaluateGoalStatus(record, effectiveGoals);
  }

  Future<void> loadRecords() async {
    _isLoading = true;
    notifyListeners();

    try {
      _goals = await _onboardingService.getGoals();
      _records = await _recordService.getAllRecords();
    } catch (_) {
      // Graceful fallback
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> deleteRecord(int id) async {
    await _recordService.deleteRecord(id);
    await loadRecords();
  }
}
