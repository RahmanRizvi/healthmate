import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/data/database/app_database.dart';
import 'package:healthmate/data/models/daily_goals.dart';
import 'package:healthmate/data/models/user_profile.dart';
import 'package:healthmate/data/repositories/onboarding_repository.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // Initialize FFI for local SQLite testing
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  group('OnboardingRepository SQLite Tests', () {
    late Database db;
    late AppDatabase appDatabase;
    late OnboardingRepository repository;

    setUp(() async {
      db = await openDatabase(
        inMemoryDatabasePath,
        version: 1,
        onCreate: (db, version) async {
          await db.execute('''
            CREATE TABLE ${AppDatabase.tableUserProfile} (
              id INTEGER PRIMARY KEY,
              full_name TEXT NOT NULL,
              date_of_birth TEXT NOT NULL,
              gender TEXT NOT NULL,
              height_cm REAL NOT NULL,
              weight_kg REAL NOT NULL,
              created_at TEXT NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');

          await db.execute('''
            CREATE TABLE ${AppDatabase.tableDailyGoals} (
              id INTEGER PRIMARY KEY,
              steps_goal INTEGER NOT NULL,
              water_goal_ml INTEGER NOT NULL,
              calories_goal_kcal INTEGER NOT NULL,
              updated_at TEXT NOT NULL
            )
          ''');
        },
      );

      appDatabase = AppDatabase();
      appDatabase.setDatabaseForTesting(db);
      repository = OnboardingRepository(db: appDatabase);
    });

    tearDown(() async {
      await db.close();
    });

    test('saves and retrieves UserProfile correctly', () async {
      final now = DateTime.now();
      final profile = UserProfile(
        id: 1,
        fullName: 'Alex Morgan',
        dateOfBirth: DateTime(1998, 5, 14),
        gender: 'Female',
        heightCm: 172.0,
        weightKg: 68.0,
        createdAt: now,
        updatedAt: now,
      );

      await repository.saveUserProfile(profile);

      final retrieved = await repository.getUserProfile();
      expect(retrieved, isNotNull);
      expect(retrieved!.fullName, equals('Alex Morgan'));
      expect(retrieved.heightCm, equals(172.0));
      expect(retrieved.weightKg, equals(68.0));
      expect(retrieved.gender, equals('Female'));
    });

    test('saves and retrieves DailyGoals correctly', () async {
      final now = DateTime.now();
      final goals = DailyGoals(
        id: 1,
        stepsGoal: 10000,
        waterGoalMl: 2500,
        caloriesGoalKcal: 500,
        updatedAt: now,
      );

      await repository.saveDailyGoals(goals);

      final retrieved = await repository.getDailyGoals();
      expect(retrieved, isNotNull);
      expect(retrieved!.stepsGoal, equals(10000));
      expect(retrieved.waterGoalMl, equals(2500));
      expect(retrieved.caloriesGoalKcal, equals(500));
    });

    test('isOnboardingCompleted returns true only when both profile and goals exist', () async {
      expect(await repository.isOnboardingCompleted(), isFalse);

      final now = DateTime.now();
      final profile = UserProfile(
        id: 1,
        fullName: 'Alex Morgan',
        dateOfBirth: DateTime(1998, 5, 14),
        gender: 'Female',
        heightCm: 172.0,
        weightKg: 68.0,
        createdAt: now,
        updatedAt: now,
      );

      await repository.saveUserProfile(profile);
      expect(await repository.isOnboardingCompleted(), isFalse); // Goals still missing

      final goals = DailyGoals(
        id: 1,
        stepsGoal: 10000,
        waterGoalMl: 2500,
        caloriesGoalKcal: 500,
        updatedAt: now,
      );

      await repository.saveDailyGoals(goals);
      expect(await repository.isOnboardingCompleted(), isTrue); // Both exist and valid
    });
  });
}
