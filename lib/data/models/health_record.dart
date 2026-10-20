import '../../core/utils/date_formatter.dart';

/// Data model representing a single day's health and wellness entry.
class HealthRecord {
  final int? id;
  final String date; // `yyyy-MM-dd` format
  final int steps;
  final int calories;
  final int water; // in millilitres (ml)
  final DateTime createdAt;
  final DateTime updatedAt;

  const HealthRecord({
    this.id,
    required this.date,
    required this.steps,
    required this.calories,
    required this.water,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Factory creating an empty/zero entry for a specific calendar [DateTime].
  factory HealthRecord.empty(DateTime dateTime) {
    final now = DateTime.now();
    return HealthRecord(
      date: DateFormatter.toIsoDateString(dateTime),
      steps: 0,
      calories: 0,
      water: 0,
      createdAt: now,
      updatedAt: now,
    );
  }

  /// Parses the stored ISO date string into a local [DateTime].
  DateTime get dateTime => DateFormatter.parseIsoDate(date);

  HealthRecord copyWith({
    int? id,
    String? date,
    int? steps,
    int? calories,
    int? water,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return HealthRecord(
      id: id ?? this.id,
      date: date ?? this.date,
      steps: (steps ?? this.steps) < 0 ? 0 : (steps ?? this.steps),
      calories: (calories ?? this.calories) < 0 ? 0 : (calories ?? this.calories),
      water: (water ?? this.water) < 0 ? 0 : (water ?? this.water),
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'date': date,
      'steps': steps,
      'calories': calories,
      'water': water,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory HealthRecord.fromMap(Map<String, dynamic> map) {
    return HealthRecord(
      id: map['id'] as int?,
      date: map['date'] as String? ?? '',
      steps: map['steps'] as int? ?? 0,
      calories: map['calories'] as int? ?? 0,
      water: map['water'] as int? ?? 0,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HealthRecord &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          date == other.date &&
          steps == other.steps &&
          calories == other.calories &&
          water == other.water;

  @override
  int get hashCode =>
      id.hashCode ^
      date.hashCode ^
      steps.hashCode ^
      calories.hashCode ^
      water.hashCode;
}
