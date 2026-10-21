import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/data/models/daily_goals.dart';
import 'package:healthmate/data/models/health_record.dart';
import 'package:healthmate/data/models/user_profile.dart';
import 'package:healthmate/data/repositories/health_record_repository.dart';
import 'package:healthmate/data/repositories/onboarding_repository.dart';
import 'package:healthmate/domain/services/health_record_service.dart';
import 'package:healthmate/domain/services/onboarding_service.dart';
import 'package:healthmate/presentation/records/viewmodels/records_viewmodel.dart';

class MockOnboardingRepo implements IOnboardingRepository {
  DailyGoals? goals = DailyGoals(
    stepsGoal: 10000,
    waterGoalMl: 2500,
    caloriesGoalKcal: 500,
    updatedAt: DateTime.now(),
  );

  @override
  Future<DailyGoals?> getDailyGoals() async => goals;

  @override
  Future<UserProfile?> getUserProfile() async => null;

  @override
  Future<bool> isOnboardingCompleted() async => true;

  @override
  Future<void> saveDailyGoals(DailyGoals g) async {
    goals = g;
  }

  @override
  Future<void> saveUserProfile(UserProfile p) async {}
}

class MockRecordRepo implements IHealthRecordRepository {
  final Map<String, HealthRecord> records = {};

  @override
  Future<int> deleteRecord(int id) async {
    records.removeWhere((_, r) => r.id == id);
    return 1;
  }

  @override
  Future<List<HealthRecord>> getAllRecords() async {
    final list = records.values.toList();
    list.sort((a, b) => b.date.compareTo(a.date));
    return list;
  }

  @override
  Future<HealthRecord?> getRecordByDate(String date) async => records[date];

  @override
  Future<HealthRecord?> getRecordById(int id) async =>
      records.values.firstWhere((r) => r.id == id);

  @override
  Future<List<HealthRecord>> getRecordsForDateRange(String s, String e) async =>
      records.values.where((r) => r.date.compareTo(s) >= 0 && r.date.compareTo(e) <= 0).toList();

  @override
  Future<void> incrementWater(String date, int amountMl) async {}

  @override
  Future<int> saveRecord(HealthRecord record) async {
    records[record.date] = record;
    return 1;
  }

  @override
  Future<int> updateRecord(HealthRecord record) async {
    records[record.date] = record;
    return 1;
  }
}

void main() {
  group('RecordsViewModel Tests', () {
    late MockRecordRepo recordRepo;
    late MockOnboardingRepo onboardingRepo;
    late HealthRecordService recordService;
    late OnboardingService onboardingService;
    late RecordsViewModel viewModel;

    setUp(() async {
      recordRepo = MockRecordRepo();
      onboardingRepo = MockOnboardingRepo();
      recordService = HealthRecordService(repository: recordRepo);
      onboardingService = OnboardingService(repository: onboardingRepo);

      // Seed 3 sample records
      recordRepo.records['2026-10-24'] = HealthRecord(
        id: 1,
        date: '2026-10-24',
        steps: 7850,
        calories: 420,
        water: 1750,
        createdAt: DateTime(2026, 10, 24, 20, 45),
        updatedAt: DateTime(2026, 10, 24, 21, 12),
      );

      recordRepo.records['2026-10-23'] = HealthRecord(
        id: 2,
        date: '2026-10-23',
        steps: 10240,
        calories: 560,
        water: 2500,
        createdAt: DateTime(2026, 10, 23, 19, 0),
        updatedAt: DateTime(2026, 10, 23, 19, 30),
      );

      recordRepo.records['2026-10-22'] = HealthRecord(
        id: 3,
        date: '2026-10-22',
        steps: 6410,
        calories: 380,
        water: 1500,
        createdAt: DateTime(2026, 10, 22, 18, 0),
        updatedAt: DateTime(2026, 10, 22, 18, 0),
      );

      viewModel = RecordsViewModel(
        recordService: recordService,
        onboardingService: onboardingService,
      );
      await viewModel.loadRecords();
    });

    test('calculates summary statistics accurately', () {
      expect(viewModel.totalRecordsCount, equals(3));
      // Average steps: (7850 + 10240 + 6410) / 3 = 24500 / 3 = 8167
      expect(viewModel.averageSteps, equals(8167));
      // Total water: (1750 + 2500 + 1500) = 5750 ml = 5.75 L -> 5.8L
      expect(viewModel.totalWaterLitres, equals(5.75));
      expect(viewModel.totalWaterFormatted, equals('5.8L'));
    });

    test('handles empty records summary calculations without division by zero', () async {
      recordRepo.records.clear();
      await viewModel.loadRecords();

      expect(viewModel.totalRecordsCount, equals(0));
      expect(viewModel.averageSteps, equals(0));
      expect(viewModel.totalWaterLitres, equals(0.0));
      expect(viewModel.totalWaterFormatted, equals('0L'));
    });

    test('filters records by search query (date, month, year)', () {
      // Search by day "24"
      viewModel.setSearchQuery('24');
      expect(viewModel.filteredRecords.length, equals(1));
      expect(viewModel.filteredRecords.first.date, equals('2026-10-24'));

      // Search by month "Oct"
      viewModel.setSearchQuery('Oct');
      expect(viewModel.filteredRecords.length, equals(3));

      // Search non-existent "Nov"
      viewModel.setSearchQuery('Nov');
      expect(viewModel.filteredRecords.isEmpty, isTrue);

      viewModel.clearSearch();
      expect(viewModel.filteredRecords.length, equals(3));
    });

    test('filters records by date filter chips', () {
      // Custom date filter
      viewModel.setCustomDate(DateTime(2026, 10, 23));
      expect(viewModel.filteredRecords.length, equals(1));
      expect(viewModel.filteredRecords.first.date, equals('2026-10-23'));

      // Custom date range filter
      viewModel.setCustomDateRange(
        DateTimeRange(
          start: DateTime(2026, 10, 22),
          end: DateTime(2026, 10, 23),
        ),
      );
      expect(viewModel.filteredRecords.length, equals(2));

      // Reset to all
      viewModel.resetFilters();
      expect(viewModel.filteredRecords.length, equals(3));
    });

    test('sorts records correctly newest first and oldest first', () {
      // Default: newest first
      expect(viewModel.sortOrder, equals(RecordSortOrder.newestFirst));
      expect(viewModel.filteredRecords.first.date, equals('2026-10-24'));
      expect(viewModel.filteredRecords.last.date, equals('2026-10-22'));

      // Toggle to oldest first
      viewModel.toggleSortOrder();
      expect(viewModel.sortOrder, equals(RecordSortOrder.oldestFirst));
      expect(viewModel.filteredRecords.first.date, equals('2026-10-22'));
      expect(viewModel.filteredRecords.last.date, equals('2026-10-24'));
    });

    test('deletes record and updates list and summary stats', () async {
      final success = await viewModel.deleteRecord(1);
      expect(success, isTrue);
      expect(viewModel.totalRecordsCount, equals(2));
      expect(viewModel.filteredRecords.any((r) => r.id == 1), isFalse);
    });
  });
}
