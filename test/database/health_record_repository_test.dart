import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/data/database/app_database.dart';
import 'package:healthmate/data/models/health_record.dart';
import 'package:healthmate/data/repositories/health_record_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('HealthRecordRepository SQLite Tests', () {
    late Database db;
    late AppDatabase appDatabase;
    late HealthRecordRepository repository;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 2,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE ${AppDatabase.tableHealthRecords} (
              id INTEGER PRIMARY KEY AUTOINCREMENT,
              date TEXT NOT NULL UNIQUE,
              steps INTEGER NOT NULL,
              calories INTEGER NOT NULL,
              water INTEGER NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        },
      );

      appDatabase = AppDatabase();
      appDatabase.setDatabaseForTesting(db);
      repository = HealthRecordRepository(db: appDatabase);
    });

    tearDown(() async {
      await db.close();
    });

    test('saves and retrieves HealthRecord by date', () async {
      final now = DateTime(2026, 10, 24);
      final record = HealthRecord(
        date: '2026-10-24',
        steps: 6420,
        calories: 1480,
        water: 1750,
        createdAt: now,
        updatedAt: now,
      );

      await repository.saveRecord(record);

      final retrieved = await repository.getRecordByDate('2026-10-24');
      expect(retrieved, isNotNull);
      expect(retrieved!.steps, equals(6420));
      expect(retrieved.calories, equals(1480));
      expect(retrieved.water, equals(1750));
    });

    test('duplicate-date policy updates existing record rather than creating duplicates', () async {
      final now = DateTime(2026, 10, 24);
      final record1 = HealthRecord(
        date: '2026-10-24',
        steps: 5000,
        calories: 300,
        water: 1000,
        createdAt: now,
        updatedAt: now,
      );
      await repository.saveRecord(record1);

      // Save again for the same date with updated measurements
      final record2 = HealthRecord(
        date: '2026-10-24',
        steps: 8000,
        calories: 500,
        water: 2000,
        createdAt: now,
        updatedAt: now.add(const Duration(hours: 2)),
      );
      await repository.saveRecord(record2);

      final allRecords = await repository.getAllRecords();
      expect(allRecords.length, equals(1)); // Only 1 record for that date
      expect(allRecords.first.steps, equals(8000));
      expect(allRecords.first.calories, equals(500));
      expect(allRecords.first.water, equals(2000));
    });

    test('incrementWater adds water amount without overwriting steps or calories', () async {
      final now = DateTime(2026, 10, 24);
      final record = HealthRecord(
        date: '2026-10-24',
        steps: 7000,
        calories: 400,
        water: 1500,
        createdAt: now,
        updatedAt: now,
      );
      await repository.saveRecord(record);

      // Perform +250 ml quick add
      await repository.incrementWater('2026-10-24', 250);

      final updated = await repository.getRecordByDate('2026-10-24');
      expect(updated, isNotNull);
      expect(updated!.water, equals(1750)); // 1500 + 250
      expect(updated.steps, equals(7000)); // Unchanged
      expect(updated.calories, equals(400)); // Unchanged
    });

    test('incrementWater creates new day record with 0 steps/calories if non-existent', () async {
      await repository.incrementWater('2026-10-25', 250);

      final record = await repository.getRecordByDate('2026-10-25');
      expect(record, isNotNull);
      expect(record!.water, equals(250));
      expect(record.steps, equals(0));
      expect(record.calories, equals(0));
    });

    test('deletes record successfully by ID', () async {
      final record = HealthRecord(
        date: '2026-10-24',
        steps: 3000,
        calories: 200,
        water: 1000,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final id = await repository.saveRecord(record);

      final deletedCount = await repository.deleteRecord(id);
      expect(deletedCount, equals(1));

      final check = await repository.getRecordById(id);
      expect(check, isNull);
    });
  });
}
