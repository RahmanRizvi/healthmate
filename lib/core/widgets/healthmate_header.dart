import 'package:flutter/material.dart';
import '../constants/app_colors.dart';

/// Reusable navigation header with support for Onboarding, Dashboard, and Form detail screens.
class HealthMateHeader extends StatelessWidget implements PreferredSizeWidget {
  final VoidCallback? onBackPressed;
  final bool showBackButton;
  final bool isDashboard;
  final VoidCallback? onAddPressed;
  final String? title;
  final Widget? trailing;

  const HealthMateHeader({
    super.key,
    this.onBackPressed,
    this.showBackButton = true,
    this.isDashboard = false,
    this.onAddPressed,
    this.title,
    this.trailing,
  });

  /// Factory constructor for the Home Dashboard header.
  factory HealthMateHeader.dashboard({
    Key? key,
    required VoidCallback onAddPressed,
  }) {
    return HealthMateHeader(
      key: key,
      isDashboard: true,
      showBackButton: false,
      onAddPressed: onAddPressed,
    );
  }

  /// Factory constructor for internal screens like Add Record.
  factory HealthMateHeader.detail({
    Key? key,
    required String title,
    VoidCallback? onBackPressed,
    VoidCallback? onAddPressed,
    Widget? trailing,
  }) {
    return HealthMateHeader(
      key: key,
      isDashboard: false,
      showBackButton: true,
      title: title,
      onBackPressed: onBackPressed,
      onAddPressed: onAddPressed,
      trailing: trailing,
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(64.0);

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      bottom: false,
      child: Container(
        height: preferredSize.height,
        padding: const EdgeInsets.symmetric(horizontal: 20.0),
        child: isDashboard
            ? _buildDashboardHeader(context)
            : (title != null
                ? _buildDetailHeader(context)
                : _buildOnboardingHeader(context)),
      ),
    );
  }

  /// Dashboard Header: Logo + Title on left, circular '+' button on right.
  Widget _buildDashboardHeader(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/logo.png',
                height: 28,
                width: 28,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'HealthMate',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),

        // Right-aligned Circular '+' Action Button
        _buildCircularButton(
          key: const Key('dashboard_add_record_button'),
          icon: Icons.add_rounded,
          onTap: onAddPressed,
          iconSize: 24,
        ),
      ],
    );
  }

  /// Detail Header: Left circular back button, Title, optional Right trailing widget.
  Widget _buildDetailHeader(BuildContext context) {
    return Row(
      children: [
        if (showBackButton)
          _buildCircularButton(
            icon: Icons.arrow_back,
            onTap: onBackPressed ?? () => Navigator.maybePop(context),
            iconSize: 20,
          ),
        const SizedBox(width: 14),
        Expanded(
          child: Text(
            title!,
            style: const TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w700,
              color: AppColors.primaryDark,
              letterSpacing: -0.3,
            ),
          ),
        ),
        if (trailing != null)
          trailing!
        else if (onAddPressed != null)
          _buildCircularButton(
            icon: Icons.add_rounded,
            onTap: onAddPressed,
            iconSize: 22,
          ),
      ],
    );
  }

  /// Onboarding Header: Center Logo + Title, Left circular back button.
  Widget _buildOnboardingHeader(BuildContext context) {
    return Stack(
      alignment: Alignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: Image.asset(
                'assets/images/logo.png',
                height: 28,
                width: 28,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.favorite_rounded,
                  color: AppColors.primary,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'HealthMate',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: AppColors.primaryDark,
                letterSpacing: -0.3,
              ),
            ),
          ],
        ),
        if (showBackButton)
          Align(
            alignment: Alignment.centerLeft,
            child: _buildCircularButton(
              icon: Icons.arrow_back,
              onTap: onBackPressed ?? () => Navigator.maybePop(context),
              iconSize: 20,
            ),
          ),
      ],
    );
  }

  Widget _buildCircularButton({
    Key? key,
    required IconData icon,
    required VoidCallback? onTap,
    required double iconSize,
  }) {
    return Container(
      key: key,
      width: 42,
      height: 42,
      decoration: BoxDecoration(
        color: Colors.white,
        shape: BoxShape.circle,
        border: Border.all(color: AppColors.border.withAlpha(180)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(10),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onTap,
          child: Center(
            child: Icon(
              icon,
              color: AppColors.textPrimary,
              size: iconSize,
            ),
          ),
        ),
      ),
    );
  }
}
