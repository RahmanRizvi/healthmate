import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/data/models/daily_goals.dart';
import 'package:healthmate/data/models/health_record.dart';
import 'package:healthmate/data/repositories/health_record_repository.dart';
import 'package:healthmate/domain/services/health_record_service.dart';

class MockHealthRecordRepository implements IHealthRecordRepository {
  final Map<String, HealthRecord> _recordsByDate = {};

  @override
  Future<int> deleteRecord(int id) async {
    _recordsByDate.removeWhere((_, r) => r.id == id);
    return 1;
  }

  @override
  Future<List<HealthRecord>> getAllRecords() async {
    final list = _recordsByDate.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<HealthRecord?> getRecordByDate(String date) async {
    return _recordsByDate[date];
  }

  @override
  Future<HealthRecord?> getRecordById(int id) async {
    return _recordsByDate.values.firstWhere((r) => r.id == id);
  }

  @override
  Future<List<HealthRecord>> getRecordsForDateRange(
    String startDate,
    String endDate,
  ) async {
    return _recordsByDate.values
        .where((r) => r.date.compareTo(startDate) >= 0 && r.date.compareTo(endDate) <= 0)
        .toList();
  }

  @override
  Future<void> incrementWater(String date, int amountMl) async {
    final existing = _recordsByDate[date];
    if (existing != null) {
      _recordsByDate[date] = existing.copyWith(water: existing.water + amountMl);
    } else {
      _recordsByDate[date] = HealthRecord(
        date: date,
        steps: 0,
        calories: 0,
        water: amountMl,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<int> saveRecord(HealthRecord record) async {
    _recordsByDate[record.date] = record;
    return 1;
  }

  @override
  Future<int> updateRecord(HealthRecord record) async {
    _recordsByDate[record.date] = record;
    return 1;
  }
}

void main() {
  group('HealthRecordService Tests', () {
    late MockHealthRecordRepository mockRepo;
    late HealthRecordService service;
    final goals = DailyGoals.defaults(); // 10,000 steps, 2,500 ml, 500 kcal

    setUp(() {
      mockRepo = MockHealthRecordRepository();
      service = HealthRecordService(repository: mockRepo);
    });

    test('evaluates goal status correctly', () {
      final metRecord = HealthRecord(
        date: '2026-10-24',
        steps: 10000,
        calories: 300,
        water: 1000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(service.evaluateGoalStatus(metRecord, goals), equals(RecordGoalStatus.goalMet));

      final partialRecord = HealthRecord(
        date: '2026-10-24',
        steps: 4000,
        calories: 150,
        water: 800,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(service.evaluateGoalStatus(partialRecord, goals), equals(RecordGoalStatus.partial));

      final emptyRecord = HealthRecord.empty(DateTime(2026, 10, 24));
      expect(service.evaluateGoalStatus(emptyRecord, goals), equals(RecordGoalStatus.none));
    });

    test('calculates 7-day weekly activity and average accurately', () async {
      // Reference date: Thursday, Oct 24, 2026
      final refDate = DateTime(2026, 10, 24);

      // Add records for Mon, Tue, Wed, Thu
      await service.saveRecord(HealthRecord(
        date: '2026-10-20',
        steps: 8000,
        calories: 400,
        water: 2000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await service.saveRecord(HealthRecord(
        date: '2026-10-21',
        steps: 9000,
        calories: 450,
        water: 2200,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await service.saveRecord(HealthRecord(
        date: '2026-10-22',
        steps: 7000,
        calories: 350,
        water: 1800,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final weekly = await service.getWeeklyActivityData(refDate, goals.stepsGoal);

      expect(weekly.days.length, equals(7)); // M, T, W, T, F, S, S
      expect(weekly.totalSteps, equals(24000)); // 8000 + 9000 + 7000
      expect(weekly.averageSteps, equals(8000)); // 24000 / 3
      expect(weekly.hasData, isTrue);

      // Verify Thursday (index 3 or 4) marks isCurrentDay correctly
      final currentDayPoint = weekly.days.firstWhere((d) => d.isCurrentDay);
      expect(currentDayPoint.label, equals('S')); // Saturday in 2026-10-24
    });

    test('calculates daily streak correctly', () async {
      final today = DateTime(2026, 10, 24);

      // Log today and yesterday
      await service.saveRecord(HealthRecord(
        date: '2026-10-24',
        steps: 5000,
        calories: 200,
        water: 1000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await service.saveRecord(HealthRecord(
        date: '2026-10-23',
        steps: 6000,
        calories: 300,
        water: 1500,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));
      await service.saveRecord(HealthRecord(
        date: '2026-10-22',
        steps: 7000,
        calories: 350,
        water: 1800,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      ));

      final streak = await service.calculateDailyStreak(today);
      expect(streak, equals(3));
    });
  });
}
