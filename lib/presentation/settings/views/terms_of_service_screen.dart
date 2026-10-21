import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/healthmate_header.dart';

/// Screen displaying the Terms of Service for personal wellness tracking with HealthMate.
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HealthMateHeader.detail(
        title: 'Terms of Service',
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle(context, '1. Personal Wellness Scope'),
              _buildContentCard(
                context,
                child: Text(
                  'HealthMate is designed solely as a self-directed personal wellness and lifestyle tracking tool. It offers habit tracking, hydration markers, daily step monitoring, and approximate caloric expenditure metrics for individual informational review.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: theme.colorScheme.onSurface,
                    height: 1.45,
                  ),
                ),
              ),
              const SizedBox(height: 20),

              _buildSectionTitle(context, '2. Medical Advice Disclaimer'),
              _buildContentCard(
                context,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'HealthMate does not provide clinical diagnosis, medical treatment, or healthcare services. Calculations such as Body Mass Index (BMI), activity progress, and hydration estimations are screening indicators and mathematical estimations only.',
                      style: TextStyle(
                        fontSize: 13.5,
                        color: theme.colorScheme.onSurface,
                        height: 1.45,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Always seek the advice of your physician or qualified medical provider with any questions you may have regarding a medical condition, diet regimen, or fitness regimen.',
                      style: TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.mint : AppColors.primaryDark,
                        height: 1.45,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              _buildSectionTitle(context, '3. User Data Responsibility'),
              _buildContentCard(
                context,
                child: Text(
                  'All profile metrics (height, weight, date of birth) and daily entries (steps, water, calories) are entered manually by the user. You are responsible for ensuring the accuracy of your entries. Because data is stored locally in device storage, backing up device content remains under the user’s control.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: theme.colorScheme.onSurface,
                    height: 1.45,
                  ),
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
}
