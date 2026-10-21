import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/healthmate_header.dart';

/// Screen detailing exact data-handling practices, local SQLite storage, and device security.
class PrivacySecurityScreen extends StatelessWidget {
  const PrivacySecurityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HealthMateHeader.detail(
        title: 'Privacy & Data Security',
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Security Banner
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.infoBannerBackgroundDark : AppColors.infoBannerBackground,
                  borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                  border: Border.all(
                    color: isDark ? AppColors.borderDark : AppColors.border.withAlpha(160),
                  ),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: const BoxDecoration(
                        color: AppColors.statusSuccessBg,
                        shape: BoxShape.circle,
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.lock_rounded,
                          color: AppColors.statusSuccess,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Local Device Storage',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w700,
                              color: isDark ? AppColors.mint : AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Your health data is stored directly on your physical device. HealthMate never transmits or sells personal metrics.',
                            style: TextStyle(
                              fontSize: 13,
                              color: theme.colorScheme.onSurfaceVariant,
                              height: 1.4,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _buildSectionTitle(context, '1. Information Stored Locally'),
              _buildContentCard(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HealthMate maintains the following user-provided entries inside your device’s local SQLite database:',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: theme.colorScheme.onSurface,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildBullet('Profile: Full name, date of birth, gender, height, and weight.', context),
                    _buildBullet('Daily targets: Step target, water volume target, and calorie burn target.', context),
                    _buildBullet('Daily records: Steps taken, water consumed, active calories burned, and log timestamps.', context),
                    _buildBullet('Preferences: Selected theme mode, reminder alerts, and measurement unit system.', context),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _buildSectionTitle(context, '2. External Services & Cloud Telemetry'),
              _buildContentCard(
                context,
                child: Text(
                  'HealthMate operates without external application servers or third-party cloud data warehouses. No personal measurements or activity logs are uploaded to any remote host. There are no tracking scripts, advertising trackers, or external behavioral analytics integrated into the core tracking engine.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: theme.colorScheme.onSurface,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _buildSectionTitle(context, '3. Device Security Recommendations'),
              _buildContentCard(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Because your records are retained locally in application storage on your smartphone, data security depends primarily on physical device protection:',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: theme.colorScheme.onSurface,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 10),
                    _buildBullet('Enable a secure device passcode, PIN, or biometric lock (Face ID / Fingerprint).', context),
                    _buildBullet('Keep your mobile operating system updated with the latest security patches.', context),
                    _buildBullet('Avoid providing untrusted individuals unrestricted access to your unlocked device.', context),
                  ],
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(BuildContext context, String title) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: isDark ? AppColors.mint : AppColors.primaryDark,
        ),
      ),
    );
  }

  Widget _buildContentCard(BuildContext context, {required Widget child}) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border.withAlpha(160),
        ),
      ),
      child: child,
    );
  }

  Widget _buildBullet(String text, BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            margin: const EdgeInsets.only(top: 6, right: 10),
            width: 6,
            height: 6,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          Expanded(
            child: Text(
              text,
              style: TextStyle(
                fontSize: 13,
                color: theme.colorScheme.onSurface,
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
