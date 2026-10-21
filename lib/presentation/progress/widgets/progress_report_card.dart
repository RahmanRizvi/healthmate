import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/date_range_utils.dart';
import '../../../domain/services/analytics_service.dart';
import '../../../domain/services/insights_service.dart';

/// A shareable, printable health report snapshot card featuring the HealthMate app logo and period analytics.
class ProgressReportCard extends StatelessWidget {
  final ProgressAnalyticsData data;
  final ProgressInsight? insight;

  const ProgressReportCard({
    super.key,
    required this.data,
    this.insight,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');
    final range = data.range;

    String periodTitle;
    if (range.periodType == DatePeriodType.day) {
      periodTitle = 'Daily Health Report';
    } else if (range.periodType == DatePeriodType.week) {
      periodTitle = 'Weekly Progress Report';
    } else {
      periodTitle = 'Monthly Progress Report';
    }

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 360),
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.primary.withAlpha(50), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 1. Header with HealthMate App Logo & Period Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Row(
                  children: [
                    ClipRRect(
                      borderRadius: BorderRadius.circular(8),
                      child: Image.asset(
                        'assets/images/logo.png',
                        width: 34,
                        height: 34,
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => Container(
                          width: 34,
                          height: 34,
                          color: AppColors.primary,
                          child: const Icon(Icons.favorite_rounded, color: Colors.white, size: 20),
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: const [
                          Text(
                            'HealthMate',
                            style: TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                              letterSpacing: -0.4,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                          Text(
                            'Personal Health & Wellness',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w500,
                              color: AppColors.textSecondary,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.mint.withAlpha(140),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                  border: Border.all(color: AppColors.primary.withAlpha(80)),
                ),
                child: Text(
                  range.periodType.label.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primaryDark,
                    letterSpacing: 0.8,
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 14),

          // 2. Report Title & Date Range
          Text(
            periodTitle,
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          const SizedBox(height: 2),
          Row(
            children: [
              const Icon(Icons.calendar_today_outlined, size: 12, color: AppColors.primary),
              const SizedBox(width: 4),
              Text(
                range.displayLabel,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 3. Three Key Summary Metrics
          Row(
            children: [
              Expanded(
                child: _buildMetricPill(
                  icon: Icons.directions_walk_rounded,
                  iconColor: AppColors.primary,
                  iconBg: const Color(0xFFD1FAE5),
                  value: range.periodType == DatePeriodType.day && data.dayPoints.isNotEmpty
                      ? numberFormat.format(data.dayPoints.first.steps)
                      : numberFormat.format(data.summary.averageSteps),
                  unit: range.periodType == DatePeriodType.day ? 'steps' : 'avg steps/d',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricPill(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: const Color(0xFFEA580C),
                  iconBg: const Color(0xFFFFEDD5),
                  value: range.periodType == DatePeriodType.day && data.dayPoints.isNotEmpty
                      ? '${data.dayPoints.first.calories}'
                      : '${data.summary.averageCalories}',
                  unit: range.periodType == DatePeriodType.day ? 'kcal' : 'avg kcal/d',
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _buildMetricPill(
                  icon: Icons.water_drop_rounded,
                  iconColor: const Color(0xFF0F766E),
                  iconBg: const Color(0xFFCCFBF1),
                  value: range.periodType == DatePeriodType.day && data.dayPoints.isNotEmpty
                      ? data.dayPoints.first.formattedWaterLitres
                      : data.summary.formattedAverageWaterLitres,
                  unit: range.periodType == DatePeriodType.day ? 'water' : 'avg water/d',
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          // 4. Daily Goal Completion Progress
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFF9FAFB),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: const Color(0xFFE5E7EB)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Daily Goal Completion',
                  style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 10),
                _buildGoalBar(
                  label: 'Steps (${numberFormat.format(data.goals.stepsGoal)})',
                  percentage: data.goalStats.stepsPercentage,
                  achieved: data.goalStats.stepsDaysAchieved,
                  total: data.goalStats.denominatorDays,
                  color: AppColors.primary,
                ),
                const SizedBox(height: 8),
                _buildGoalBar(
                  label: 'Water (${numberFormat.format(data.goals.waterGoalMl)} ml)',
                  percentage: data.goalStats.waterPercentage,
                  achieved: data.goalStats.waterDaysAchieved,
                  total: data.goalStats.denominatorDays,
                  color: const Color(0xFF0F766E),
                ),
                const SizedBox(height: 8),
                _buildGoalBar(
                  label: 'Active Calories (${data.goals.caloriesGoalKcal} kcal)',
                  percentage: data.goalStats.caloriesPercentage,
                  achieved: data.goalStats.caloriesDaysAchieved,
                  total: data.goalStats.denominatorDays,
                  color: const Color(0xFFEA580C),
                ),
              ],
            ),
          ),

          // 5. Insight Banner if available
          if (insight != null) ...[
            const SizedBox(height: 14),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFE6F9F2), Color(0xFFD3F5E7)],
                ),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: AppColors.mint),
              ),
              child: Row(
                children: [
                  const Icon(Icons.auto_awesome_rounded, color: AppColors.primary, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      insight!.message,
                      style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.primaryDark,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),
          const Divider(height: 1, color: Color(0xFFE5E7EB)),
          const SizedBox(height: 10),

          // 6. Footer branding
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  'Tracked with HealthMate App',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textMuted.withAlpha(200),
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                DateFormat('yyyy-MM-dd HH:mm').format(DateTime.now()),
                style: TextStyle(
                  fontSize: 9.5,
                  color: AppColors.textMuted.withAlpha(180),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricPill({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFF9FAFB),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: const Color(0xFFE5E7EB)),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(color: iconBg, shape: BoxShape.circle),
            child: Icon(icon, color: iconColor, size: 14),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 9.5,
              fontWeight: FontWeight.w500,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGoalBar({
    required String label,
    required int percentage,
    required int achieved,
    required int total,
    required Color color,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                label,
                style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textPrimary),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 8),
            Text(
              '$achieved of $total ($percentage%)',
              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: color),
            ),
          ],
        ),
        const SizedBox(height: 4),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (percentage / 100.0).clamp(0.0, 1.0),
            backgroundColor: const Color(0xFFE5E7EB),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 4,
          ),
        ),
      ],
    );
  }
}
