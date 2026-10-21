import 'package:flutter/foundation.dart';
import '../../../core/utils/date_range_utils.dart';
import '../../../data/models/daily_goals.dart';
import '../../../data/repositories/health_record_repository.dart';
import '../../../domain/services/analytics_service.dart';
import '../../../domain/services/insights_service.dart';
import '../../../domain/services/onboarding_service.dart';

/// ViewModel managing state, interactive periods, day selection, and analytics for the Progress screen.
class ProgressViewModel extends ChangeNotifier {
  final AnalyticsService _analyticsService;
  final InsightsService _insightsService;
  final OnboardingService _onboardingService;
  final IHealthRecordRepository _recordRepository;

  DatePeriodType _periodType = DatePeriodType.week;
  late DateRange _currentRange;
  ProgressAnalyticsData? _analyticsData;
  ProgressInsight? _currentInsight;
  int? _selectedDayIndex;
  int _totalAllRecordsCount = 0;
  bool _isLoading = true;
  String? _errorMessage;

  final DateTime _referenceDate;

  ProgressViewModel({
    AnalyticsService? analyticsService,
    InsightsService? insightsService,
    OnboardingService? onboardingService,
    IHealthRecordRepository? recordRepository,
    DateTime? initialDate,
  })  : _analyticsService = analyticsService ?? AnalyticsService(),
        _insightsService = insightsService ?? InsightsService(),
        _onboardingService = onboardingService ?? OnboardingService(),
        _recordRepository = recordRepository ?? HealthRecordRepository(),
        _referenceDate = initialDate ?? DateTime.now() {
    _currentRange = DateRangeUtils.getWeekRange(_referenceDate);
    loadProgress();
  }

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  DatePeriodType get periodType => _periodType;
  DateRange get currentRange => _currentRange;
  ProgressAnalyticsData? get analyticsData => _analyticsData;
  ProgressInsight? get currentInsight => _currentInsight;
  int? get selectedDayIndex => _selectedDayIndex;
  int get totalAllRecordsCount => _totalAllRecordsCount;
  bool get canGoNext => DateRangeUtils.canNavigateNext(_currentRange);

  String get periodDateBadgeLabel => _currentRange.displayLabel;

  /// Currently selected day point for chart inspection, or fallback to today/last point.
  PeriodDayPoint? get selectedDayPoint {
    if (_analyticsData == null || _analyticsData!.dayPoints.isEmpty) return null;
    if (_selectedDayIndex != null &&
        _selectedDayIndex! >= 0 &&
        _selectedDayIndex! < _analyticsData!.dayPoints.length) {
      return _analyticsData!.dayPoints[_selectedDayIndex!];
    }
    // Default to today if in range, otherwise last recorded or last point
    final todayIdx = _analyticsData!.dayPoints.indexWhere((p) => p.isToday);
    if (todayIdx != -1) return _analyticsData!.dayPoints[todayIdx];
    return _analyticsData!.dayPoints.last;
  }

  /// Loads all analytics from SQLite and saved daily goals.
  Future<void> loadProgress() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final goals = await _onboardingService.getGoals() ??
          DailyGoals(
            stepsGoal: 10000,
            waterGoalMl: 2500,
            caloriesGoalKcal: 500,
            updatedAt: DateTime.now(),
          );

      // Fetch analytics for current period
      final data = await _analyticsService.getAnalyticsForPeriod(
        _currentRange,
        goals,
        _referenceDate,
      );

      // Fetch total count across entire database for "View all records" card
      final allRecords = await _recordRepository.getAllRecords();
      _totalAllRecordsCount = allRecords.length;

      // Generate insight
      final insight = _insightsService.generateInsight(data);

      _analyticsData = data;
      _currentInsight = insight;

      // Pick default selected day (today if in range, else best day, or last recorded day)
      if (data.dayPoints.isNotEmpty) {
        final todayIdx = data.dayPoints.indexWhere((p) => p.isToday);
        if (todayIdx != -1) {
          _selectedDayIndex = todayIdx;
        } else {
          final lastRecordedIdx = data.dayPoints.lastIndexWhere((p) => p.hasRecord);
          _selectedDayIndex = lastRecordedIdx != -1 ? lastRecordedIdx : data.dayPoints.length - 1;
        }
      } else {
        _selectedDayIndex = null;
      }
    } catch (e) {
      _errorMessage = 'Failed to load progress analytics: $e';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  /// Toggles between Day, Week, and Month views.
  Future<void> setPeriodType(DatePeriodType type) async {
    if (_periodType == type) return;
    _periodType = type;

    final now = _referenceDate;
    if (_periodType == DatePeriodType.day) {
      _currentRange = DateRangeUtils.getDayRange(now);
    } else if (_periodType == DatePeriodType.week) {
      _currentRange = DateRangeUtils.getWeekRange(now);
    } else {
      _currentRange = DateRangeUtils.getMonthRange(now);
    }

    await loadProgress();
  }

  /// Navigates to the previous day, week, or month.
  Future<void> goToPreviousPeriod() async {
    if (_periodType == DatePeriodType.day) {
      _currentRange = DateRangeUtils.getPreviousDayRange(_currentRange);
    } else if (_periodType == DatePeriodType.week) {
      _currentRange = DateRangeUtils.getPreviousWeekRange(_currentRange);
    } else {
      _currentRange = DateRangeUtils.getPreviousMonthRange(_currentRange);
    }
    await loadProgress();
  }

  /// Navigates to the next day, week, or month (if not in future).
  Future<void> goToNextPeriod() async {
    if (!canGoNext) return;

    if (_periodType == DatePeriodType.day) {
      _currentRange = DateRangeUtils.getNextDayRange(_currentRange);
    } else if (_periodType == DatePeriodType.week) {
      _currentRange = DateRangeUtils.getNextWeekRange(_currentRange);
    } else {
      _currentRange = DateRangeUtils.getNextMonthRange(_currentRange);
    }
    await loadProgress();
  }

  /// Returns to the current (today's) day, week, or month.
  Future<void> returnToCurrentPeriod() async {
    final now = _referenceDate;
    if (_periodType == DatePeriodType.day) {
      _currentRange = DateRangeUtils.getDayRange(now);
    } else if (_periodType == DatePeriodType.week) {
      _currentRange = DateRangeUtils.getWeekRange(now);
    } else {
      _currentRange = DateRangeUtils.getMonthRange(now);
    }
    await loadProgress();
  }

  /// Selects a day point in the chart.
  void selectDay(int index) {
    if (_selectedDayIndex != index) {
      _selectedDayIndex = index;
      notifyListeners();
    }
  }

  /// Generates a CSV string of all records in the selected period.
  String generateCsvReport() {
    if (_analyticsData == null) return '';

    final buffer = StringBuffer();
    buffer.writeln('Date,Weekday,Steps,Calories (kcal),Water (ml),Steps Goal Met,Calories Goal Met,Water Goal Met,All Goals Met');

    for (final day in _analyticsData!.dayPoints) {
      if (day.hasRecord) {
        buffer.writeln(
          '${day.dateIso},${day.fullWeekday},${day.steps},${day.calories},${day.waterMl},'
          '${day.stepsGoalMet ? "Yes" : "No"},${day.caloriesGoalMet ? "Yes" : "No"},'
          '${day.waterGoalMet ? "Yes" : "No"},${day.allGoalsMet ? "Yes" : "No"}',
        );
      }
    }
    return buffer.toString();
  }
}
