import 'dart:math';
import 'package:intl/intl.dart';
import '../../core/utils/date_formatter.dart';
import '../../core/utils/date_range_utils.dart';
import '../../data/models/daily_goals.dart';
import '../../data/models/health_record.dart';
import '../../data/repositories/health_record_repository.dart';

/// Single day data point for analytics charts and period breakdown.
class PeriodDayPoint {
  final DateTime date;
  final String dateIso;
  final String dayLabel; // e.g. "M", "T", "W" or "14"
  final String fullWeekday; // e.g. "Thursday"
  final int steps;
  final int calories;
  final int waterMl;
  final bool hasRecord;
  final bool isToday;
  final bool isFuture;
  final bool stepsGoalMet;
  final bool caloriesGoalMet;
  final bool waterGoalMet;
  final bool allGoalsMet;

  const PeriodDayPoint({
    required this.date,
    required this.dateIso,
    required this.dayLabel,
    required this.fullWeekday,
    required this.steps,
    required this.calories,
    required this.waterMl,
    required this.hasRecord,
    required this.isToday,
    required this.isFuture,
    required this.stepsGoalMet,
    required this.caloriesGoalMet,
    required this.waterGoalMet,
    required this.allGoalsMet,
  });

  double get waterLitres => waterMl / 1000.0;

  String get formattedWaterLitres {
    final l = waterLitres;
    if (l == l.roundToDouble()) {
      return '${l.toInt()}L';
    }
    return '${l.toStringAsFixed(1)}L';
  }
}

/// Aggregated summary statistics across recorded days in a period.
class PeriodAnalyticsSummary {
  final int totalRecords;
  final int totalCalendarDays;
  final int elapsedDays;
  final int totalSteps;
  final int totalCalories;
  final int totalWaterMl;
  final int averageSteps;
  final int averageCalories;
  final double averageWaterLitres;

  const PeriodAnalyticsSummary({
    required this.totalRecords,
    required this.totalCalendarDays,
    required this.elapsedDays,
    required this.totalSteps,
    required this.totalCalories,
    required this.totalWaterMl,
    required this.averageSteps,
    required this.averageCalories,
    required this.averageWaterLitres,
  });

  String get formattedAverageWaterLitres {
    if (averageWaterLitres == averageWaterLitres.roundToDouble()) {
      return '${averageWaterLitres.toInt()} L';
    }
    return '${averageWaterLitres.toStringAsFixed(1)} L';
  }
}

/// Goal completion counts and percentages across a period.
class GoalCompletionStats {
  final int stepsDaysAchieved;
  final int caloriesDaysAchieved;
  final int waterDaysAchieved;
  final int allGoalsDaysAchieved;
  final int denominatorDays; // calendar elapsed days in period

  const GoalCompletionStats({
    required this.stepsDaysAchieved,
    required this.caloriesDaysAchieved,
    required this.waterDaysAchieved,
    required this.allGoalsDaysAchieved,
    required this.denominatorDays,
  });

  int get stepsPercentage =>
      denominatorDays > 0 ? ((stepsDaysAchieved / denominatorDays) * 100).round().clamp(0, 100) : 0;

  int get caloriesPercentage =>
      denominatorDays > 0 ? ((caloriesDaysAchieved / denominatorDays) * 100).round().clamp(0, 100) : 0;

  int get waterPercentage =>
      denominatorDays > 0 ? ((waterDaysAchieved / denominatorDays) * 100).round().clamp(0, 100) : 0;
}

/// Percentage comparison between current period and previous equivalent period.
class PeriodComparisonStats {
  final int currentPeriodTotalSteps;
  final int previousPeriodTotalSteps;
  final double? percentageChange;
  final String periodName; // "last week" or "last month"

  const PeriodComparisonStats({
    required this.currentPeriodTotalSteps,
    required this.previousPeriodTotalSteps,
    required this.percentageChange,
    required this.periodName,
  });

  bool get hasComparison => percentageChange != null;
  bool get isPositive => (percentageChange ?? 0) >= 0;

  /// Formatted label, e.g. `+12% vs last week` or `-5% vs last month`.
  String get formattedComparisonText {
    if (percentageChange == null) {
      return 'No prior data';
    }
    final prefix = percentageChange! >= 0 ? '+' : '';
    return '$prefix${percentageChange!.round()}% vs $periodName';
  }
}

/// Extreme records within a period (highest and lowest).
class BestAndLowestStats {
  final PeriodDayPoint? bestStepsDay;
  final PeriodDayPoint? lowestStepsDay;
  final PeriodDayPoint? bestHydrationDay;

  const BestAndLowestStats({
    this.bestStepsDay,
    this.lowestStepsDay,
    this.bestHydrationDay,
  });

  /// e.g. `Thu (10.2k)` or `Oct 14 (12.4k)`
  String get formattedBestStepsLabel {
    if (bestStepsDay == null || bestStepsDay!.steps <= 0) {
      return 'None';
    }
    final day = bestStepsDay!;
    final stepsK = (day.steps / 1000.0);
    final stepsFmt = stepsK >= 10.0
        ? '${stepsK.toStringAsFixed(1)}k'
        : '${stepsK.toStringAsFixed(1)}k';

    final shortDay = DateFormat('E').format(day.date); // e.g. Thu
    return '$shortDay ($stepsFmt)';
  }
}

/// Comprehensive bundle of all analytics for a given period.
class ProgressAnalyticsData {
  final DateRange range;
  final List<HealthRecord> records;
  final List<PeriodDayPoint> dayPoints;
  final PeriodAnalyticsSummary summary;
  final GoalCompletionStats goalStats;
  final PeriodComparisonStats comparison;
  final BestAndLowestStats bestLowest;
  final DailyGoals goals;

  const ProgressAnalyticsData({
    required this.range,
    required this.records,
    required this.dayPoints,
    required this.summary,
    required this.goalStats,
    required this.comparison,
    required this.bestLowest,
    required this.goals,
  });

  bool get hasData => records.isNotEmpty;
}

/// Domain service calculating all real-data analytics and trends from SQLite.
class AnalyticsService {
  final IHealthRecordRepository _repository;

  AnalyticsService({IHealthRecordRepository? repository})
      : _repository = repository ?? HealthRecordRepository();

  /// Compiles all analytics for [range] with given [goals].
  Future<ProgressAnalyticsData> getAnalyticsForPeriod(
    DateRange range,
    DailyGoals goals, [
    DateTime? currentDate,
  ]) async {
    final now = DateRangeUtils.toMidnight(currentDate ?? DateTime.now());

    // 1. Fetch current period records from SQLite
    final records = await _repository.getRecordsForDateRange(
      range.startIso,
      range.endIso,
    );

    final Map<String, HealthRecord> recordMap = {
      for (final r in records) r.date: r,
    };

    // 2. Build Day Points for all calendar days in period
    final dayPoints = <PeriodDayPoint>[];
    const weeklyLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];

    int elapsedCalendarDays = 0;

    for (int i = 0; i < range.totalCalendarDays; i++) {
      final dayDate = range.startDate.add(Duration(days: i));
      final dayIso = DateFormatter.toIsoDateString(dayDate);
      final isToday = DateFormatter.isSameDay(dayDate, now);
      final isFuture = dayDate.isAfter(now);

      if (!isFuture) {
        elapsedCalendarDays++;
      }

      final record = recordMap[dayIso];
      final hasRecord = record != null;
      final steps = record?.steps ?? 0;
      final calories = record?.calories ?? 0;
      final water = record?.water ?? 0;

      final stepsGoalMet = goals.stepsGoal > 0 && steps >= goals.stepsGoal;
      final caloriesGoalMet = goals.caloriesGoalKcal > 0 && calories >= goals.caloriesGoalKcal;
      final waterGoalMet = goals.waterGoalMl > 0 && water >= goals.waterGoalMl;
      final allGoalsMet = stepsGoalMet && caloriesGoalMet && waterGoalMet;

      String label;
      if (range.periodType == DatePeriodType.day) {
        label = DateFormat('E').format(dayDate);
      } else if (range.periodType == DatePeriodType.week) {
        label = weeklyLabels[i % 7];
      } else {
        label = '${dayDate.day}';
      }

      dayPoints.add(
        PeriodDayPoint(
          date: dayDate,
          dateIso: dayIso,
          dayLabel: label,
          fullWeekday: DateFormat('EEEE').format(dayDate),
          steps: steps,
          calories: calories,
          waterMl: water,
          hasRecord: hasRecord,
          isToday: isToday,
          isFuture: isFuture,
          stepsGoalMet: stepsGoalMet,
          caloriesGoalMet: caloriesGoalMet,
          waterGoalMet: waterGoalMet,
          allGoalsMet: allGoalsMet,
        ),
      );
    }

    // 3. Calculate Summary Statistics (averaging recorded days transparently)
    final totalRecords = records.length;
    final totalSteps = records.fold<int>(0, (sum, r) => sum + r.steps);
    final totalCalories = records.fold<int>(0, (sum, r) => sum + r.calories);
    final totalWaterMl = records.fold<int>(0, (sum, r) => sum + r.water);

    final averageSteps = totalRecords > 0 ? (totalSteps / totalRecords).round() : 0;
    final averageCalories = totalRecords > 0 ? (totalCalories / totalRecords).round() : 0;
    final averageWaterLitres = totalRecords > 0 ? (totalWaterMl / totalRecords) / 1000.0 : 0.0;

    final summary = PeriodAnalyticsSummary(
      totalRecords: totalRecords,
      totalCalendarDays: range.totalCalendarDays,
      elapsedDays: elapsedCalendarDays,
      totalSteps: totalSteps,
      totalCalories: totalCalories,
      totalWaterMl: totalWaterMl,
      averageSteps: averageSteps,
      averageCalories: averageCalories,
      averageWaterLitres: averageWaterLitres,
    );

    // 4. Calculate Goal Completion Stats
    int stepsDaysAchieved = 0;
    int caloriesDaysAchieved = 0;
    int waterDaysAchieved = 0;
    int allGoalsDaysAchieved = 0;

    for (final dp in dayPoints) {
      if (!dp.isFuture && dp.hasRecord) {
        if (dp.stepsGoalMet) stepsDaysAchieved++;
        if (dp.caloriesGoalMet) caloriesDaysAchieved++;
        if (dp.waterGoalMet) waterDaysAchieved++;
        if (dp.allGoalsMet) allGoalsDaysAchieved++;
      }
    }

    // Denominator is the number of elapsed calendar days in the period (e.g. 6 of 6 days if today is Saturday)
    final denominator = max(1, elapsedCalendarDays);

    final goalStats = GoalCompletionStats(
      stepsDaysAchieved: stepsDaysAchieved,
      caloriesDaysAchieved: caloriesDaysAchieved,
      waterDaysAchieved: waterDaysAchieved,
      allGoalsDaysAchieved: allGoalsDaysAchieved,
      denominatorDays: denominator,
    );

    // 5. Calculate Comparison vs Previous Period
    final prevRange = DateRangeUtils.getEquivalentPreviousPeriod(range);
    final prevRecords = await _repository.getRecordsForDateRange(
      prevRange.startIso,
      prevRange.endIso,
    );
    final prevTotalSteps = prevRecords.fold<int>(0, (sum, r) => sum + r.steps);

    double? pctChange;
    if (prevTotalSteps > 0) {
      pctChange = ((totalSteps - prevTotalSteps) / prevTotalSteps) * 100.0;
    } else if (totalSteps > 0 && prevTotalSteps == 0) {
      pctChange = null; // Cannot compute clean infinite percentage
    }

    final String periodName;
    if (range.periodType == DatePeriodType.day) {
      periodName = 'yesterday';
    } else if (range.periodType == DatePeriodType.week) {
      periodName = 'last week';
    } else {
      periodName = 'last month';
    }
    final comparison = PeriodComparisonStats(
      currentPeriodTotalSteps: totalSteps,
      previousPeriodTotalSteps: prevTotalSteps,
      percentageChange: pctChange,
      periodName: periodName,
    );

    // 6. Calculate Best & Lowest Recorded Days
    PeriodDayPoint? bestSteps;
    PeriodDayPoint? lowestSteps;
    PeriodDayPoint? bestHydration;

    final recordedPoints = dayPoints.where((p) => p.hasRecord && !p.isFuture).toList();
    if (recordedPoints.isNotEmpty) {
      bestSteps = recordedPoints.reduce((curr, next) => curr.steps >= next.steps ? curr : next);
      lowestSteps = recordedPoints.reduce((curr, next) => curr.steps <= next.steps ? curr : next);
      bestHydration = recordedPoints.reduce((curr, next) => curr.waterMl >= next.waterMl ? curr : next);
    }

    final bestLowest = BestAndLowestStats(
      bestStepsDay: bestSteps,
      lowestStepsDay: lowestSteps,
      bestHydrationDay: bestHydration,
    );

    return ProgressAnalyticsData(
      range: range,
      records: records,
      dayPoints: dayPoints,
      summary: summary,
      goalStats: goalStats,
      comparison: comparison,
      bestLowest: bestLowest,
      goals: goals,
    );
  }
}
