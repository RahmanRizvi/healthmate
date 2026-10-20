import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Reusable 3-step progress indicator matching the Figma onboarding header.
class OnboardingProgress extends StatelessWidget {
  final int currentStep; // 1, 2, or 3
  final int totalSteps;
  final String stepTitle;

  const OnboardingProgress({
    super.key,
    required this.currentStep,
    this.totalSteps = 3,
    required this.stepTitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              'STEP $currentStep OF $totalSteps',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.primary,
                letterSpacing: 0.8,
              ),
            ),
            Text(
              stepTitle,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),

        // 3 Segmented Bars
        Row(
          children: List.generate(totalSteps, (index) {
            final isCompleted = (index + 1) <= currentStep;
            return Expanded(
              child: Container(
                height: 5.0,
                margin: EdgeInsets.only(
                  right: index < totalSteps - 1 ? 6.0 : 0.0,
                ),
                decoration: BoxDecoration(
                  color: isCompleted
                      ? AppColors.primary
                      : AppColors.progressTrack,
                  borderRadius: BorderRadius.circular(3.0),
                ),
              ),
            );
          }),
        ),
      ],
    );
  }
}
