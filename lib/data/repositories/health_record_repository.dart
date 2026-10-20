import '../database/app_database.dart';
import '../models/health_record.dart';

/// Repository interface for SQLite health record operations.
abstract class IHealthRecordRepository {
  Future<HealthRecord?> getRecordById(int id);
  Future<HealthRecord?> getRecordByDate(String date);
  Future<List<HealthRecord>> getAllRecords();
  Future<List<HealthRecord>> getRecordsForDateRange(String startDate, String endDate);
  Future<int> saveRecord(HealthRecord record);
  Future<int> deleteRecord(int id);
  Future<void> incrementWater(String date, int amountMl);
}

class HealthRecordRepository implements IHealthRecordRepository {
  final AppDatabase _db;

  HealthRecordRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  @override
  Future<HealthRecord?> getRecordById(int id) async {
    return await _db.getHealthRecordById(id);
  }

  @override
  Future<HealthRecord?> getRecordByDate(String date) async {
    return await _db.getHealthRecordByDate(date);
  }

  @override
  Future<List<HealthRecord>> getAllRecords() async {
    return await _db.getAllHealthRecords();
  }

  @override
  Future<List<HealthRecord>> getRecordsForDateRange(
    String startDate,
    String endDate,
  ) async {
    return await _db.getHealthRecordsForDateRange(startDate, endDate);
  }

  @override
  Future<int> saveRecord(HealthRecord record) async {
    return await _db.saveHealthRecord(record);
  }

  @override
  Future<int> deleteRecord(int id) async {
    return await _db.deleteHealthRecord(id);
  }

  @override
  Future<void> incrementWater(String date, int amountMl) async {
    await _db.incrementWaterForDate(date, amountMl);
  }
}
