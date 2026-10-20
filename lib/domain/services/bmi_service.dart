import '../../core/utils/bmi_calculator.dart';
import '../../data/models/user_profile.dart';

/// Structured result of a BMI calculation and assessment.
class BmiResult {
  final double bmi;
  final BmiCategory category;
  final String categoryLabel;
  final String explanation;
  final double gaugePosition;
  final bool isAdult;
  final String disclaimer;

  const BmiResult({
    required this.bmi,
    required this.category,
    required this.categoryLabel,
    required this.explanation,
    required this.gaugePosition,
    required this.isAdult,
    this.disclaimer = 'BMI is a general screening measure, not a diagnosis.',
  });

  /// Default fallback when measurements are missing or invalid.
  factory BmiResult.empty() {
    return const BmiResult(
      bmi: 0.0,
      category: BmiCategory.normal,
      categoryLabel: 'Not Available',
      explanation: 'Please provide valid height and weight measurements.',
      gaugePosition: 0.35,
      isAdult: true,
    );
  }
}

/// Domain service for calculating and assessing BMI according to standard adult criteria.
class BmiService {
  /// Assesses BMI from user profile.
  BmiResult assess(UserProfile profile) {
    return calculate(
      heightCm: profile.heightCm,
      weightKg: profile.weightKg,
      age: profile.age,
    );
  }

  /// Calculates BMI and category with safety and adult checks.
  BmiResult calculate({
    required double heightCm,
    required double weightKg,
    required int age,
  }) {
    if (heightCm <= 0 || weightKg <= 0) {
      return BmiResult.empty();
    }

    final bmi = BmiCalculator.calculateBmi(
      heightCm: heightCm,
      weightKg: weightKg,
    );
    final category = BmiCalculator.getCategory(bmi);
    final gaugePosition = BmiCalculator.getGaugePosition(bmi);
    final isAdult = age >= 18;

    final explanation = isAdult
        ? category.explanation
        : 'BMI percentiles differ for individuals under 18. This calculation provides general informational reference; consult a pediatrician for personalized guidance.';

    return BmiResult(
      bmi: bmi,
      category: category,
      categoryLabel: category.label,
      explanation: explanation,
      gaugePosition: gaugePosition,
      isAdult: isAdult,
    );
  }
}
