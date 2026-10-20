import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/bottom_navigation.dart';
import '../../../core/widgets/healthmate_header.dart';
import '../../../core/widgets/weekly_activity_chart.dart';
import '../../../domain/services/health_record_service.dart';
import '../../../domain/services/onboarding_service.dart';
import '../../records/views/records_screen.dart';
import '../../settings/views/settings_screen.dart';

/// Progress Screen showing weekly metrics, trends, and achievements.
class ProgressScreen extends StatefulWidget {
  const ProgressScreen({super.key});

  @override
  State<ProgressScreen> createState() => _ProgressScreenState();
}

class _ProgressScreenState extends State<ProgressScreen> {
  WeeklyActivityData? _weeklyData;
  int _totalSteps = 0;
  int _averageSteps = 0;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<void> _loadProgress() async {
    final recordService = context.read<HealthRecordService>();
    final onboardingService = context.read<OnboardingService>();

    final goals = await onboardingService.getGoals();
    final stepGoal = goals?.stepsGoal ?? 10000;

    final data = await recordService.getWeeklyActivityData(DateTime.now(), stepGoal);
    setState(() {
      _weeklyData = data;
      _totalSteps = data.totalSteps;
      _averageSteps = data.averageSteps;
      _isLoading = false;
    });
  }

  void _onBottomNavTap(int index) {
    if (index == 2) return; // already in Progress

    if (index == 0) {
      Navigator.maybePop(context);
      return;
    }

    Widget screen;
    switch (index) {
      case 1:
        screen = const RecordsScreen();
        break;
      case 3:
        screen = const SettingsScreen();
        break;
      default:
        return;
    }

    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    final numberFormat = NumberFormat('#,###');

    return Scaffold(
      backgroundColor: AppColors.scaffoldBackground,
      appBar: HealthMateHeader.detail(
        title: 'Activity Progress',
        onBackPressed: () => Navigator.maybePop(context),
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Weekly Performance',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Track consistency across your daily wellness goals.',
                    style: TextStyle(
                      fontSize: 14,
                      color: AppColors.textSecondary,
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_weeklyData != null)
                    WeeklyActivityChart(data: _weeklyData!),
                  const SizedBox(height: 20),

                  // 2x2 Metric Cards Grid
                  Row(
                    children: [
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Total Steps',
                          value: numberFormat.format(_totalSteps),
                          unit: 'steps this week',
                          icon: Icons.directions_walk_rounded,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildMetricCard(
                          title: 'Daily Average',
                          value: numberFormat.format(_averageSteps),
                          unit: 'steps / day',
                          icon: Icons.speed_rounded,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Achievement Note
                  Container(
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: AppColors.mintBadge,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                    ),
                    child: Row(
                      children: const [
                        Icon(
                          Icons.emoji_events_outlined,
                          color: AppColors.primary,
                          size: 28,
                        ),
                        SizedBox(width: 14),
                        Expanded(
                          child: Text(
                            'Consistency is key! Every step and glass of water builds long-term vitality.',
                            style: TextStyle(
                              fontSize: 13.5,
                              color: AppColors.primaryDark,
                              fontWeight: FontWeight.w600,
                              height: 1.35,
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
      bottomNavigationBar: HealthMateBottomNavigation(
        currentIndex: 2,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildMetricCard({
    required String title,
    required String value,
    required String unit,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(color: AppColors.border.withAlpha(160)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.primary, size: 26),
          const SizedBox(height: 12),
          Text(
            title,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: const TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
          Text(
            unit,
            style: const TextStyle(
              fontSize: 11,
              color: AppColors.textMuted,
            ),
          ),
        ],
      ),
    );
  }
}
