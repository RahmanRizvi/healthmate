import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/date_range_utils.dart';

/// Interactive period toggle ([Week] | [Month]) and date range badge with navigation arrows.
class PeriodSelectorHeader extends StatelessWidget {
  final DatePeriodType selectedType;
  final String dateBadgeLabel;
  final bool canGoNext;
  final ValueChanged<DatePeriodType> onTypeChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;

  final VoidCallback? onExport;

  const PeriodSelectorHeader({
    super.key,
    required this.selectedType,
    required this.dateBadgeLabel,
    required this.canGoNext,
    required this.onTypeChanged,
    required this.onPrevious,
    required this.onNext,
    this.onExport,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Top Row: "Your progress" + Date Range Badge with arrows
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Heading & Subtitle
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: const [
                  Text(
                    'Your progress',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                      letterSpacing: -0.5,
                    ),
                  ),
                  SizedBox(height: 2),
                  Text(
                    'Small steps. Meaningful progress.',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),

            // Date Badge with Previous / Next Controls
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 4.0, vertical: 3.0),
              decoration: BoxDecoration(
                color: const Color(0xFFF3F4F6),
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                border: Border.all(color: AppColors.border.withAlpha(120)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Previous arrow
                  InkWell(
                    onTap: onPrevious,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                    child: const Padding(
                      padding: EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.chevron_left_rounded,
                        size: 18,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 2),

                  // Calendar icon + date label
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.calendar_today_outlined,
                        size: 13,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        dateBadgeLabel,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: AppColors.primaryDark,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 2),

                  // Next arrow
                  InkWell(
                    onTap: canGoNext ? onNext : null,
                    borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                    child: Padding(
                      padding: const EdgeInsets.all(4.0),
                      child: Icon(
                        Icons.chevron_right_rounded,
                        size: 18,
                        color: canGoNext
                            ? AppColors.primaryDark
                            : AppColors.textMuted.withAlpha(100),
                      ),
                    ),
                  ),

                  if (onExport != null) ...[
                    const SizedBox(width: 2),
                    InkWell(
                      onTap: onExport,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                      child: const Padding(
                        padding: EdgeInsets.all(4.0),
                        child: Icon(
                          Icons.file_download_outlined,
                          size: 16,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Period Toggle Pills: [Day] [Week] [Month]
        Align(
          alignment: Alignment.centerLeft,
          child: Container(
            padding: const EdgeInsets.all(3.0),
            decoration: BoxDecoration(
              color: const Color(0xFFEAEEEC),
              borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                _buildToggleOption(
                  label: 'Day',
                  isSelected: selectedType == DatePeriodType.day,
                  onTap: () => onTypeChanged(DatePeriodType.day),
                ),
                _buildToggleOption(
                  label: 'Week',
                  isSelected: selectedType == DatePeriodType.week,
                  onTap: () => onTypeChanged(DatePeriodType.week),
                ),
                _buildToggleOption(
                  label: 'Month',
                  isSelected: selectedType == DatePeriodType.month,
                  onTap: () => onTypeChanged(DatePeriodType.month),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildToggleOption({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 22.0, vertical: 7.0),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primaryDark : Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
            color: isSelected ? Colors.white : AppColors.textSecondary,
          ),
        ),
      ),
    );
  }
}
