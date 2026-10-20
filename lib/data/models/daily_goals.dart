/// Data model representing daily health targets.
class DailyGoals {
  final int id;
  final int stepsGoal;
  final int waterGoalMl;
  final int caloriesGoalKcal;
  final DateTime updatedAt;

  // Defaults and increment boundaries
  static const int defaultSteps = 10000;
  static const int stepIncrement = 500;
  static const int minSteps = 500;

  static const int defaultWaterMl = 2500;
  static const int waterIncrement = 250;
  static const int minWaterMl = 250;

  static const int defaultCaloriesKcal = 500;
  static const int caloriesIncrement = 50;
  static const int minCaloriesKcal = 50;

  const DailyGoals({
    this.id = 1,
    this.stepsGoal = defaultSteps,
    this.waterGoalMl = defaultWaterMl,
    this.caloriesGoalKcal = defaultCaloriesKcal,
    required this.updatedAt,
  });

  /// Factory creating default targets.
  factory DailyGoals.defaults() {
    return DailyGoals(
      id: 1,
      stepsGoal: defaultSteps,
      waterGoalMl: defaultWaterMl,
      caloriesGoalKcal: defaultCaloriesKcal,
      updatedAt: DateTime.now(),
    );
  }

  DailyGoals copyWith({
    int? id,
    int? stepsGoal,
    int? waterGoalMl,
    int? caloriesGoalKcal,
    DateTime? updatedAt,
  }) {
    return DailyGoals(
      id: id ?? this.id,
      stepsGoal: (stepsGoal ?? this.stepsGoal) < minSteps
          ? minSteps
          : (stepsGoal ?? this.stepsGoal),
      waterGoalMl: (waterGoalMl ?? this.waterGoalMl) < minWaterMl
          ? minWaterMl
          : (waterGoalMl ?? this.waterGoalMl),
      caloriesGoalKcal: (caloriesGoalKcal ?? this.caloriesGoalKcal) < minCaloriesKcal
          ? minCaloriesKcal
          : (caloriesGoalKcal ?? this.caloriesGoalKcal),
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'steps_goal': stepsGoal,
      'water_goal_ml': waterGoalMl,
      'calories_goal_kcal': caloriesGoalKcal,
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory DailyGoals.fromMap(Map<String, dynamic> map) {
    return DailyGoals(
      id: map['id'] as int? ?? 1,
      stepsGoal: map['steps_goal'] as int? ?? defaultSteps,
      waterGoalMl: map['water_goal_ml'] as int? ?? defaultWaterMl,
      caloriesGoalKcal: map['calories_goal_kcal'] as int? ?? defaultCaloriesKcal,
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DailyGoals &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          stepsGoal == other.stepsGoal &&
          waterGoalMl == other.waterGoalMl &&
          caloriesGoalKcal == other.caloriesGoalKcal;

  @override
  int get hashCode =>
      id.hashCode ^
      stepsGoal.hashCode ^
      waterGoalMl.hashCode ^
      caloriesGoalKcal.hashCode;
}
