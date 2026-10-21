import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../../core/utils/date_range_utils.dart';
import '../../../core/utils/unit_converter.dart';
import '../../../core/widgets/healthmate_header.dart';
import '../../../data/models/daily_goals.dart';
import '../../../domain/services/analytics_service.dart';
import '../../../domain/services/onboarding_service.dart';

/// Screen displaying an on-demand summary of the past week's real SQLite health records.
class WeeklyDigestScreen extends StatefulWidget {
  final MeasurementUnitSystem unitSystem;

  const WeeklyDigestScreen({
    super.key,
    required this.unitSystem,
  });

  @override
  State<WeeklyDigestScreen> createState() => _WeeklyDigestScreenState();
}

class _WeeklyDigestScreenState extends State<WeeklyDigestScreen> {
  bool _isLoading = true;
  ProgressAnalyticsData? _analyticsData;

  @override
  void initState() {
    super.initState();
    _loadDigestData();
  }

  Future<void> _loadDigestData() async {
    final onboardingService = context.read<OnboardingService>();
    final analyticsService = context.read<AnalyticsService>();

    final goals = await onboardingService.getGoals() ?? DailyGoals.defaults();
    final weekRange = DateRangeUtils.getWeekRange(DateTime.now());

    final data = await analyticsService.getAnalyticsForPeriod(weekRange, goals);

    if (mounted) {
      setState(() {
        _analyticsData = data;
        _isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final numberFormat = NumberFormat('#,###');

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      appBar: HealthMateHeader.detail(
        title: 'Weekly Health Digest',
        onBackPressed: () => Navigator.of(context).pop(),
      ),
      body: SafeArea(
        child: _isLoading
            ? const Center(
                child: CircularProgressIndicator(color: AppColors.primary),
              )
            : SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header card with date range
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20.0),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.border.withAlpha(160),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                width: 44,
                                height: 44,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.pillBackgroundDark
                                      : AppColors.mintBadge,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(
                                  Icons.insights_rounded,
                                  color: AppColors.primary,
                                  size: 24,
                                ),
                              ),
                              const SizedBox(width: 14),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      'Past 7 Days Summary',
                                      style: TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: theme.colorScheme.onSurface,
                                      ),
                                    ),
                                    const SizedBox(height: 2),
                                    Text(
                                      _analyticsData?.range.displayLabel ?? 'This Week',
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: theme.colorScheme.onSurfaceVariant,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          Text(
                            _analyticsData?.hasData == true
                                ? 'You have logged ${_analyticsData!.summary.totalRecords} out of ${_analyticsData!.summary.elapsedDays} elapsed days this week. Here is your aggregated activity summary calculated directly from your local SQLite records.'
                                : 'No activity records have been logged yet for this week. Add daily records to see your weekly trends and completion rates here.',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: theme.colorScheme.onSurface,
                              height: 1.45,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    if (_analyticsData?.hasData == true) ...[
                      // Averages
                      _buildSectionTitle(context, 'Weekly Averages (Recorded Days)'),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18.0),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.border.withAlpha(160),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildStatRow(
                              icon: Icons.directions_walk_rounded,
                              iconColor: const Color(0xFF047857),
                              label: 'Average Steps',
                              value: '${numberFormat.format(_analyticsData!.summary.averageSteps)} steps / day',
                              context: context,
                            ),
                            const Divider(height: 20),
                            _buildStatRow(
                              icon: Icons.water_drop_rounded,
                              iconColor: const Color(0xFF0284C7),
                              label: 'Average Hydration',
                              value: '${UnitConverter.formatWater((_analyticsData!.summary.averageWaterLitres * 1000).round(), widget.unitSystem)} / day',
                              context: context,
                            ),
                            const Divider(height: 20),
                            _buildStatRow(
                              icon: Icons.local_fire_department_rounded,
                              iconColor: const Color(0xFFD97706),
                              label: 'Average Energy Burn',
                              value: '${numberFormat.format(_analyticsData!.summary.averageCalories)} kcal / day',
                              context: context,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 20),

                      // Goal Completion Rates
                      _buildSectionTitle(context, 'Goal Completion Rates'),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(18.0),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.border.withAlpha(160),
                          ),
                        ),
                        child: Column(
                          children: [
                            _buildCompletionRow(
                              label: 'Steps Goal Met',
                              achievedDays: _analyticsData!.goalStats.stepsDaysAchieved,
                              totalDays: _analyticsData!.goalStats.denominatorDays,
                              percentage: _analyticsData!.goalStats.stepsPercentage,
                              color: AppColors.statusSuccess,
                              context: context,
                            ),
                            const SizedBox(height: 14),
                            _buildCompletionRow(
                              label: 'Water Target Met',
                              achievedDays: _analyticsData!.goalStats.waterDaysAchieved,
                              totalDays: _analyticsData!.goalStats.denominatorDays,
                              percentage: _analyticsData!.goalStats.waterPercentage,
                              color: const Color(0xFF0284C7),
                              context: context,
                            ),
                            const SizedBox(height: 14),
                            _buildCompletionRow(
                              label: 'Calorie Target Met',
                              achievedDays: _analyticsData!.goalStats.caloriesDaysAchieved,
                              totalDays: _analyticsData!.goalStats.denominatorDays,
                              percentage: _analyticsData!.goalStats.caloriesPercentage,
                              color: const Color(0xFFD97706),
                              context: context,
                            ),
                          ],
                        ),
                      ),
                    ],
                    const SizedBox(height: 20),

                    // Privacy Note
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16.0),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.infoBannerBackgroundDark : AppColors.infoBannerBackground,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                        border: Border.all(
                          color: isDark ? AppColors.borderDark : AppColors.border.withAlpha(140),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.lock_outline_rounded,
                            color: AppColors.statusSuccess,
                            size: 20,
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              'This weekly digest is calculated strictly from your local SQLite database on this device. HealthMate never uploads or sells your personal metrics.',
                              style: TextStyle(
                                fontSize: 12.5,
                                color: theme.colorScheme.onSurfaceVariant,
                                height: 1.4,
                              ),
                            ),
                          ),
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

  Widget _buildStatRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String value,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Row(
          children: [
            Icon(icon, color: iconColor, size: 20),
            const SizedBox(width: 10),
            Text(
              label,
              style: TextStyle(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Widget _buildCompletionRow({
    required String label,
    required int achievedDays,
    required int totalDays,
    required int percentage,
    required Color color,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 13.5,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
            ),
            Text(
              '$achievedDays of $totalDays days ($percentage%)',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (percentage / 100.0).clamp(0.0, 1.0),
            backgroundColor: color.withAlpha(40),
            valueColor: AlwaysStoppedAnimation<Color>(color),
            minHeight: 6,
          ),
        ),
      ],
    );
  }
}
