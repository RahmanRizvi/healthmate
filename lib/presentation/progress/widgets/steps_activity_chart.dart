import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/date_range_utils.dart';
import '../../../domain/services/analytics_service.dart';

/// Interactive steps activity chart reproducing the Figma Steps Activity card.
class StepsActivityChart extends StatelessWidget {
  final ProgressAnalyticsData data;
  final int? selectedIndex;
  final ValueChanged<int> onSelectDay;

  const StepsActivityChart({
    super.key,
    required this.data,
    required this.selectedIndex,
    required this.onSelectDay,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');
    final goalSteps = data.goals.stepsGoal > 0 ? data.goals.stepsGoal : 10000;
    final goalK = (goalSteps / 1000.0).round();

    // Determine max value for vertical scaling
    final maxRecorded = data.dayPoints.fold<int>(0, (prev, p) => max(prev, p.steps));
    final chartMaxSteps = max(goalSteps, maxRecorded > 0 ? (maxRecorded * 1.15).round() : 10000);

    final isWeek = data.range.periodType == DatePeriodType.week;
    final points = data.dayPoints;

    final activeIndex = (selectedIndex != null && selectedIndex! >= 0 && selectedIndex! < points.length)
        ? selectedIndex!
        : points.indexWhere((p) => p.isToday);
    final validActiveIndex = activeIndex != -1 ? activeIndex : (points.isNotEmpty ? points.length - 1 : 0);

    final selectedPoint = points.isNotEmpty ? points[validActiveIndex] : null;

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
          // Header Row: Title & Subtitle + Goal Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text.rich(
                      TextSpan(
                        text: 'Steps activity ',
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w800,
                          color: AppColors.primaryDark,
                          letterSpacing: -0.3,
                        ),
                        children: const [
                          TextSpan(
                            text: '•',
                            style: TextStyle(
                              color: AppColors.primary,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    const Text(
                      'Daily walking distribution',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Goal Badge: [flag icon] Goal 10k
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.flag_outlined,
                      size: 13,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      'Goal ${goalK}k',
                      style: const TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 22),

          // Main Interactive Chart Area
          _buildChartArea(
            context: context,
            points: points,
            chartMaxSteps: chartMaxSteps,
            goalSteps: goalSteps,
            validActiveIndex: validActiveIndex,
            selectedPoint: selectedPoint,
            numberFormat: numberFormat,
            isWeek: isWeek,
          ),
          const SizedBox(height: 16),

          const Divider(height: 1, color: Color(0xFFF1F5F3)),
          const SizedBox(height: 12),

          // Footer: Percentage vs last period & Best day
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              // Trend indicator
              Expanded(
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      data.comparison.isPositive
                          ? Icons.trending_up_rounded
                          : Icons.trending_down_rounded,
                      size: 17,
                      color: data.comparison.hasComparison
                          ? (data.comparison.isPositive
                              ? AppColors.primary
                              : const Color(0xFFDC2626))
                          : AppColors.textMuted,
                    ),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        data.comparison.formattedComparisonText,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: data.comparison.hasComparison
                              ? (data.comparison.isPositive
                                  ? AppColors.primary
                                  : const Color(0xFFDC2626))
                              : AppColors.textSecondary,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Best recorded day
              Text(
                'Best: ${data.bestLowest.formattedBestStepsLabel}',
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildChartArea({
    required BuildContext context,
    required List<PeriodDayPoint> points,
    required int chartMaxSteps,
    required int goalSteps,
    required int validActiveIndex,
    required PeriodDayPoint? selectedPoint,
    required NumberFormat numberFormat,
    required bool isWeek,
  }) {
    const double chartHeight = 150.0;
    final goalRatio = (goalSteps / chartMaxSteps).clamp(0.0, 1.0);
    final goalTopY = chartHeight * (1.0 - goalRatio);

    return Column(
      children: [
        // Tooltip above the active bar
        SizedBox(
          height: 30,
          child: selectedPoint != null
              ? Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: const Color(0xFF1E293B),
                      borderRadius: BorderRadius.circular(6),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withAlpha(20),
                          blurRadius: 4,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Text(
                      selectedPoint.isToday
                          ? '${numberFormat.format(selectedPoint.steps)} today'
                          : '${numberFormat.format(selectedPoint.steps)} ${DateFormat('E').format(selectedPoint.date)}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
        ),
        const SizedBox(height: 6),

        // Bars with Dashed Goal Line Stack
        SizedBox(
          height: chartHeight,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              // Dashed Horizontal Goal Line
              Positioned(
                top: goalTopY,
                left: 0,
                right: 0,
                child: CustomPaint(
                  size: const Size(double.infinity, 1),
                  painter: _DashedLinePainter(color: const Color(0xFFCBD5E1)),
                ),
              ),

              // Bars Row
              if (data.range.periodType == DatePeriodType.day)
                Center(
                  child: _buildSingleBar(
                    point: points.first,
                    chartHeight: chartHeight,
                    chartMaxSteps: chartMaxSteps,
                    isSelected: true,
                    onTap: () => onSelectDay(0),
                    barWidth: 36,
                  ),
                )
              else if (isWeek)
                Row(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: List.generate(points.length, (idx) {
                    final point = points[idx];
                    final isSelected = idx == validActiveIndex;
                    return _buildSingleBar(
                      point: point,
                      chartHeight: chartHeight,
                      chartMaxSteps: chartMaxSteps,
                      isSelected: isSelected,
                      onTap: () => onSelectDay(idx),
                      barWidth: 20,
                    );
                  }),
                )
              else
                // Monthly responsive/scrollable bars
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  physics: const BouncingScrollPhysics(),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: List.generate(points.length, (idx) {
                      final point = points[idx];
                      final isSelected = idx == validActiveIndex;
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 3.0),
                        child: _buildSingleBar(
                          point: point,
                          chartHeight: chartHeight,
                          chartMaxSteps: chartMaxSteps,
                          isSelected: isSelected,
                          onTap: () => onSelectDay(idx),
                          barWidth: 10,
                        ),
                      );
                    }),
                  ),
                ),
            ],
          ),
        ),
        const SizedBox(height: 10),

        // X-Axis Labels Row
        if (data.range.periodType == DatePeriodType.day && points.isNotEmpty)
          Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.primaryDark,
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
              ),
              child: Text(
                points.first.fullWeekday,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          )
        else if (isWeek)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: List.generate(points.length, (idx) {
              final point = points[idx];
              final isSelected = idx == validActiveIndex;
              return GestureDetector(
                onTap: () => onSelectDay(idx),
                child: Container(
                  width: 24,
                  height: 24,
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: isSelected ? AppColors.primaryDark : Colors.transparent,
                    shape: BoxShape.circle,
                  ),
                  child: Text(
                    point.dayLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                      color: isSelected ? Colors.white : AppColors.textSecondary,
                    ),
                  ),
                ),
              );
            }),
          )
        else
          // Monthly labels: sample key days (1, 5, 10, 15, 20, 25, 30)
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Day 1',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              Text(
                'Day ${(points.length / 2).round()}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
              Text(
                'Day ${points.length}',
                style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
              ),
            ],
          ),
      ],
    );
  }

  Widget _buildSingleBar({
    required PeriodDayPoint point,
    required double chartHeight,
    required int chartMaxSteps,
    required bool isSelected,
    required VoidCallback onTap,
    required double barWidth,
  }) {
    final ratio = (point.steps / chartMaxSteps).clamp(0.0, 1.0);
    final barHeight = max(8.0, chartHeight * ratio);

    return GestureDetector(
      onTap: onTap,
      behavior: HitTestBehavior.opaque,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          if (point.hasRecord && point.steps > 0)
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: barWidth,
              height: barHeight,
              decoration: BoxDecoration(
                color: isSelected ? AppColors.primaryDark : const Color(0xFFA7F3D0),
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
              ),
            )
          else
            // Empty / unrecorded day: dashed or faint container (matching Sunday in Figma)
            Container(
              width: barWidth,
              height: 28,
              decoration: BoxDecoration(
                color: const Color(0xFFF1F5F3),
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                border: Border.all(
                  color: const Color(0xFFCBD5E1),
                  style: BorderStyle.solid,
                  width: 1.0,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Custom painter for the dashed horizontal reference line.
class _DashedLinePainter extends CustomPainter {
  final Color color;

  _DashedLinePainter({required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = 0;

    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, 0),
        Offset(startX + dashWidth, 0),
        paint,
      );
      startX += dashWidth + dashSpace;
    }
  }

  @override
  bool shouldRepaint(covariant _DashedLinePainter oldDelegate) =>
      color != oldDelegate.color;
}
