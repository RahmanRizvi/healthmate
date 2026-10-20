import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// Reusable goal adjustment card with increment/decrement steppers matching Figma Screen 4.
class GoalStepperCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final bool isSubtitleHighlighted;
  final int value;
  final String unit;
  final int step;
  final int minValue;
  final VoidCallback onIncrement;
  final VoidCallback onDecrement;
  final String? footerNote;

  const GoalStepperCard({
    super.key,
    required this.icon,
    required this.title,
    required this.subtitle,
    this.isSubtitleHighlighted = false,
    required this.value,
    required this.unit,
    required this.step,
    required this.minValue,
    required this.onIncrement,
    required this.onDecrement,
    this.footerNote,
  });

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');
    final formattedValue = numberFormat.format(value);
    final isAtMin = value <= minValue;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: AppColors.border.withAlpha(160)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(8),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row with Icon and Titles
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.mintBadge,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: AppColors.primary,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        fontWeight: isSubtitleHighlighted
                            ? FontWeight.w600
                            : FontWeight.w400,
                        color: isSubtitleHighlighted
                            ? AppColors.primary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Stepper Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: AppColors.stepperBackground,
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // Minus Button
                _StepperActionButton(
                  icon: Icons.remove_rounded,
                  onPressed: isAtMin ? null : onDecrement,
                  isEnabled: !isAtMin,
                ),

                // Center Value & Unit
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.baseline,
                      textBaseline: TextBaseline.alphabetic,
                      children: [
                        Text(
                          formattedValue,
                          style: const TextStyle(
                            fontSize: 26,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                            letterSpacing: -0.5,
                          ),
                        ),
                        if (unit == 'ml' || unit == 'kcal') ...[
                          const SizedBox(width: 4),
                          Text(
                            unit,
                            style: const TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: AppColors.textPrimary,
                            ),
                          ),
                        ],
                      ],
                    ),
                    if (unit == 'steps')
                      Text(
                        unit,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                  ],
                ),

                // Plus Button
                _StepperActionButton(
                  icon: Icons.add_rounded,
                  onPressed: onIncrement,
                  isEnabled: true,
                ),
              ],
            ),
          ),

          // Optional Footer Note
          if (footerNote != null) ...[
            const SizedBox(height: 14),
            Text(
              footerNote!,
              style: const TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _StepperActionButton extends StatelessWidget {
  final IconData icon;
  final VoidCallback? onPressed;
  final bool isEnabled;

  const _StepperActionButton({
    required this.icon,
    required this.onPressed,
    required this.isEnabled,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: isEnabled ? Colors.white : Colors.white.withAlpha(160),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        boxShadow: isEnabled
            ? [
                BoxShadow(
                  color: Colors.black.withAlpha(12),
                  blurRadius: 4,
                  offset: const Offset(0, 1),
                ),
              ]
            : null,
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          onTap: onPressed,
          child: Center(
            child: Icon(
              icon,
              size: 22,
              color: isEnabled ? AppColors.primaryDark : AppColors.textMuted,
            ),
          ),
        ),
      ),
    );
  }
}
