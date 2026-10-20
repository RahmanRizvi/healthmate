import '../../core/utils/age_calculator.dart';

/// Data model representing the user's personal details.
class UserProfile {
  final int id;
  final String fullName;
  final DateTime dateOfBirth;
  final String gender;
  final double heightCm;
  final double weightKg;
  final DateTime createdAt;
  final DateTime updatedAt;

  const UserProfile({
    this.id = 1,
    required this.fullName,
    required this.dateOfBirth,
    required this.gender,
    required this.heightCm,
    required this.weightKg,
    required this.createdAt,
    required this.updatedAt,
  });

  /// Chronological age derived dynamically from [dateOfBirth].
  int get age => AgeCalculator.calculateAge(dateOfBirth);

  /// Label for age (e.g. "Age: 26 years").
  String get ageLabel => AgeCalculator.formatAge(age);

  /// Short label for age (e.g. "26 yrs").
  String get ageShortLabel => AgeCalculator.formatAgeShort(age);

  UserProfile copyWith({
    int? id,
    String? fullName,
    DateTime? dateOfBirth,
    String? gender,
    double? heightCm,
    double? weightKg,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: id ?? this.id,
      fullName: fullName ?? this.fullName,
      dateOfBirth: dateOfBirth ?? this.dateOfBirth,
      gender: gender ?? this.gender,
      heightCm: heightCm ?? this.heightCm,
      weightKg: weightKg ?? this.weightKg,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'full_name': fullName,
      'date_of_birth': dateOfBirth.toIso8601String(),
      'gender': gender,
      'height_cm': heightCm,
      'weight_kg': weightKg,
      'created_at': createdAt.toIso8601String(),
      'updated_at': updatedAt.toIso8601String(),
    };
  }

  factory UserProfile.fromMap(Map<String, dynamic> map) {
    return UserProfile(
      id: map['id'] as int? ?? 1,
      fullName: map['full_name'] as String? ?? '',
      dateOfBirth: DateTime.tryParse(map['date_of_birth'] as String? ?? '') ??
          DateTime(2000, 1, 1),
      gender: map['gender'] as String? ?? 'Prefer not to say',
      heightCm: (map['height_cm'] as num?)?.toDouble() ?? 0.0,
      weightKg: (map['weight_kg'] as num?)?.toDouble() ?? 0.0,
      createdAt: DateTime.tryParse(map['created_at'] as String? ?? '') ??
          DateTime.now(),
      updatedAt: DateTime.tryParse(map['updated_at'] as String? ?? '') ??
          DateTime.now(),
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          id == other.id &&
          fullName == other.fullName &&
          dateOfBirth == other.dateOfBirth &&
          gender == other.gender &&
          heightCm == other.heightCm &&
          weightKg == other.weightKg;

  @override
  int get hashCode =>
      id.hashCode ^
      fullName.hashCode ^
      dateOfBirth.hashCode ^
      gender.hashCode ^
      heightCm.hashCode ^
      weightKg.hashCode;
}
