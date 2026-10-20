import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/data/models/daily_goals.dart';
import 'package:healthmate/data/models/user_profile.dart';

void main() {
  group('Model Serialization Tests', () {
    test('UserProfile serialize toMap and deserialize fromMap accurately', () {
      final dob = DateTime(1998, 5, 14);
      final now = DateTime(2024, 10, 20);

      final profile = UserProfile(
        id: 1,
        fullName: 'Alex Morgan',
        dateOfBirth: dob,
        gender: 'Female',
        heightCm: 172.0,
        weightKg: 68.0,
        createdAt: now,
        updatedAt: now,
      );

      final map = profile.toMap();
      final fromMap = UserProfile.fromMap(map);

      expect(fromMap.id, equals(profile.id));
      expect(fromMap.fullName, equals('Alex Morgan'));
      expect(fromMap.gender, equals('Female'));
      expect(fromMap.heightCm, equals(172.0));
      expect(fromMap.weightKg, equals(68.0));
      expect(fromMap.dateOfBirth, equals(dob));
    });

    test('DailyGoals serialize toMap and deserialize fromMap accurately', () {
      final now = DateTime(2024, 10, 20);
      final goals = DailyGoals(
        id: 1,
        stepsGoal: 10000,
        waterGoalMl: 2500,
        caloriesGoalKcal: 500,
        updatedAt: now,
      );

      final map = goals.toMap();
      final fromMap = DailyGoals.fromMap(map);

      expect(fromMap.id, equals(goals.id));
      expect(fromMap.stepsGoal, equals(10000));
      expect(fromMap.waterGoalMl, equals(2500));
      expect(fromMap.caloriesGoalKcal, equals(500));
    });

    test('DailyGoals copyWith enforces minimum limits', () {
      final goals = DailyGoals.defaults();
      final updated = goals.copyWith(
        stepsGoal: 100, // Below min 500
        waterGoalMl: 50, // Below min 250
        caloriesGoalKcal: 10, // Below min 50
      );

      expect(updated.stepsGoal, equals(DailyGoals.minSteps));
      expect(updated.waterGoalMl, equals(DailyGoals.minWaterMl));
      expect(updated.caloriesGoalKcal, equals(DailyGoals.minCaloriesKcal));
    });
  });
}
