import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/user_profile.dart';
import '../models/daily_goals.dart';
import '../models/health_record.dart';

/// SQLite Database Manager for HealthMate.
class AppDatabase {
  static const String _databaseName = 'healthmate.db';
  static const int _databaseVersion = 2;

  // Table names
  static const String tableUserProfile = 'user_profile';
  static const String tableDailyGoals = 'daily_goals';
  static const String tableHealthRecords = 'health_records';

  // Singleton instance
  static final AppDatabase _instance = AppDatabase._internal();
  factory AppDatabase() => _instance;
  AppDatabase._internal();

  Database? _database;

  /// Allows injecting a custom database or in-memory DB for unit tests.
  void setDatabaseForTesting(Database db) {
    _database = db;
  }

  /// Returns the database instance, initializing it if necessary.
  Future<Database> get database async {
    if (_database != null) {
      return _database!;
    }
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = p.join(dbPath, _databaseName);

    return await openDatabase(
      path,
      version: _databaseVersion,
      onCreate: _onCreate,
      onUpgrade: _onUpgrade,
    );
  }

  FutureOr<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE $tableUserProfile (
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
      CREATE TABLE $tableDailyGoals (
        id INTEGER PRIMARY KEY,
        steps_goal INTEGER NOT NULL,
        water_goal_ml INTEGER NOT NULL,
        calories_goal_kcal INTEGER NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');

    await db.execute('''
      CREATE TABLE $tableHealthRecords (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        date TEXT NOT NULL UNIQUE,
        steps INTEGER NOT NULL,
        calories INTEGER NOT NULL,
        water INTEGER NOT NULL,
        created_at TEXT NOT NULL,
        updated_at TEXT NOT NULL
      )
    ''');
  }

  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('''
        CREATE TABLE IF NOT EXISTS $tableHealthRecords (
          id INTEGER PRIMARY KEY AUTOINCREMENT,
          date TEXT NOT NULL UNIQUE,
          steps INTEGER NOT NULL,
          calories INTEGER NOT NULL,
          water INTEGER NOT NULL,
          created_at TEXT NOT NULL,
          updated_at TEXT NOT NULL
        )
      ''');
    }
  }

  // ================= User Profile CRUD =================

  /// Inserts or updates the single user profile record.
  Future<int> saveUserProfile(UserProfile profile) async {
    final db = await database;
    return await db.insert(
      tableUserProfile,
      profile.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves the current user profile, or null if none exists.
  Future<UserProfile?> getUserProfile() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableUserProfile,
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return UserProfile.fromMap(maps.first);
    }
    return null;
  }

  // ================= Daily Goals CRUD =================

  /// Inserts or updates the daily goals record.
  Future<int> saveDailyGoals(DailyGoals goals) async {
    final db = await database;
    return await db.insert(
      tableDailyGoals,
      goals.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves the saved daily goals, or null if not yet configured.
  Future<DailyGoals?> getDailyGoals() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableDailyGoals,
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return DailyGoals.fromMap(maps.first);
    }
    return null;
  }

  // ================= Health Records CRUD =================

  /// Inserts or updates a health record for a given date.
  /// Uses [ConflictAlgorithm.replace] to enforce one record per calendar day.
  Future<int> saveHealthRecord(HealthRecord record) async {
    final db = await database;
    return await db.insert(
      tableHealthRecords,
      record.toMap(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Retrieves a health record by its unique ID.
  Future<HealthRecord?> getHealthRecordById(int id) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableHealthRecords,
      where: 'id = ?',
      whereArgs: [id],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return HealthRecord.fromMap(maps.first);
    }
    return null;
  }

  /// Retrieves a health record by ISO date string (`yyyy-MM-dd`).
  Future<HealthRecord?> getHealthRecordByDate(String date) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableHealthRecords,
      where: 'date = ?',
      whereArgs: [date],
      limit: 1,
    );

    if (maps.isNotEmpty) {
      return HealthRecord.fromMap(maps.first);
    }
    return null;
  }

  /// Retrieves all health records sorted newest first.
  Future<List<HealthRecord>> getAllHealthRecords() async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableHealthRecords,
      orderBy: 'date DESC',
    );

    return maps.map((m) => HealthRecord.fromMap(m)).toList();
  }

  /// Retrieves health records within an inclusive date range (`yyyy-MM-dd`).
  Future<List<HealthRecord>> getHealthRecordsForDateRange(
    String startDate,
    String endDate,
  ) async {
    final db = await database;
    final List<Map<String, dynamic>> maps = await db.query(
      tableHealthRecords,
      where: 'date >= ? AND date <= ?',
      whereArgs: [startDate, endDate],
      orderBy: 'date ASC',
    );

    return maps.map((m) => HealthRecord.fromMap(m)).toList();
  }

  /// Deletes a health record by its ID.
  Future<int> deleteHealthRecord(int id) async {
    final db = await database;
    return await db.delete(
      tableHealthRecords,
      where: 'id = ?',
      whereArgs: [id],
    );
  }

  /// Atomically increments water intake for a specific date without overwriting steps or calories.
  /// If no record exists for that date, creates a new entry with the water amount.
  Future<void> incrementWaterForDate(String date, int amountMl) async {
    final db = await database;
    await db.transaction((txn) async {
      final existing = await txn.query(
        tableHealthRecords,
        where: 'date = ?',
        whereArgs: [date],
        limit: 1,
      );

      final now = DateTime.now().toIso8601String();

      if (existing.isNotEmpty) {
        final currentWater = (existing.first['water'] as int?) ?? 0;
        final newWater = currentWater + amountMl;
        await txn.update(
          tableHealthRecords,
          {
            'water': newWater,
            'updated_at': now,
          },
          where: 'date = ?',
          whereArgs: [date],
        );
      } else {
        await txn.insert(
          tableHealthRecords,
          {
            'date': date,
            'steps': 0,
            'calories': 0,
            'water': amountMl,
            'created_at': now,
            'updated_at': now,
          },
        );
      }
    });
  }

  /// Closes database connection.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
