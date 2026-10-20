import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/activity_progress_card.dart';
import '../../../core/widgets/bottom_navigation.dart';
import '../../../core/widgets/healthmate_header.dart';
import '../../../core/widgets/recent_record_card.dart';
import '../../../core/widgets/weekly_activity_chart.dart';
import '../../../domain/services/health_record_service.dart';
import '../../../domain/services/onboarding_service.dart';
import '../../progress/views/progress_screen.dart';
import '../../records/views/add_record_screen.dart';
import '../../records/views/records_screen.dart';
import '../../settings/views/settings_screen.dart';
import '../viewmodels/dashboard_viewmodel.dart';

/// Main HealthMate Dashboard Screen matching Figma screenshots 1 and 2.
class DashboardScreen extends StatelessWidget {
  final DashboardViewModel? viewModel;
  final bool isJustCompletedOnboarding;

  const DashboardScreen({
    super.key,
    this.viewModel,
    this.isJustCompletedOnboarding = false,
  });

  Future<void> _navigateToAddRecord(
    BuildContext context,
    DashboardViewModel vm, {
    DateTime? initialDate,
  }) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddRecordScreen(
          selectedDate: initialDate ?? DateTime.now(),
        ),
      ),
    );

    if (result == true) {
      await vm.loadDashboard();
    }
  }

  void _onBottomNavTap(BuildContext context, int index) {
    if (index == 0) return; // already on Home

    Widget screen;
    switch (index) {
      case 1:
        screen = const RecordsScreen();
        break;
      case 2:
        screen = const ProgressScreen();
        break;
      case 3:
        screen = const SettingsScreen();
        break;
      default:
        return;
    }

    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) =>
          viewModel ??
          DashboardViewModel(
            onboardingService: ctx.read<OnboardingService>(),
            recordService: ctx.read<HealthRecordService>(),
          ),
      child: Consumer<DashboardViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            backgroundColor: AppColors.scaffoldBackground,
            appBar: HealthMateHeader.dashboard(
              onAddPressed: () => _navigateToAddRecord(context, vm),
            ),
            body: vm.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : RefreshIndicator(
              color: AppColors.primary,
              onRefresh: vm.loadDashboard,
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(
                  parent: BouncingScrollPhysics(),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // Greeting Section with Date and Streak Badge
                    _buildGreetingSection(vm),
                    const SizedBox(height: 16),

                    // Onboarding "You're all set!" banner (shown only right after onboarding)
                    if (isJustCompletedOnboarding && !vm.isBannerDismissed) ...[
                      _buildCalibratedBanner(vm),
                      const SizedBox(height: 18),
                    ],

                    // "Today's activity" Header
                    Row(
                      children: const [
                        Icon(
                          Icons.schedule_rounded,
                          color: AppColors.primaryDark,
                          size: 20,
                        ),
                        SizedBox(width: 8),
                        Text(
                          "Today's activity",
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Steps Walked Card
                    StepsActivityCard(
                      currentSteps: vm.todaySteps,
                      stepGoal: vm.stepsGoal,
                      averageSteps: vm.averageSteps,
                    ),
                    const SizedBox(height: 14),

                    // 2-Column Row: Calories & Water
                    Row(
                      children: [
                        Expanded(
                          child: CaloriesActivityCard(
                            currentCalories: vm.todayCalories,
                            caloriesGoal: vm.caloriesGoal,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: WaterActivityCard(
                            currentWaterMl: vm.todayWaterMl,
                            waterGoalMl: vm.waterGoalMl,
                            onQuickAdd: () => vm.quickAddWater(250),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    // "Add today's record" Button
                    _buildAddTodayButton(context, vm),
                    const SizedBox(height: 22),

                    // Weekly Activity Chart
                    if (vm.weeklyData != null)
                      WeeklyActivityChart(
                        data: vm.weeklyData!,
                        onSeeProgress: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => const ProgressScreen(),
                            ),
                          );
                        },
                      ),
                    const SizedBox(height: 24),

                    // Recent Records Header
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Recent records',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                        ),
                        InkWell(
                          onTap: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const RecordsScreen(),
                              ),
                            );
                          },
                          borderRadius: BorderRadius.circular(4),
                          child: const Padding(
                            padding: EdgeInsets.symmetric(
                              horizontal: 6,
                              vertical: 4,
                            ),
                            child: Text(
                              'See all',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textSecondary,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),

                    // Recent Records List or Empty State
                    if (vm.recentRecords.isNotEmpty)
                      ...vm.recentRecords.map(
                        (record) => RecentRecordCard(
                          record: record,
                          status: vm.getRecordStatus(record),
                          onTap: () => _navigateToAddRecord(
                            context,
                            vm,
                            initialDate: record.dateTime,
                          ),
                        ),
                      )
                    else
                      _buildEmptyStateCard(context, vm),

                    const SizedBox(height: 28),
                  ],
                ),
              ),
            ),
            bottomNavigationBar: HealthMateBottomNavigation(
              currentIndex: 0,
              onTap: (index) => _onBottomNavTap(context, index),
            ),
          );
        },
      ),
    );
  }

  /// Greeting section matching Figma.
  Widget _buildGreetingSection(DashboardViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Small green dot + Today Date
        Row(
          children: [
            Container(
              width: 6,
              height: 6,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 6),
            Text(
              vm.greetingDate,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
                letterSpacing: 0.8,
              ),
            ),
          ],
        ),
        const SizedBox(height: 4),

        // Headline & Day Streak Badge
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Text(
                '${vm.greeting}, ${vm.userName} 👋',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                  letterSpacing: -0.5,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(width: 10),

            // Streak Badge (Day X)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                border: Border.all(color: AppColors.border.withAlpha(140)),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(6),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.local_fire_department_rounded,
                    color: AppColors.primary,
                    size: 16,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    'Day ${vm.streakDays}',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 2),
        const Text(
          'Your health, at a glance.',
          style: TextStyle(
            fontSize: 13.5,
            color: AppColors.textSecondary,
            fontWeight: FontWeight.w400,
          ),
        ),
      ],
    );
  }

  /// Calibrated banner for new users (Screenshot 2).
  Widget _buildCalibratedBanner(DashboardViewModel vm) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: const Color(0xFFD3F9E9),
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 28,
            height: 28,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.check_rounded,
              color: Colors.white,
              size: 18,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                Text(
                  "You're all set!",
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
                SizedBox(height: 3),
                Text(
                  'Your daily goals are calibrated. Let\'s start tracking your vitality.',
                  style: TextStyle(
                    fontSize: 12.5,
                    height: 1.35,
                    color: Color(0xFF1E3A34),
                  ),
                ),
              ],
            ),
          ),
          InkWell(
            onTap: vm.dismissBanner,
            child: const Icon(
              Icons.close_rounded,
              size: 18,
              color: AppColors.primaryDark,
            ),
          ),
        ],
      ),
    );
  }

  /// Dark green "Add today's record" button.
  Widget _buildAddTodayButton(BuildContext context, DashboardViewModel vm) {
    return Column(
      children: [
        SizedBox(
          width: double.infinity,
          height: 54,
          child: ElevatedButton(
            onPressed: () => _navigateToAddRecord(context, vm),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: const [
                Icon(
                  Icons.add_circle_outline_rounded,
                  size: 20,
                  color: Colors.white,
                ),
                SizedBox(width: 8),
                Text(
                  "Add today's record",
                  style: TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 6),
        const Text(
          'Log your steps, active calories, and water balance.',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }

  /// Empty state container when no records exist yet (Screenshot 2).
  Widget _buildEmptyStateCard(BuildContext context, DashboardViewModel vm) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 28.0),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXXL),
        border: Border.all(color: AppColors.border.withAlpha(160)),
      ),
      child: Column(
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: const BoxDecoration(
              color: AppColors.mintBadge,
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.edit_calendar_rounded,
              color: AppColors.primary,
              size: 26,
            ),
          ),
          const SizedBox(height: 14),
          const Text(
            'Your journey begins today',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: AppColors.textPrimary,
            ),
          ),
          const SizedBox(height: 6),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Log your morning walks, workouts, or hydration to populate your wellness',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ),
          const SizedBox(height: 18),
          OutlinedButton.icon(
            onPressed: () => _navigateToAddRecord(context, vm),
            icon: const Icon(Icons.add_rounded, size: 18),
            label: const Text('Add your first record'),
            style: OutlinedButton.styleFrom(
              foregroundColor: AppColors.primary,
              side: const BorderSide(color: AppColors.primary),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
            ),
          ),
        ],
      ),
    );
  }
}
