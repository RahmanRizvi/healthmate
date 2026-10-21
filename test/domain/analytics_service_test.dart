import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/utils/date_range_utils.dart';
import 'package:healthmate/data/models/daily_goals.dart';
import 'package:healthmate/data/models/health_record.dart';
import 'package:healthmate/data/repositories/health_record_repository.dart';
import 'package:healthmate/domain/services/analytics_service.dart';
import 'package:healthmate/domain/services/insights_service.dart';

class MockRecordRepo implements IHealthRecordRepository {
  final Map<int, HealthRecord> records = {};

  @override
  Future<int> deleteRecord(int id) async {
    records.remove(id);
    return 1;
  }

  @override
  Future<List<HealthRecord>> getAllRecords() async {
    return records.values.toList();
  }

  @override
  Future<HealthRecord?> getRecordByDate(String date) async {
    try {
      return records.values.firstWhere((r) => r.date == date);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<HealthRecord?> getRecordById(int id) async => records[id];

  @override
  Future<List<HealthRecord>> getRecordsForDateRange(String start, String end) async {
    return records.values
        .where((r) => r.date.compareTo(start) >= 0 && r.date.compareTo(end) <= 0)
        .toList();
  }

  @override
  Future<void> incrementWater(String date, int amountMl) async {}

  @override
  Future<int> saveRecord(HealthRecord record) async {
    final id = record.id ?? (records.length + 1);
    records[id] = record.copyWith(id: id);
    return id;
  }

  @override
  Future<int> updateRecord(HealthRecord record) async {
    if (record.id != null) {
      records[record.id!] = record;
      return 1;
    }
    return 0;
  }
}

void main() {
  group('AnalyticsService and InsightsService Tests', () {
    late MockRecordRepo repo;
    late AnalyticsService analyticsService;
    late InsightsService insightsService;
    late DailyGoals goals;

    setUp(() {
      repo = MockRecordRepo();
      analyticsService = AnalyticsService(repository: repo);
      insightsService = InsightsService();
      goals = DailyGoals(
        stepsGoal: 10000,
        waterGoalMl: 2500,
        caloriesGoalKcal: 500,
        updatedAt: DateTime.now(),
      );
    });

    test('calculates correct averages and goal achievements for weekly period', () async {
      // Reference date: Saturday Oct 24, 2026
      final refDate = DateTime(2026, 10, 24);
      final range = DateRangeUtils.getWeekRange(refDate); // Oct 19 - 25

      // Seed 4 records in this week
      repo.records[1] = HealthRecord(
        id: 1,
        date: '2026-10-19', // Mon: goal met for steps & calories
        steps: 10500,
        calories: 520,
        water: 2600,
        createdAt: DateTime(2026, 10, 19, 12, 0),
        updatedAt: DateTime(2026, 10, 19, 12, 0),
      );
      repo.records[2] = HealthRecord(
        id: 2,
        date: '2026-10-20', // Tue: goal met for steps
        steps: 11000,
        calories: 450,
        water: 2000,
        createdAt: DateTime(2026, 10, 20, 12, 0),
        updatedAt: DateTime(2026, 10, 20, 12, 0),
      );
      repo.records[3] = HealthRecord(
        id: 3,
        date: '2026-10-21', // Wed: partial
        steps: 7000,
        calories: 350,
        water: 1500,
        createdAt: DateTime(2026, 10, 21, 12, 0),
        updatedAt: DateTime(2026, 10, 21, 12, 0),
      );
      repo.records[4] = HealthRecord(
        id: 4,
        date: '2026-10-22', // Thu: highest steps
        steps: 12500,
        calories: 600,
        water: 2700,
        createdAt: DateTime(2026, 10, 22, 12, 0),
        updatedAt: DateTime(2026, 10, 22, 12, 0),
      );

      final data = await analyticsService.getAnalyticsForPeriod(range, goals, refDate);

      // Summary checks
      expect(data.hasData, isTrue);
      expect(data.summary.totalRecords, 4);
      // Avg steps: (10500 + 11000 + 7000 + 12500) / 4 = 41000 / 4 = 10250
      expect(data.summary.averageSteps, 10250);
      // Total calories: 520 + 450 + 350 + 600 = 1920 / 4 = 480
      expect(data.summary.averageCalories, 480);
      // Water: 2600 + 2000 + 1500 + 2700 = 8800 ml = 8.8 L. Avg: 2.2 L
      expect(data.summary.averageWaterLitres, 2.2);

      // Goal stats:
      // Steps >= 10k: 19th (10.5k), 20th (11k), 22nd (12.5k) -> 3 days
      expect(data.goalStats.stepsDaysAchieved, 3);
      // Elapsed days up to Saturday Oct 24: Mon, Tue, Wed, Thu, Fri, Sat = 6 days
      expect(data.goalStats.denominatorDays, 6);
      expect(data.goalStats.stepsPercentage, 50); // 3 of 6 = 50%

      // Best and lowest days
      expect(data.bestLowest.bestStepsDay?.steps, 12500);
      expect(data.bestLowest.lowestStepsDay?.steps, 7000);
      expect(data.bestLowest.formattedBestStepsLabel, 'Thu (12.5k)');

      // Insight generation
      final insight = insightsService.generateInsight(data);
      expect(insight.title, 'Your insight');
      expect(insight.message, contains('3 recorded days'));
      expect(insight.message, contains('10,250 steps/day'));
    });

    test('handles empty period safely without errors or division by zero', () async {
      final refDate = DateTime(2026, 10, 24);
      final range = DateRangeUtils.getWeekRange(refDate);

      final data = await analyticsService.getAnalyticsForPeriod(range, goals, refDate);

      expect(data.hasData, isFalse);
      expect(data.summary.totalRecords, 0);
      expect(data.summary.averageSteps, 0);
      expect(data.summary.averageCalories, 0);
      expect(data.summary.averageWaterLitres, 0.0);
      expect(data.goalStats.stepsDaysAchieved, 0);
      expect(data.comparison.percentageChange, isNull);
      expect(data.bestLowest.formattedBestStepsLabel, 'None');

      final insight = insightsService.generateInsight(data);
      expect(insight.message, contains('No activity recorded yet'));
    });

    test('calculates period-over-period percentage change correctly', () async {
      final refDate = DateTime(2026, 10, 24); // Week 2
      final currentWeek = DateRangeUtils.getWeekRange(refDate); // Oct 19 - 25

      // Prev week: 10,000 steps total
      repo.records[1] = HealthRecord(
        id: 1,
        date: '2026-10-15',
        steps: 10000,
        calories: 500,
        water: 2000,
        createdAt: DateTime(2026, 10, 15, 12, 0),
        updatedAt: DateTime(2026, 10, 15, 12, 0),
      );

      // Current week: 12,000 steps total (+20%)
      repo.records[2] = HealthRecord(
        id: 2,
        date: '2026-10-20',
        steps: 12000,
        calories: 600,
        water: 2500,
        createdAt: DateTime(2026, 10, 20, 12, 0),
        updatedAt: DateTime(2026, 10, 20, 12, 0),
      );

      final data = await analyticsService.getAnalyticsForPeriod(currentWeek, goals, refDate);
      expect(data.comparison.percentageChange, 20.0);
      expect(data.comparison.formattedComparisonText, '+20% vs last week');
      expect(data.comparison.isPositive, isTrue);
    });
  });
}
