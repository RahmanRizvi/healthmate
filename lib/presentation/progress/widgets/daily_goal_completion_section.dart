import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/date_range_utils.dart';
import '../../../domain/services/analytics_service.dart';

/// Reusable card displaying goal achievement days and progress bars for the 3 daily targets.
class DailyGoalCompletionSection extends StatelessWidget {
  final ProgressAnalyticsData data;

  const DailyGoalCompletionSection({
    super.key,
    required this.data,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');
    final String periodSubtitle;
    if (data.range.periodType == DatePeriodType.day) {
      periodSubtitle = 'Days target achieved today';
    } else if (data.range.periodType == DatePeriodType.week) {
      periodSubtitle = 'Days target achieved this week';
    } else {
      periodSubtitle = 'Days target achieved this month';
    }

    final denominator = data.goalStats.denominatorDays;
    final goals = data.goals;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXXL),
        border: Border.all(color: AppColors.border.withAlpha(140)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Text(
            'Daily goal completion',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
              letterSpacing: -0.3,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            periodSubtitle,
            style: const TextStyle(
              fontSize: 12,
              color: AppColors.textSecondary,
              fontWeight: FontWeight.w400,
            ),
          ),
          const SizedBox(height: 16),

          // 1. Steps Goal
          _buildGoalProgressRow(
            icon: Icons.directions_walk_rounded,
            iconColor: AppColors.primary,
            iconBg: const Color(0xFFD1FAE5),
            label: 'Steps (${numberFormat.format(goals.stepsGoal)} / day)',
            achievedDays: data.goalStats.stepsDaysAchieved,
            denominatorDays: denominator,
            percentage: data.goalStats.stepsPercentage,
            progressColor: AppColors.primaryDark,
          ),
          const SizedBox(height: 12),

          // 2. Water Intake Goal
          _buildGoalProgressRow(
            icon: Icons.water_drop_rounded,
            iconColor: const Color(0xFF0F766E),
            iconBg: const Color(0xFFCCFBF1),
            label: 'Water intake (${numberFormat.format(goals.waterGoalMl)} ml)',
            achievedDays: data.goalStats.waterDaysAchieved,
            denominatorDays: denominator,
            percentage: data.goalStats.waterPercentage,
            progressColor: const Color(0xFF0F766E),
          ),
          const SizedBox(height: 12),

          // 3. Active Calories Goal
          _buildGoalProgressRow(
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFFEA580C),
            iconBg: const Color(0xFFFFEDD5),
            label: 'Active calories (${numberFormat.format(goals.caloriesGoalKcal)} kcal)',
            achievedDays: data.goalStats.caloriesDaysAchieved,
            denominatorDays: denominator,
            percentage: data.goalStats.caloriesPercentage,
            progressColor: AppColors.primaryDark,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalProgressRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String label,
    required int achievedDays,
    required int denominatorDays,
    required int percentage,
    required Color progressColor,
  }) {
    final ratio = (percentage / 100.0).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 12.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Icon + Label
              Expanded(
                child: Row(
                  children: [
                    Container(
                      width: 28,
                      height: 28,
                      decoration: BoxDecoration(
                        color: iconBg,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(icon, color: iconColor, size: 16),
                    ),
                    const SizedBox(width: 10),
                    Flexible(
                      child: Text(
                        label,
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Achievement Pill: e.g. "5 of 6 days (83%)"
              Text(
                '$achievedDays of $denominatorDays days ($percentage%)',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
            child: LinearProgressIndicator(
              value: ratio,
              backgroundColor: const Color(0xFFE5E7EB),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 5,
            ),
          ),
        ],
      ),
    );
  }
}
