import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../utils/date_formatter.dart';
import '../../data/models/daily_goals.dart';
import '../../data/models/health_record.dart';

/// Reusable card displaying daily health history in the records list matching Figma Screenshot 2.
class RecordHistoryCard extends StatelessWidget {
  final HealthRecord record;
  final DailyGoals goals;
  final VoidCallback onTap;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  const RecordHistoryCard({
    super.key,
    required this.record,
    required this.goals,
    required this.onTap,
    required this.onEdit,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');
    final recordDate = record.dateTime;
    final isToday = DateFormatter.isSameDay(recordDate, DateTime.now());

    // Goals check
    final metSteps = goals.stepsGoal > 0 && record.steps >= goals.stepsGoal;
    final metCalories = goals.caloriesGoalKcal > 0 && record.calories >= goals.caloriesGoalKcal;
    final metWater = goals.waterGoalMl > 0 && record.water >= goals.waterGoalMl;
    final isAllGoalsCompleted = metSteps && metCalories && metWater;

    // Overall progress calculation
    final stepsRatio = goals.stepsGoal > 0
        ? (record.steps / goals.stepsGoal).clamp(0.0, 1.0)
        : 0.0;
    final calRatio = goals.caloriesGoalKcal > 0
        ? (record.calories / goals.caloriesGoalKcal).clamp(0.0, 1.0)
        : 0.0;
    final waterRatio = goals.waterGoalMl > 0
        ? (record.water / goals.waterGoalMl).clamp(0.0, 1.0)
        : 0.0;
    final progressPercent = (((stepsRatio + calRatio + waterRatio) / 3.0) * 100).round();

    return Container(
      margin: const EdgeInsets.only(bottom: 14.0),
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
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXXL),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AppDimensions.radiusXXL),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Calendar Icon, Date & Weekday, Badges, Overflow Menu
                Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    // Calendar Icon Box
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isAllGoalsCompleted
                            ? const Color(0xFFD1FAE5)
                            : const Color(0xFFF1F5F3),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        Icons.calendar_month_rounded,
                        color: isAllGoalsCompleted
                            ? AppColors.primary
                            : AppColors.primaryDark,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),

                    // Date & Weekday
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            crossAxisAlignment: WrapCrossAlignment.center,
                            spacing: 8,
                            runSpacing: 4,
                            children: [
                              Text(
                                DateFormatter.formatFullDate(recordDate),
                                style: const TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              if (isToday) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFCCFBEF),
                                    borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                                  ),
                                  child: const Text(
                                    'Today',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w700,
                                      color: AppColors.primary,
                                    ),
                                  ),
                                ),
                              ],
                              if (isAllGoalsCompleted && !isToday) ...[
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                    vertical: 2,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFD1FAE5),
                                    borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                                  ),
                                  child: const Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Icon(
                                        Icons.check_rounded,
                                        size: 13,
                                        color: AppColors.primary,
                                      ),
                                      SizedBox(width: 3),
                                      Text(
                                        'Goal reached',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w700,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            DateFormatter.formatWeekday(recordDate),
                            style: const TextStyle(
                              fontSize: 12.5,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // Overflow 3-dots Menu
                    PopupMenuButton<String>(
                      icon: const Icon(
                        Icons.more_vert_rounded,
                        color: AppColors.textSecondary,
                        size: 20,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                      ),
                      onSelected: (value) {
                        if (value == 'edit') {
                          onEdit();
                        } else if (value == 'delete') {
                          onDelete();
                        }
                      },
                      itemBuilder: (context) => [
                        const PopupMenuItem(
                          value: 'edit',
                          child: Row(
                            children: [
                              Icon(
                                Icons.edit_outlined,
                                size: 18,
                                color: AppColors.primaryDark,
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Edit',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Row(
                            children: [
                              Icon(
                                Icons.delete_outline_rounded,
                                size: 18,
                                color: Color(0xFFDC2626),
                              ),
                              SizedBox(width: 10),
                              Text(
                                'Delete',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: Color(0xFFDC2626),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Middle Row: 3 Metrics Pill Containers
                Row(
                  children: [
                    // Steps
                    Expanded(
                      child: _buildMetricPill(
                        icon: Icons.directions_run_rounded,
                        iconColor: AppColors.primary,
                        value: numberFormat.format(record.steps),
                        unit: 'steps',
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Calories
                    Expanded(
                      child: _buildMetricPill(
                        icon: Icons.local_fire_department_rounded,
                        iconColor: const Color(0xFFEA580C),
                        value: numberFormat.format(record.calories),
                        unit: 'kcal',
                      ),
                    ),
                    const SizedBox(width: 8),

                    // Water
                    Expanded(
                      child: _buildMetricPill(
                        icon: Icons.water_drop_rounded,
                        iconColor: const Color(0xFF0F766E),
                        value: numberFormat.format(record.water),
                        unit: 'ml',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // Bottom Row: Progress / Goals Completed & View details link
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Left indicator
                    if (isAllGoalsCompleted) ...[
                      const Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.check_circle_outline_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            SizedBox(width: 6),
                            Flexible(
                              child: Text(
                                'All 3 goals completed',
                                style: TextStyle(
                                  fontSize: 12.5,
                                  fontWeight: FontWeight.w700,
                                  color: AppColors.primary,
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ] else ...[
                      Expanded(
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Expanded(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(4),
                                child: LinearProgressIndicator(
                                  value: (progressPercent / 100.0).clamp(0.0, 1.0),
                                  backgroundColor: const Color(0xFFE2E8F0),
                                  valueColor: const AlwaysStoppedAnimation<Color>(
                                    AppColors.primaryDark,
                                  ),
                                  minHeight: 6,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              '$progressPercent%',
                              style: const TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(width: 8),

                    // Right: View Details Action
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'View details',
                          style: TextStyle(
                            fontSize: 12.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 18,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMetricPill({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F4),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: iconColor, size: 15),
          const SizedBox(width: 5),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
                Text(
                  unit,
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
