import 'dart:async';
import 'package:path/path.dart' as p;
import 'package:sqflite/sqflite.dart';
import '../models/user_profile.dart';
import '../models/daily_goals.dart';

/// SQLite Database Manager for HealthMate.
class AppDatabase {
  static const String _databaseName = 'healthmate.db';
  static const int _databaseVersion = 1;

  // Table names
  static const String tableUserProfile = 'user_profile';
  static const String tableDailyGoals = 'daily_goals';

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
  }

  FutureOr<void> _onUpgrade(Database db, int oldVersion, int newVersion) async {
    // Handled incrementally if schema changes in future versions
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

  /// Closes database connection.
  Future<void> close() async {
    if (_database != null) {
      await _database!.close();
      _database = null;
    }
  }
}
