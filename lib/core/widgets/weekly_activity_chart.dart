import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';
import '../../domain/services/health_record_service.dart';

/// Reusable 7-day weekly activity bar chart matching Figma screenshots.
class WeeklyActivityChart extends StatelessWidget {
  final WeeklyActivityData data;
  final VoidCallback? onSeeProgress;

  const WeeklyActivityChart({
    super.key,
    required this.data,
    this.onSeeProgress,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');
    final formattedAverage = numberFormat.format(data.averageSteps);

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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Your weekly activity',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Average: $formattedAverage steps / day',
                      style: const TextStyle(
                        fontSize: 12.5,
                        color: AppColors.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              if (onSeeProgress != null)
                InkWell(
                  onTap: onSeeProgress,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 4.0,
                      vertical: 2.0,
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: const [
                        Text(
                          'See progress',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                        SizedBox(width: 4),
                        Icon(
                          Icons.arrow_forward_rounded,
                          size: 15,
                          color: AppColors.primary,
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 18),

          // 7-day Bar Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 16.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F5F4),
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: data.days.map((day) => _buildDayColumn(day)).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDayColumn(WeeklyDayPoint day) {
    const double barHeight = 84.0;
    const double barWidth = 18.0;

    // Minimum visual indicator if day has data
    final double fillRatio = day.steps > 0 ? (day.ratio.clamp(0.15, 1.0)) : 0.0;
    final double filledHeight = barHeight * fillRatio;

    final Color barColor = day.isCurrentDay
        ? AppColors.primaryDark
        : (day.steps > 0 ? const Color(0xFF2E8B75) : Colors.transparent);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // Top indicator dot for current day
        SizedBox(
          height: 10,
          child: day.isCurrentDay
              ? Container(
                  width: 5,
                  height: 5,
                  decoration: const BoxDecoration(
                    color: AppColors.primaryDark,
                    shape: BoxShape.circle,
                  ),
                )
              : null,
        ),
        const SizedBox(height: 4),

        // Capsule Track
        Container(
          width: barWidth,
          height: barHeight,
          decoration: BoxDecoration(
            color: const Color(0xFFE5E7EB).withAlpha(160),
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          ),
          alignment: Alignment.bottomCenter,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 350),
            curve: Curves.easeOutCubic,
            width: barWidth,
            height: filledHeight,
            decoration: BoxDecoration(
              color: barColor,
              borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
            ),
          ),
        ),
        const SizedBox(height: 8),

        // Weekday Label
        Text(
          day.label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: day.isCurrentDay ? FontWeight.w800 : FontWeight.w500,
            color: day.isCurrentDay
                ? AppColors.primaryDark
                : AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}
