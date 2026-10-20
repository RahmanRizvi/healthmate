import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Categories of Body Mass Index for adults based on standard reference ranges.
enum BmiCategory {
  underweight,
  normal,
  overweight,
  obese;

  String get label {
    switch (this) {
      case BmiCategory.underweight:
        return 'Underweight';
      case BmiCategory.normal:
        return 'Normal weight';
      case BmiCategory.overweight:
        return 'Overweight';
      case BmiCategory.obese:
        return 'Obese';
    }
  }

  Color get color {
    switch (this) {
      case BmiCategory.underweight:
        return AppColors.bmiUnderweight;
      case BmiCategory.normal:
        return AppColors.statusSuccess;
      case BmiCategory.overweight:
        return const Color(0xFFD97706); // Amber
      case BmiCategory.obese:
        return const Color(0xFFDC2626); // Coral red
    }
  }

  Color get badgeBackground {
    switch (this) {
      case BmiCategory.underweight:
        return const Color(0xFFEFF6FF);
      case BmiCategory.normal:
        return const Color(0xFFD1FAE5);
      case BmiCategory.overweight:
        return const Color(0xFFFEF3C7);
      case BmiCategory.obese:
        return const Color(0xFFFEE2E2);
    }
  }

  String get explanation {
    switch (this) {
      case BmiCategory.underweight:
        return 'Your BMI indicates you may be underweight. Focusing on nutrient-dense meals and balanced habits can help support healthy weight and stamina.';
      case BmiCategory.normal:
        return 'Your BMI falls in the healthy weight range. Maintaining this balance supports cardiovascular health and steady energy levels.';
      case BmiCategory.overweight:
        return 'Your BMI is in the overweight range. Small, consistent daily habits like increased daily movement and hydration can make a meaningful difference.';
      case BmiCategory.obese:
        return 'Your BMI is in the obesity range. Prioritizing gradual lifestyle changes and consulting a healthcare professional can support your long-term wellness.';
    }
  }
}

/// Utility for calculating BMI and interpreting results.
class BmiCalculator {
  BmiCalculator._();

  /// Calculates BMI: weight (kg) / (height (m) ^ 2).
  /// Returns 0.0 if inputs are non-positive or invalid.
  static double calculateBmi({
    required double heightCm,
    required double weightKg,
  }) {
    if (heightCm <= 0 || weightKg <= 0) {
      return 0.0;
    }

    final heightM = heightCm / 100.0;
    final bmi = weightKg / (heightM * heightM);

    if (bmi.isNaN || bmi.isInfinite) {
      return 0.0;
    }

    // Round to one decimal place
    return double.parse(bmi.toStringAsFixed(1));
  }

  /// Classifies adult BMI into standard reference categories.
  /// - Underweight: < 18.5
  /// - Normal weight: 18.5 - 24.9
  /// - Overweight: 25.0 - 29.9
  /// - Obese: >= 30.0
  static BmiCategory getCategory(double bmi) {
    if (bmi < 18.5) {
      return BmiCategory.underweight;
    } else if (bmi < 25.0) {
      return BmiCategory.normal;
    } else if (bmi < 30.0) {
      return BmiCategory.overweight;
    } else {
      return BmiCategory.obese;
    }
  }

  /// Calculates the proportional position [0.0 - 1.0] of a BMI value
  /// across the 4 visual segments on the range indicator bar.
  /// Segment 1 (Underweight): 12.0 - 18.5 -> [0.00, 0.25]
  /// Segment 2 (Normal):      18.5 - 25.0 -> [0.25, 0.50]
  /// Segment 3 (Overweight):  25.0 - 30.0 -> [0.50, 0.75]
  /// Segment 4 (Obese):       30.0 - 40.0 -> [0.75, 1.00]
  static double getGaugePosition(double bmi) {
    if (bmi <= 12.0) return 0.0;
    if (bmi >= 40.0) return 1.0;

    if (bmi < 18.5) {
      final t = (bmi - 12.0) / (18.5 - 12.0);
      return (t * 0.25).clamp(0.0, 0.25);
    } else if (bmi < 25.0) {
      final t = (bmi - 18.5) / (25.0 - 18.5);
      return (0.25 + (t * 0.25)).clamp(0.25, 0.50);
    } else if (bmi < 30.0) {
      final t = (bmi - 25.0) / (30.0 - 25.0);
      return (0.50 + (t * 0.25)).clamp(0.50, 0.75);
    } else {
      final t = (bmi - 30.0) / (40.0 - 30.0);
      return (0.75 + (t * 0.25)).clamp(0.75, 1.0);
    }
  }
}
