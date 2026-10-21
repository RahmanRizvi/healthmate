import '../../core/utils/date_formatter.dart';
import '../../data/models/daily_goals.dart';
import '../../data/models/health_record.dart';
import '../../data/repositories/health_record_repository.dart';

enum RecordGoalStatus {
  goalMet,
  partial,
  none;

  String get label {
    switch (this) {
      case RecordGoalStatus.goalMet:
        return 'Goal met';
      case RecordGoalStatus.partial:
        return 'Partial';
      case RecordGoalStatus.none:
        return 'Incomplete';
    }
  }
}

/// Represents one day's data in the 7-day weekly activity chart.
class WeeklyDayPoint {
  final String label; // "M", "T", "W", "T", "F", "S", "S"
  final DateTime date;
  final int steps;
  final bool isCurrentDay;
  final double ratio; // normalized [0.0 - 1.0] relative to goal or max

  const WeeklyDayPoint({
    required this.label,
    required this.date,
    required this.steps,
    required this.isCurrentDay,
    required this.ratio,
  });
}

/// Structured summary of the current week's activity.
class WeeklyActivityData {
  final List<WeeklyDayPoint> days;
  final int averageSteps;
  final int totalSteps;
  final bool hasData;

  const WeeklyActivityData({
    required this.days,
    required this.averageSteps,
    required this.totalSteps,
    required this.hasData,
  });
}

/// Domain service coordinating health record business logic, weekly stats, and streaks.
class HealthRecordService {
  final IHealthRecordRepository _repository;

  HealthRecordService({IHealthRecordRepository? repository})
      : _repository = repository ?? HealthRecordRepository();

  /// Retrieves today's health record.
  Future<HealthRecord?> getTodayRecord([DateTime? currentDate]) async {
    final now = currentDate ?? DateTime.now();
    final todayStr = DateFormatter.toIsoDateString(now);
    return await _repository.getRecordByDate(todayStr);
  }

  /// Retrieves health record for a specific calendar date.
  Future<HealthRecord?> getRecordForDate(DateTime date) async {
    final dateStr = DateFormatter.toIsoDateString(date);
    return await _repository.getRecordByDate(dateStr);
  }

  /// Retrieves all records sorted newest first.
  Future<List<HealthRecord>> getAllRecords() async {
    return await _repository.getAllRecords();
  }

  /// Retrieves health record by ID.
  Future<HealthRecord?> getRecordById(int id) async {
    return await _repository.getRecordById(id);
  }

  /// Saves or updates a health record for its specified date.
  Future<int> saveRecord(HealthRecord record) async {
    return await _repository.saveRecord(record);
  }

  /// Updates an existing health record by its unique ID.
  Future<int> updateRecord(HealthRecord record) async {
    return await _repository.updateRecord(record);
  }

  /// Deletes a health record by its unique ID.
  Future<int> deleteRecord(int id) async {
    return await _repository.deleteRecord(id);
  }

  /// Atomically adds water to today's entry without changing steps or calories.
  Future<void> quickAddWaterToday(int amountMl, [DateTime? currentDate]) async {
    final now = currentDate ?? DateTime.now();
    final dateStr = DateFormatter.toIsoDateString(now);
    await _repository.incrementWater(dateStr, amountMl);
  }

  /// Checks if all 3 daily goals (steps, calories, water) are met.
  bool isAllGoalsMet(HealthRecord record, DailyGoals goals) {
    final metSteps = goals.stepsGoal > 0 && record.steps >= goals.stepsGoal;
    final metCalories = goals.caloriesGoalKcal > 0 && record.calories >= goals.caloriesGoalKcal;
    final metWater = goals.waterGoalMl > 0 && record.water >= goals.waterGoalMl;
    return metSteps && metCalories && metWater;
  }

  /// Counts how many of the 3 goals are achieved (0, 1, 2, or 3).
  int countGoalsMet(HealthRecord record, DailyGoals goals) {
    int count = 0;
    if (goals.stepsGoal > 0 && record.steps >= goals.stepsGoal) count++;
    if (goals.caloriesGoalKcal > 0 && record.calories >= goals.caloriesGoalKcal) count++;
    if (goals.waterGoalMl > 0 && record.water >= goals.waterGoalMl) count++;
    return count;
  }

  /// Calculates overall progress percentage as the arithmetic mean of the three capped ratios.
  double calculateOverallProgressPercentage(HealthRecord record, DailyGoals goals) {
    final stepsRatio = goals.stepsGoal > 0
        ? (record.steps / goals.stepsGoal).clamp(0.0, 1.0)
        : 0.0;
    final caloriesRatio = goals.caloriesGoalKcal > 0
        ? (record.calories / goals.caloriesGoalKcal).clamp(0.0, 1.0)
        : 0.0;
    final waterRatio = goals.waterGoalMl > 0
        ? (record.water / goals.waterGoalMl).clamp(0.0, 1.0)
        : 0.0;

    final mean = (stepsRatio + caloriesRatio + waterRatio) / 3.0;
    return mean * 100.0;
  }

  /// Evaluates goal completion status for a health record.
  RecordGoalStatus evaluateGoalStatus(HealthRecord record, DailyGoals goals) {
    if (record.steps <= 0 && record.calories <= 0 && record.water <= 0) {
      return RecordGoalStatus.none;
    }

    final metSteps = goals.stepsGoal > 0 && record.steps >= goals.stepsGoal;
    final metCalories = goals.caloriesGoalKcal > 0 && record.calories >= goals.caloriesGoalKcal;
    final metWater = goals.waterGoalMl > 0 && record.water >= goals.waterGoalMl;

    final metCount = (metSteps ? 1 : 0) + (metCalories ? 1 : 0) + (metWater ? 1 : 0);

    if (metSteps || metCount >= 2) {
      return RecordGoalStatus.goalMet;
    }

    return RecordGoalStatus.partial;
  }

  /// Calculates the average steps across a list of records safely.
  int calculateAverageSteps(List<HealthRecord> records) {
    if (records.isEmpty) return 0;
    final total = records.fold<int>(0, (sum, r) => sum + r.steps);
    return (total / records.length).round();
  }

  /// Calculates the total water intake in Litres across a list of records.
  double calculateTotalWaterLitres(List<HealthRecord> records) {
    if (records.isEmpty) return 0.0;
    final totalMl = records.fold<int>(0, (sum, r) => sum + r.water);
    return totalMl / 1000.0;
  }

  /// Formats water in Litres: e.g. `28.5L` or `0L`.
  String formatWaterLitres(double litres) {
    if (litres == litres.roundToDouble()) {
      return '${litres.toInt()}L';
    }
    return '${litres.toStringAsFixed(1)}L';
  }

  /// Calculates weekly chart points (Monday through Sunday) and average steps.
  Future<WeeklyActivityData> getWeeklyActivityData(
    DateTime referenceDate,
    int stepGoal,
  ) async {
    // Determine Monday of the current week (weekday 1 = Monday)
    final monday = referenceDate.subtract(Duration(days: referenceDate.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));

    final startStr = DateFormatter.toIsoDateString(monday);
    final endStr = DateFormatter.toIsoDateString(sunday);

    final records = await _repository.getRecordsForDateRange(startStr, endStr);
    final Map<String, HealthRecord> recordMap = {
      for (final r in records) r.date: r,
    };

    const dayLabels = ['M', 'T', 'W', 'T', 'F', 'S', 'S'];
    final List<WeeklyDayPoint> points = [];

    int totalSteps = 0;
    int recordedDaysCount = 0;
    final effectiveGoal = stepGoal > 0 ? stepGoal : 10000;

    for (int i = 0; i < 7; i++) {
      final dayDate = monday.add(Duration(days: i));
      final dayStr = DateFormatter.toIsoDateString(dayDate);
      final isToday = DateFormatter.isSameDay(dayDate, referenceDate);

      final record = recordMap[dayStr];
      final steps = record?.steps ?? 0;

      if (record != null && steps > 0) {
        totalSteps += steps;
        recordedDaysCount++;
      }

      final ratio = (steps / effectiveGoal).clamp(0.0, 1.0);

      points.add(
        WeeklyDayPoint(
          label: dayLabels[i],
          date: dayDate,
          steps: steps,
          isCurrentDay: isToday,
          ratio: ratio,
        ),
      );
    }

    final averageSteps = recordedDaysCount > 0
        ? (totalSteps / recordedDaysCount).round()
        : 0;

    return WeeklyActivityData(
      days: points,
      averageSteps: averageSteps,
      totalSteps: totalSteps,
      hasData: recordedDaysCount > 0,
    );
  }

  /// Calculates active consecutive daily streak ending today or yesterday.
  Future<int> calculateDailyStreak([DateTime? currentDate]) async {
    final now = currentDate ?? DateTime.now();
    final records = await _repository.getAllRecords();

    if (records.isEmpty) {
      return 1; // Default Day 1 on onboarding completion
    }

    final Set<String> activeDates = {
      for (final r in records)
        if (r.steps > 0 || r.water > 0 || r.calories > 0) r.date,
    };

    int streak = 0;
    DateTime checkDate = now;

    // If today is not yet logged, start checking from yesterday
    final todayStr = DateFormatter.toIsoDateString(checkDate);
    if (!activeDates.contains(todayStr)) {
      checkDate = checkDate.subtract(const Duration(days: 1));
    }

    while (true) {
      final dateStr = DateFormatter.toIsoDateString(checkDate);
      if (activeDates.contains(dateStr)) {
        streak++;
        checkDate = checkDate.subtract(const Duration(days: 1));
      } else {
        break;
      }
    }

    // Default to at least Day 1 for active user engagement
    return streak > 0 ? streak : 1;
  }
}
