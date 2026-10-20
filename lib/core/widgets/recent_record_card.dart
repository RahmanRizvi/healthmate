import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../utils/date_formatter.dart';
import '../../data/models/health_record.dart';
import '../../domain/services/health_record_service.dart';

/// Reusable card displaying a historical daily health record.
class RecentRecordCard extends StatelessWidget {
  final HealthRecord record;
  final RecordGoalStatus status;
  final VoidCallback? onTap;

  const RecentRecordCard({
    super.key,
    required this.record,
    required this.status,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');
    final formattedDate = DateFormatter.formatRecentRecordDate(record.dateTime);

    final isGoalMet = status == RecordGoalStatus.goalMet;
    final dotColor = isGoalMet ? AppColors.statusSuccess : const Color(0xFFD97706);
    final badgeBg = isGoalMet ? const Color(0xFFD1FAE5) : const Color(0xFFFEF3C7);
    final badgeTextColor = isGoalMet ? AppColors.statusSuccess : const Color(0xFFD97706);

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12.0),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: AppColors.border.withAlpha(160)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Top Row: Dot + Date & Status Badge
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            color: dotColor,
                            shape: BoxShape.circle,
                          ),
                        ),
                        const SizedBox(width: 8),
                        Text(
                          formattedDate,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ],
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: badgeBg,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                      ),
                      child: Text(
                        status.label,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w700,
                          color: badgeTextColor,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),

                // 3 Metric Chips Row
                Row(
                  children: [
                    Expanded(
                      child: _buildMetricChip(
                        icon: Icons.directions_walk_rounded,
                        value: numberFormat.format(record.steps),
                        unit: 'steps',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricChip(
                        icon: Icons.water_drop_rounded,
                        value: numberFormat.format(record.water),
                        unit: 'ml',
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildMetricChip(
                        icon: Icons.local_fire_department_rounded,
                        value: numberFormat.format(record.calories),
                        unit: 'kcal',
                      ),
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

  Widget _buildMetricChip({
    required IconData icon,
    required String value,
    required String unit,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 8.0),
      decoration: BoxDecoration(
        color: const Color(0xFFF3F5F4),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              color: AppColors.mintBadge,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              size: 15,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 6),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
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
