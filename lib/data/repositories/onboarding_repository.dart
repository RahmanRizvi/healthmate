import '../database/app_database.dart';
import '../models/user_profile.dart';
import '../models/daily_goals.dart';

/// Repository interface and implementation for managing onboarding data persistence.
abstract class IOnboardingRepository {
  Future<UserProfile?> getUserProfile();
  Future<void> saveUserProfile(UserProfile profile);
  Future<DailyGoals?> getDailyGoals();
  Future<void> saveDailyGoals(DailyGoals goals);
  Future<bool> isOnboardingCompleted();
}

class OnboardingRepository implements IOnboardingRepository {
  final AppDatabase _db;

  OnboardingRepository({AppDatabase? db}) : _db = db ?? AppDatabase();

  @override
  Future<UserProfile?> getUserProfile() async {
    return await _db.getUserProfile();
  }

  @override
  Future<void> saveUserProfile(UserProfile profile) async {
    await _db.saveUserProfile(profile);
  }

  @override
  Future<DailyGoals?> getDailyGoals() async {
    return await _db.getDailyGoals();
  }

  @override
  Future<void> saveDailyGoals(DailyGoals goals) async {
    await _db.saveDailyGoals(goals);
  }

  @override
  Future<bool> isOnboardingCompleted() async {
    final profile = await _db.getUserProfile();
    final goals = await _db.getDailyGoals();
    return profile != null &&
        profile.fullName.trim().isNotEmpty &&
        profile.heightCm > 0 &&
        profile.weightKg > 0 &&
        goals != null;
  }
}
