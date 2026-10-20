import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/utils/bmi_calculator.dart';
import 'package:healthmate/data/models/user_profile.dart';
import 'package:healthmate/domain/services/bmi_service.dart';

void main() {
  group('BmiService Tests', () {
    late BmiService bmiService;

    setUp(() {
      bmiService = BmiService();
    });

    test('assesses adult profile accurately', () {
      final profile = UserProfile(
        id: 1,
        fullName: 'Alex Morgan',
        dateOfBirth: DateTime(1998, 5, 14),
        gender: 'Female',
        heightCm: 172.0,
        weightKg: 68.0,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final result = bmiService.assess(profile);

      expect(result.bmi, equals(23.0));
      expect(result.category, equals(BmiCategory.normal));
      expect(result.categoryLabel, equals('Normal weight'));
      expect(result.isAdult, isTrue);
      expect(
        result.explanation,
        contains('Your BMI falls in the healthy weight range'),
      );
    });

    test('provides pediatric safeguard explanation when age is under 18', () {
      final result = bmiService.calculate(
        heightCm: 160.0,
        weightKg: 50.0,
        age: 15,
      );

      expect(result.isAdult, isFalse);
      expect(result.explanation, contains('consult a pediatrician'));
    });

    test('handles invalid zero measurements safely with fallback', () {
      final result = bmiService.calculate(
        heightCm: 0,
        weightKg: 0,
        age: 25,
      );

      expect(result.bmi, equals(0.0));
      expect(result.categoryLabel, equals('Not Available'));
    });
  });
}
