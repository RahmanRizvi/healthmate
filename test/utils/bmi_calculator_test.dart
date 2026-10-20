import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/utils/bmi_calculator.dart';

void main() {
  group('BmiCalculator Tests', () {
    test('calculates BMI correctly with example 172cm and 68kg', () {
      final bmi = BmiCalculator.calculateBmi(heightCm: 172, weightKg: 68);
      expect(bmi, equals(23.0));
    });

    test('returns 0.0 for invalid or non-positive measurements', () {
      expect(BmiCalculator.calculateBmi(heightCm: 0, weightKg: 68), equals(0.0));
      expect(BmiCalculator.calculateBmi(heightCm: -172, weightKg: 68), equals(0.0));
      expect(BmiCalculator.calculateBmi(heightCm: 172, weightKg: 0), equals(0.0));
      expect(BmiCalculator.calculateBmi(heightCm: 172, weightKg: -68), equals(0.0));
    });

    test('categorizes underweight correctly (< 18.5)', () {
      expect(BmiCalculator.getCategory(18.4), equals(BmiCategory.underweight));
      expect(BmiCalculator.getCategory(16.0), equals(BmiCategory.underweight));
    });

    test('categorizes normal weight correctly (18.5 - 24.9)', () {
      expect(BmiCalculator.getCategory(18.5), equals(BmiCategory.normal));
      expect(BmiCalculator.getCategory(23.0), equals(BmiCategory.normal));
      expect(BmiCalculator.getCategory(24.9), equals(BmiCategory.normal));
    });

    test('categorizes overweight correctly (25.0 - 29.9)', () {
      expect(BmiCalculator.getCategory(25.0), equals(BmiCategory.overweight));
      expect(BmiCalculator.getCategory(27.5), equals(BmiCategory.overweight));
      expect(BmiCalculator.getCategory(29.9), equals(BmiCategory.overweight));
    });

    test('categorizes obese correctly (>= 30.0)', () {
      expect(BmiCalculator.getCategory(30.0), equals(BmiCategory.obese));
      expect(BmiCalculator.getCategory(35.0), equals(BmiCategory.obese));
    });

    test('calculates gauge position within valid bounds [0.0, 1.0]', () {
      final posUnder = BmiCalculator.getGaugePosition(15.0);
      final posNormal = BmiCalculator.getGaugePosition(23.0);
      final posOver = BmiCalculator.getGaugePosition(27.0);
      final posObese = BmiCalculator.getGaugePosition(35.0);

      expect(posUnder, inInclusiveRange(0.0, 0.25));
      expect(posNormal, inInclusiveRange(0.25, 0.50));
      expect(posOver, inInclusiveRange(0.50, 0.75));
      expect(posObese, inInclusiveRange(0.75, 1.0));
    });
  });
}
