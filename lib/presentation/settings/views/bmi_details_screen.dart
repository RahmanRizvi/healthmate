import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/bmi_calculator.dart';
import '../../../core/widgets/healthmate_header.dart';
import '../../../domain/services/bmi_service.dart';

/// Screen explaining the Body Mass Index calculation, categories, and clinical limitations.
class BmiDetailsScreen extends StatelessWidget {
  final BmiResult bmiResult;
  final double heightCm;
  final double weightKg;
  final int age;

  const BmiDetailsScreen({
    super.key,
    required this.bmiResult,
    required this.heightCm,
    required this.weightKg,
    required this.age,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final heightM = heightCm / 100.0;
    final heightSquared = heightM * heightM;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HealthMateHeader.detail(
        title: 'BMI Information',
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Current Result Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border.withAlpha(160),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            'Your Assessment',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 12,
                            vertical: 5,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.pillBackgroundDark
                                : bmiResult.category.badgeBackground,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 7,
                                height: 7,
                                decoration: BoxDecoration(
                                  color: bmiResult.category.color,
                                  shape: BoxShape.circle,
                                ),
                              ),
                              const SizedBox(width: 6),
                              Text(
                                '${bmiResult.categoryLabel} (${bmiResult.bmi.toStringAsFixed(1)})',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? AppColors.mint
                                      : bmiResult.category.color,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      '${bmiResult.bmi.toStringAsFixed(1)} kg/m²',
                      style: TextStyle(
                        fontSize: 34,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.mint : AppColors.primaryDark,
                        letterSpacing: -1,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      bmiResult.explanation,
                      style: TextStyle(
                        fontSize: 14,
                        color: theme.colorScheme.onSurface,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Formula Breakdown Card
              _buildSectionTitle(context, 'Calculation Formula'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20.0),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border.withAlpha(160),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 14,
                      ),
                      decoration: BoxDecoration(
                        color: isDark
                            ? AppColors.cardElevatedDark
                            : AppColors.infoBannerBackground,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                      ),
                      child: Text(
                        'BMI = Weight (kg) / [Height (m)]²',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.mint : AppColors.primaryDark,
                          fontFamily: 'monospace',
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Text(
                      'Step-by-step for your profile:',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 8),
                    _buildCalculationStep(
                      step: '1. Height in metres',
                      detail: '${heightCm.toStringAsFixed(0)} cm = ${heightM.toStringAsFixed(2)} m',
                      context: context,
                    ),
                    _buildCalculationStep(
                      step: '2. Height squared',
                      detail: '${heightM.toStringAsFixed(2)} × ${heightM.toStringAsFixed(2)} = ${heightSquared.toStringAsFixed(2)} m²',
                      context: context,
                    ),
                    _buildCalculationStep(
                      step: '3. Divide weight by height²',
                      detail: '${weightKg.toStringAsFixed(1)} kg / ${heightSquared.toStringAsFixed(2)} m² = ${bmiResult.bmi.toStringAsFixed(1)}',
                      context: context,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Category Reference Table
              _buildSectionTitle(context, 'Adult Reference Ranges'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18.0),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border.withAlpha(160),
                  ),
                ),
                child: Column(
                  children: [
                    _buildCategoryRow(
                      category: 'Underweight',
                      range: 'Below 18.5',
                      color: AppColors.bmiUnderweight,
                      isSelected: bmiResult.category == BmiCategory.underweight,
                      context: context,
                    ),
                    const Divider(height: 18),
                    _buildCategoryRow(
                      category: 'Healthy range',
                      range: '18.5 – 24.9',
                      color: AppColors.statusSuccess,
                      isSelected: bmiResult.category == BmiCategory.normal,
                      context: context,
                    ),
                    const Divider(height: 18),
                    _buildCategoryRow(
                      category: 'Overweight',
                      range: '25.0 – 29.9',
                      color: AppColors.bmiOverweight,
                      isSelected: bmiResult.category == BmiCategory.overweight,
                      context: context,
                    ),
                    const Divider(height: 18),
                    _buildCategoryRow(
                      category: 'Obesity',
                      range: '30.0 or above',
                      color: AppColors.bmiObese,
                      isSelected: bmiResult.category == BmiCategory.obese,
                      context: context,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Clinical Limitations & Pediatric Note
              _buildSectionTitle(context, 'Important Disclosures'),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18.0),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border.withAlpha(160),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.info_outline_rounded,
                          color: isDark ? AppColors.mint : AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Screening Tool, Not Diagnosis',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'BMI is a population-level screening indicator of weight-to-height proportion. It does not directly quantify body fat percentage, muscular mass, bone density, or adipose distribution. Athletes with high muscle mass may be classified as overweight despite having low body fat.',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 14),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.child_care_rounded,
                          color: isDark ? AppColors.mint : AppColors.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Pediatric Considerations',
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Standard adult BMI categories do not apply to children or adolescents under age 18. Pediatric growth requires evaluation using age-and-sex-specific growth percentile charts from certified health practitioners.',
                      style: TextStyle(
                        fontSize: 13,
                        color: theme.colorScheme.onSurfaceVariant,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.mint : AppColors.primaryDark,
        ),
      ),
    );
  }

  Widget _buildCalculationStep({
    required String step,
    required String detail,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              step,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            detail,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategoryRow({
    required String category,
    required String range,
    required Color color,
    required bool isSelected,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 4.0, horizontal: 6.0),
      decoration: isSelected
          ? BoxDecoration(
              color: isDark ? AppColors.cardElevatedDark : AppColors.mintBadge,
              borderRadius: BorderRadius.circular(8),
            )
          : null,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 10),
                Flexible(
                  child: Text(
                    category,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                      color: isSelected
                          ? (isDark ? AppColors.mint : AppColors.primaryDark)
                          : theme.colorScheme.onSurface,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          Row(
            children: [
              Text(
                range,
                style: TextStyle(
                  fontSize: 13.5,
                  fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  color: isSelected
                      ? (isDark ? AppColors.mint : AppColors.primaryDark)
                      : theme.colorScheme.onSurfaceVariant,
                ),
              ),
              if (isSelected) ...[
                const SizedBox(width: 8),
                Icon(
                  Icons.check_circle_rounded,
                  size: 16,
                  color: isDark ? AppColors.mint : AppColors.statusSuccess,
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
