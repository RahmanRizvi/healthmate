import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/healthmate_header.dart';
import '../../../core/widgets/onboarding_progress.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../domain/services/bmi_service.dart';
import '../../../domain/services/onboarding_service.dart';
import '../viewmodels/bmi_analysis_viewmodel.dart';
import 'daily_goals_screen.dart';

/// Screen 3: BMI Analysis display with interactive range gauge and screening interpretation.
class BmiAnalysisScreen extends StatelessWidget {
  final BmiAnalysisViewModel? viewModel;

  const BmiAnalysisScreen({super.key, this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) =>
          viewModel ??
          BmiAnalysisViewModel(
            onboardingService: ctx.read<OnboardingService>(),
            bmiService: ctx.read<BmiService>(),
          ),
      child: Scaffold(
        appBar: HealthMateHeader(
          onBackPressed: () => Navigator.maybePop(context),
        ),
        body: SafeArea(
          child: Consumer<BmiAnalysisViewModel>(
            builder: (context, vm, _) {
              if (vm.isLoading) {
                return const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
                );
              }

              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // Progress Indicator
                    const OnboardingProgress(
                      currentStep: 2,
                      stepTitle: 'BMI Analysis',
                    ),
                    const SizedBox(height: 24),

                    // Heading
                    const Text(
                      'Your health snapshot',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      "Here's a starting point for your wellness journey.",
                      style: TextStyle(
                        fontSize: 14.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Main BMI Card
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(22.0),
                      decoration: BoxDecoration(
                        color: AppColors.cardBackground,
                        borderRadius:
                            BorderRadius.circular(AppDimensions.radiusXXL),
                        border:
                            Border.all(color: AppColors.border.withAlpha(160)),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withAlpha(8),
                            blurRadius: 16,
                            offset: const Offset(0, 4),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Top row: "YOUR BMI" & Category Badge
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text(
                                'YOUR BMI',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.textSecondary,
                                  letterSpacing: 0.8,
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 6,
                                ),
                                decoration: BoxDecoration(
                                  color: vm.categoryBadgeBg,
                                  borderRadius: BorderRadius.circular(
                                    AppDimensions.radiusPill,
                                  ),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(
                                      Icons.check_circle_rounded,
                                      size: 16,
                                      color: vm.categoryColor,
                                    ),
                                    const SizedBox(width: 5),
                                    Text(
                                      vm.categoryLabel,
                                      style: TextStyle(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w700,
                                        color: vm.categoryColor,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // BMI Number and Unit
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.baseline,
                            textBaseline: TextBaseline.alphabetic,
                            children: [
                              Text(
                                vm.formattedBmi,
                                style: const TextStyle(
                                  fontSize: 42,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primaryDark,
                                  letterSpacing: -1.0,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text(
                                'kg/m²',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.textSecondary,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),

                          // BMI Range Gauge with position indicator
                          _BmiRangeGauge(
                            bmi: vm.bmi,
                            position: vm.gaugePosition,
                          ),
                          const SizedBox(height: 24),

                          // Height, Weight, Age Summary Row
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 16,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF8FAFC),
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.radiusL),
                              border: Border.all(
                                color: AppColors.border.withAlpha(120),
                              ),
                            ),
                            child: Row(
                              children: [
                                Expanded(
                                  child: _buildSummaryMetric(
                                    label: 'Height',
                                    value: vm.heightSummary,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 36,
                                  color: AppColors.border.withAlpha(160),
                                ),
                                Expanded(
                                  child: _buildSummaryMetric(
                                    label: 'Weight',
                                    value: vm.weightSummary,
                                  ),
                                ),
                                Container(
                                  width: 1,
                                  height: 36,
                                  color: AppColors.border.withAlpha(160),
                                ),
                                Expanded(
                                  child: _buildSummaryMetric(
                                    label: 'Age',
                                    value: vm.ageSummary,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),

                          // Explanation Box with Leaf Icon
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF1F5F3),
                              borderRadius:
                                  BorderRadius.circular(AppDimensions.radiusL),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Container(
                                  width: 36,
                                  height: 36,
                                  decoration: const BoxDecoration(
                                    color: AppColors.mintBadge,
                                    shape: BoxShape.circle,
                                  ),
                                  child: const Center(
                                    child: Icon(
                                      Icons.spa_rounded,
                                      color: AppColors.primary,
                                      size: 20,
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Text(
                                    vm.explanation,
                                    style: const TextStyle(
                                      fontSize: 13.5,
                                      height: 1.45,
                                      color: AppColors.textPrimary,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 14),

                          // Disclaimer
                          Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Icon(
                                Icons.info_outline_rounded,
                                size: 16,
                                color: AppColors.textMuted,
                              ),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  vm.disclaimer,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontStyle: FontStyle.italic,
                                    color: AppColors.textSecondary,
                                    height: 1.3,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Continue Button
                    PrimaryButton(
                      text: 'Continue',
                      onPressed: () {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => const DailyGoalsScreen(),
                          ),
                        );
                      },
                    ),
                    const SizedBox(height: 14),

                    // Edit Details Button
                    Center(
                      child: TextButton(
                        onPressed: () => Navigator.maybePop(context),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 20,
                            vertical: 8,
                          ),
                        ),
                        child: const Text(
                          'Edit details',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildSummaryMetric({
    required String label,
    required String value,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 12.5,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w500,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}

/// Horizontal multi-color BMI range indicator bar matching Figma Screen 3.
class _BmiRangeGauge extends StatelessWidget {
  final double bmi;
  final double position; // [0.0 - 1.0]

  const _BmiRangeGauge({
    required this.bmi,
    required this.position,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final totalWidth = constraints.maxWidth;
        const barHeight = 8.0;

        // Clamp indicator position
        final clampedPos = position.clamp(0.04, 0.96);
        final indicatorX = clampedPos * totalWidth;

        return Column(
          children: [
            // Indicator Pill & Pointer
            SizedBox(
              height: 38,
              child: Stack(
                clipBehavior: Clip.none,
                children: [
                  Positioned(
                    left: indicatorX - 22,
                    top: 0,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 3,
                          ),
                          decoration: BoxDecoration(
                            color: AppColors.primaryDark,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            bmi.toStringAsFixed(1),
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          width: 6,
                          height: 6,
                          decoration: const BoxDecoration(
                            color: AppColors.primaryDark,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // 4 Segmented Rounded Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(barHeight / 2),
              child: SizedBox(
                height: barHeight,
                child: Row(
                  children: const [
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFFBAE6FD), // Underweight
                        ),
                        child: SizedBox.expand(),
                      ),
                    ),
                    SizedBox(width: 2),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFF6EE7B7), // Normal
                        ),
                        child: SizedBox.expand(),
                      ),
                    ),
                    SizedBox(width: 2),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFFFDE68A), // Overweight
                        ),
                        child: SizedBox.expand(),
                      ),
                    ),
                    SizedBox(width: 2),
                    Expanded(
                      child: DecoratedBox(
                        decoration: BoxDecoration(
                          color: Color(0xFFFECDD3), // Obese
                        ),
                        child: SizedBox.expand(),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            // Range Labels Below
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Under',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '<18.5',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
                const Text(
                  '18.5',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                const Text(
                  '25.0',
                  style: TextStyle(
                    fontSize: 11,
                    color: AppColors.textSecondary,
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: const [
                    Text(
                      '30.0',
                      style: TextStyle(
                        fontSize: 11,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    Text(
                      '≥30',
                      style: TextStyle(
                        fontSize: 10,
                        color: AppColors.textMuted,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}
