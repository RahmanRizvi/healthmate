import 'package:flutter/material.dart';
import '../constants/app_colors.dart';
import '../constants/app_dimensions.dart';

/// Reusable information banner with leading icon and customizable background.
class InfoBanner extends StatelessWidget {
  final String message;
  final IconData icon;
  final Color? backgroundColor;
  final Color? iconColor;
  final Color? textColor;
  final Widget? trailing;

  const InfoBanner({
    super.key,
    required this.message,
    this.icon = Icons.info_outline_rounded,
    this.backgroundColor,
    this.iconColor,
    this.textColor,
    this.trailing,
  });

  /// Factory constructor for the mint age banner with lock icon.
  factory InfoBanner.age({
    Key? key,
    required String ageLabel,
  }) {
    return InfoBanner(
      key: key,
      message: ageLabel,
      icon: Icons.verified_rounded,
      backgroundColor: AppColors.mintBadge,
      iconColor: AppColors.primary,
      textColor: AppColors.primaryDark,
      trailing: const Icon(
        Icons.lock_outline_rounded,
        size: 18,
        color: AppColors.lockIcon,
      ),
    );
  }

  /// Factory constructor for neutral informational notes.
  factory InfoBanner.neutral({
    Key? key,
    required String message,
  }) {
    return InfoBanner(
      key: key,
      message: message,
      icon: Icons.info_outline_rounded,
      backgroundColor: AppColors.infoBannerBackground,
      iconColor: AppColors.primary,
      textColor: AppColors.textSecondary,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
      decoration: BoxDecoration(
        color: backgroundColor ?? AppColors.infoBannerBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            size: 20,
            color: iconColor ?? AppColors.primary,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: textColor ?? AppColors.textPrimary,
                height: 1.35,
              ),
            ),
          ),
          if (trailing != null) ...[
            const SizedBox(width: 8),
            trailing!,
          ],
        ],
      ),
    );
  }
}
