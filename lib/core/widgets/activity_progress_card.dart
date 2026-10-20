import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// Card for Steps walked on the Home Dashboard.
class StepsActivityCard extends StatelessWidget {
  final int currentSteps;
  final int stepGoal;
  final int? averageSteps;

  const StepsActivityCard({
    super.key,
    required this.currentSteps,
    required this.stepGoal,
    this.averageSteps,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');
    final formattedSteps = numberFormat.format(currentSteps);
    final formattedGoal = numberFormat.format(stepGoal);

    final double ratio = stepGoal > 0 ? (currentSteps / stepGoal).clamp(0.0, 1.0) : 0.0;

    final subtitle = averageSteps != null && averageSteps! > 0
        ? 'Average: ${numberFormat.format(averageSteps)} steps / day'
        : 'Target: $formattedGoal steps';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXXL),
        border: Border.all(color: AppColors.border.withAlpha(160)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.mintBadge,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.directions_walk_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Steps walked',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Steps count display
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formattedSteps,
                style: const TextStyle(
                  fontSize: 34,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                  letterSpacing: -0.8,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '/ $formattedGoal steps',
                style: const TextStyle(
                  fontSize: 14.5,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Linear Progress Indicator
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 8,
              color: AppColors.primary,
              backgroundColor: const Color(0xFFE5E7EB),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card for Calories burned on the Home Dashboard.
class CaloriesActivityCard extends StatelessWidget {
  final int currentCalories;
  final int caloriesGoal;

  const CaloriesActivityCard({
    super.key,
    required this.currentCalories,
    required this.caloriesGoal,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');
    final formattedCalories = numberFormat.format(currentCalories);
    final formattedGoal = numberFormat.format(caloriesGoal);

    final double ratio = caloriesGoal > 0 ? (currentCalories / caloriesGoal).clamp(0.0, 1.0) : 0.0;

    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXXL),
        border: Border.all(color: AppColors.border.withAlpha(160)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.mintBadge,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const Icon(
                Icons.more_horiz_rounded,
                color: AppColors.textMuted,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Calories',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            'Goal: $formattedGoal kcal',
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formattedCalories,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'kcal',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          const Text(
            'Active burn',
            style: TextStyle(
              fontSize: 11.5,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
            child: LinearProgressIndicator(
              value: ratio,
              minHeight: 5,
              color: const Color(0xFFFF914D),
              backgroundColor: const Color(0xFFE5E7EB),
            ),
          ),
        ],
      ),
    );
  }
}

/// Card for Water intake on the Home Dashboard with quick +250ml action.
class WaterActivityCard extends StatelessWidget {
  final int currentWaterMl;
  final int waterGoalMl;
  final VoidCallback onQuickAdd;

  const WaterActivityCard({
    super.key,
    required this.currentWaterMl,
    required this.waterGoalMl,
    required this.onQuickAdd,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');
    final formattedWater = numberFormat.format(currentWaterMl);

    final currentL = (currentWaterMl / 1000).toStringAsFixed(2).replaceAll(RegExp(r'0+$'), '').replaceAll(RegExp(r'\.$'), '');
    final goalL = (waterGoalMl / 1000).toStringAsFixed(1);

    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXXL),
        border: Border.all(color: AppColors.border.withAlpha(160)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: const BoxDecoration(
                  color: AppColors.mintBadge,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.water_drop_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F5F4),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                ),
                child: Text(
                  '$currentL / ${goalL}L',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Water intake',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 2),
          const Text(
            'Hydration tracker',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                formattedWater,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                ),
              ),
              const SizedBox(width: 4),
              const Text(
                'ml',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // + 250 ml Action Button
          SizedBox(
            width: double.infinity,
            height: 36,
            child: ElevatedButton(
              onPressed: onQuickAdd,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.mintBadge,
                foregroundColor: AppColors.primaryDark,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                ),
                padding: EdgeInsets.zero,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.add_rounded, size: 16),
                  SizedBox(width: 4),
                  Text(
                    '250 ml',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
