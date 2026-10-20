import 'package:flutter/material.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../data/models/daily_goals.dart';
import '../../../data/models/health_record.dart';
import '../../../data/models/user_profile.dart';
import '../../../domain/services/health_record_service.dart';
import '../../../domain/services/onboarding_service.dart';

/// ViewModel managing data, calculations, and UI state for the Home Dashboard.
class DashboardViewModel extends ChangeNotifier {
  final OnboardingService _onboardingService;
  final HealthRecordService _recordService;

  DashboardViewModel({
    OnboardingService? onboardingService,
    HealthRecordService? recordService,
  })  : _onboardingService = onboardingService ?? OnboardingService(),
        _recordService = recordService ?? HealthRecordService() {
    loadDashboard();
  }

  UserProfile? _profile;
  DailyGoals? _goals;
  HealthRecord? _todayRecord;
  WeeklyActivityData? _weeklyData;
  List<HealthRecord> _recentRecords = [];
  int _streakDays = 1;
  bool _isLoading = true;
  bool _isBannerDismissed = false;

  // Getters
  UserProfile? get profile => _profile;
  DailyGoals? get goals => _goals;
  HealthRecord? get todayRecord => _todayRecord;
  WeeklyActivityData? get weeklyData => _weeklyData;
  List<HealthRecord> get recentRecords => _recentRecords;
  int get streakDays => _streakDays;
  bool get isLoading => _isLoading;
  bool get isBannerDismissed => _isBannerDismissed;

  bool get isNewUser => _recentRecords.isEmpty && (_todayRecord == null || _todayRecord!.steps == 0);

  String get greetingDate => DateFormatter.formatGreetingDate(DateTime.now());

  String get greeting {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  String get userName {
    if (_profile != null && _profile!.fullName.trim().isNotEmpty) {
      return _profile!.fullName.trim().split(' ').first;
    }
    return 'Alex';
  }

  int get stepsGoal => _goals?.stepsGoal ?? DailyGoals.defaultSteps;
  int get caloriesGoal => _goals?.caloriesGoalKcal ?? DailyGoals.defaultCaloriesKcal;
  int get waterGoalMl => _goals?.waterGoalMl ?? DailyGoals.defaultWaterMl;

  int get todaySteps => _todayRecord?.steps ?? 0;
  int get todayCalories => _todayRecord?.calories ?? 0;
  int get todayWaterMl => _todayRecord?.water ?? 0;

  int? get averageSteps => _weeklyData?.averageSteps;

  RecordGoalStatus getRecordStatus(HealthRecord record) {
    final effectiveGoals = _goals ?? DailyGoals.defaults();
    return _recordService.evaluateGoalStatus(record, effectiveGoals);
  }

  void dismissBanner() {
    _isBannerDismissed = true;
    notifyListeners();
  }

  /// Reloads all dashboard data from SQLite.
  Future<void> loadDashboard() async {
    _isLoading = true;
    notifyListeners();

    try {
      final now = DateTime.now();

      _profile = await _onboardingService.getProfile();
      _goals = await _onboardingService.getGoals();

      _todayRecord = await _recordService.getTodayRecord(now);

      final stepGoal = _goals?.stepsGoal ?? DailyGoals.defaultSteps;
      _weeklyData = await _recordService.getWeeklyActivityData(now, stepGoal);

      final allRecords = await _recordService.getAllRecords();
      // Exclude today from recent records if you want, or show all recent records up to 5
      _recentRecords = allRecords.take(5).toList();

      _streakDays = await _recordService.calculateDailyStreak(now);
    } catch (_) {
      // Graceful fallback
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Adds water directly from the dashboard shortcut and reloads.
  Future<void> quickAddWater(int amountMl) async {
    await _recordService.quickAddWaterToday(amountMl);
    await loadDashboard();
  }
}
