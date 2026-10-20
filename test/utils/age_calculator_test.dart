import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/utils/age_calculator.dart';

void main() {
  group('AgeCalculator Tests', () {
    final referenceDate = DateTime(2024, 10, 20);

    test('calculates correct age when birthday has already passed this year', () {
      final dob = DateTime(1998, 5, 14);
      final age = AgeCalculator.calculateAge(dob, referenceDate);
      expect(age, equals(26));
    });

    test('calculates correct age when birthday has not occurred yet this year', () {
      final dob = DateTime(1998, 12, 1);
      final age = AgeCalculator.calculateAge(dob, referenceDate);
      expect(age, equals(25));
    });

    test('calculates correct age on exact birthday', () {
      final dob = DateTime(2000, 10, 20);
      final age = AgeCalculator.calculateAge(dob, referenceDate);
      expect(age, equals(24));
    });

    test('handles future birth date safely by returning 0', () {
      final futureDob = DateTime(2025, 1, 1);
      final age = AgeCalculator.calculateAge(futureDob, referenceDate);
      expect(age, equals(0));
    });

    test('formats age label properly', () {
      expect(AgeCalculator.formatAge(26), equals('Age: 26 years'));
      expect(AgeCalculator.formatAge(1), equals('Age: 1 year'));
      expect(AgeCalculator.formatAge(null), equals('Age: --'));
      expect(AgeCalculator.formatAge(0), equals('Age: --'));
    });

    test('formats short age label properly', () {
      expect(AgeCalculator.formatAgeShort(26), equals('26 yrs'));
      expect(AgeCalculator.formatAgeShort(null), equals('--'));
    });
  });
}
