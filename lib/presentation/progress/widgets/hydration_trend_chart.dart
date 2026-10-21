import 'dart:math';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/date_range_utils.dart';
import '../../../domain/services/analytics_service.dart';

/// Interactive hydration trend chart reproducing the Figma Hydration Trend spline chart.
class HydrationTrendChart extends StatelessWidget {
  final ProgressAnalyticsData data;
  final int? selectedIndex;
  final ValueChanged<int> onSelectDay;

  const HydrationTrendChart({
    super.key,
    required this.data,
    required this.selectedIndex,
    required this.onSelectDay,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');
    final waterTargetMl = data.goals.waterGoalMl > 0 ? data.goals.waterGoalMl : 2500;

    final points = data.dayPoints;
    final maxWaterRecorded = points.fold<int>(0, (prev, p) => max(prev, p.waterMl));
    final chartMaxWater = max(waterTargetMl, maxWaterRecorded > 0 ? (maxWaterRecorded * 1.15).round() : 2500);

    final isWeek = data.range.periodType == DatePeriodType.week;
    final activeIndex = (selectedIndex != null && selectedIndex! >= 0 && selectedIndex! < points.length)
        ? selectedIndex!
        : points.indexWhere((p) => p.isToday);
    final validActiveIndex = activeIndex != -1 ? activeIndex : (points.isNotEmpty ? points.length - 1 : 0);

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
          // Header: Title + Target Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Hydration trend',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Daily fluid intake in milliliters',
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

              // Target Badge: Target: 2,500 ml
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                ),
                child: Text(
                  'Target: ${numberFormat.format(waterTargetMl)} ml',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Custom Painted Spline Chart
          SizedBox(
            height: 120,
            width: double.infinity,
            child: CustomPaint(
              painter: _HydrationCurvePainter(
                points: points,
                maxWater: chartMaxWater,
                targetWater: waterTargetMl,
                selectedIndex: validActiveIndex,
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Daily Values Row (e.g. "M 2.2L", "T 2.5L", "Sat 1.8L")
          if (data.range.periodType == DatePeriodType.day && points.isNotEmpty)
            Center(
              child: Column(
                children: [
                  Text(
                    points.first.fullWeekday,
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    points.first.hasRecord && points.first.waterMl > 0
                        ? points.first.formattedWaterLitres
                        : '-',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            )
          else if (isWeek)
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(points.length, (idx) {
                final point = points[idx];
                final isSelected = idx == validActiveIndex;
                final dayLabel = isSelected && point.fullWeekday.length >= 3
                    ? point.fullWeekday.substring(0, 3)
                    : point.dayLabel;

                return GestureDetector(
                  onTap: () => onSelectDay(idx),
                  behavior: HitTestBehavior.opaque,
                  child: Column(
                    children: [
                      Text(
                        dayLabel,
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w600,
                          color: isSelected ? AppColors.primaryDark : AppColors.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        point.hasRecord && point.waterMl > 0
                            ? point.formattedWaterLitres
                            : '-',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isSelected ? FontWeight.w800 : FontWeight.w500,
                          color: isSelected ? AppColors.primaryDark : AppColors.textMuted,
                        ),
                      ),
                    ],
                  ),
                );
              }),
            )
          else
            // Monthly summary
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Start: ${points.isNotEmpty ? points.first.formattedWaterLitres : "-"}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
                Text(
                  'Average: ${data.summary.formattedAverageWaterLitres}',
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'End: ${points.isNotEmpty ? points.last.formattedWaterLitres : "-"}',
                  style: const TextStyle(fontSize: 11, color: AppColors.textSecondary),
                ),
              ],
            ),
        ],
      ),
    );
  }
}

/// Painter rendering the smooth cubic Bezier curve, mint gradient fill, data dots, and dashed target line.
class _HydrationCurvePainter extends CustomPainter {
  final List<PeriodDayPoint> points;
  final int maxWater;
  final int targetWater;
  final int selectedIndex;

  _HydrationCurvePainter({
    required this.points,
    required this.maxWater,
    required this.targetWater,
    required this.selectedIndex,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (points.isEmpty) return;

    final targetRatio = (targetWater / maxWater).clamp(0.0, 1.0);
    final targetY = size.height * (1.0 - targetRatio);

    // 1. Draw Dashed Target Line
    final targetPaint = Paint()
      ..color = const Color(0xFF6EE7B7)
      ..strokeWidth = 1.0
      ..style = PaintingStyle.stroke;

    const dashWidth = 4.0;
    const dashSpace = 4.0;
    double startX = 0;
    while (startX < size.width) {
      canvas.drawLine(
        Offset(startX, targetY),
        Offset(startX + dashWidth, targetY),
        targetPaint,
      );
      startX += dashWidth + dashSpace;
    }

    // 2. Handle single point (Day mode)
    if (points.length == 1) {
      final val = points[0].waterMl;
      final ratio = maxWater > 0 ? (val / maxWater).clamp(0.0, 1.0) : 0.0;
      final y = size.height - 10 - (ratio * (size.height - 20));

      final fillPaint = Paint()
        ..shader = const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [
            Color(0x66B7F7DE),
            Color(0x05B7F7DE),
          ],
        ).createShader(Rect.fromLTWH(0, y, size.width, size.height - y));
      canvas.drawRect(Rect.fromLTWH(0, y, size.width, size.height - y), fillPaint);

      final linePaint = Paint()
        ..color = const Color(0xFF047857)
        ..strokeWidth = 2.5
        ..style = PaintingStyle.stroke;
      canvas.drawLine(Offset(0, y), Offset(size.width, y), linePaint);

      final dotPaint = Paint()..color = const Color(0xFF073F38);
      canvas.drawCircle(Offset(size.width / 2, y), 5.5, dotPaint);
      final whiteInner = Paint()..color = Colors.white;
      canvas.drawCircle(Offset(size.width / 2, y), 2.5, whiteInner);
      return;
    }

    // 3. Compute Coordinates of all data points
    final List<Offset> offsets = [];
    final n = points.length;
    final stepX = n > 1 ? size.width / (n - 1) : size.width;

    for (int i = 0; i < n; i++) {
      final x = n > 1 ? i * stepX : size.width / 2;
      final val = points[i].waterMl;
      final ratio = maxWater > 0 ? (val / maxWater).clamp(0.0, 1.0) : 0.0;
      // Leave 10px margin at top and bottom
      final y = size.height - 10 - (ratio * (size.height - 20));
      offsets.add(Offset(x, y));
    }

    // 3. Build Smooth Bezier Path
    final path = Path();
    path.moveTo(offsets[0].dx, offsets[0].dy);

    for (int i = 0; i < offsets.length - 1; i++) {
      final p0 = offsets[i];
      final p1 = offsets[i + 1];
      final controlX = (p0.dx + p1.dx) / 2;
      path.cubicTo(controlX, p0.dy, controlX, p1.dy, p1.dx, p1.dy);
    }

    // 4. Fill Gradient Under Curve
    final fillPath = Path.from(path)
      ..lineTo(offsets.last.dx, size.height)
      ..lineTo(offsets.first.dx, size.height)
      ..close();

    final fillPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          const Color(0xFFD1FAE5).withAlpha(160),
          const Color(0xFFD1FAE5).withAlpha(20),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill;

    canvas.drawPath(fillPath, fillPaint);

    // 5. Stroke Curve Line
    final strokePaint = Paint()
      ..color = const Color(0xFF047857)
      ..strokeWidth = 2.5
      ..style = PaintingStyle.stroke
      ..strokeCap = StrokeCap.round;

    canvas.drawPath(path, strokePaint);

    // 6. Draw Data Dots
    final dotPaint = Paint()..style = PaintingStyle.fill;
    final dotBorderPaint = Paint()
      ..color = Colors.white
      ..strokeWidth = 2.0
      ..style = PaintingStyle.stroke;

    for (int i = 0; i < offsets.length; i++) {
      final isSelected = i == selectedIndex;
      final p = offsets[i];

      if (isSelected) {
        // Outer glow
        dotPaint.color = const Color(0xFF047857).withAlpha(40);
        canvas.drawCircle(p, 9.0, dotPaint);

        // Solid inner dot
        dotPaint.color = const Color(0xFF047857);
        canvas.drawCircle(p, 5.0, dotPaint);
        canvas.drawCircle(p, 5.0, dotBorderPaint);
      } else {
        dotPaint.color = const Color(0xFF047857);
        canvas.drawCircle(p, 3.5, dotPaint);
      }
    }
  }

  @override
  bool shouldRepaint(covariant _HydrationCurvePainter oldDelegate) => true;
}
