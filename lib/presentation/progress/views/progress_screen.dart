import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/bottom_navigation.dart';
import '../../../core/widgets/healthmate_header.dart';
import '../../../core/widgets/record_summary_card.dart';
import '../../../data/repositories/health_record_repository.dart';
import '../../../domain/services/analytics_service.dart';
import '../../../domain/services/insights_service.dart';
import '../../../domain/services/onboarding_service.dart';
import '../../dashboard/views/dashboard_screen.dart';
import '../../records/views/add_record_screen.dart';
import '../../records/views/records_screen.dart';
import '../../settings/views/settings_screen.dart';
import '../viewmodels/progress_viewmodel.dart';
import '../widgets/daily_goal_completion_section.dart';
import '../widgets/hydration_trend_chart.dart';
import '../widgets/period_selector.dart';
import '../widgets/progress_export_dialog.dart';
import '../widgets/progress_insight_card.dart';
import '../widgets/steps_activity_chart.dart';
import '../widgets/view_all_records_card.dart';
import '../widgets/wellness_tip_card.dart';

/// Progress & Analytics screen reproducing the Figma reference screenshot.
class ProgressScreen extends StatelessWidget {
  final ProgressViewModel? viewModel;

  const ProgressScreen({
    super.key,
    this.viewModel,
  });

  Future<void> _openAddRecord(BuildContext context, ProgressViewModel vm) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddRecordScreen(
          selectedDate: DateTime.now(),
        ),
      ),
    );

    if (result == true) {
      await vm.loadProgress();
    }
  }

  void _navigateToRecords(BuildContext context, ProgressViewModel vm) async {
    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const RecordsScreen()),
    );
  }

  Future<void> _onBottomNavTap(
    BuildContext context,
    ProgressViewModel vm,
    int index,
  ) async {
    if (index == 2) return; // already in Progress

    Widget screen;
    switch (index) {
      case 0:
        screen = const DashboardScreen();
        break;
      case 1:
        screen = const RecordsScreen();
        break;
      case 3:
        screen = const SettingsScreen();
        break;
      default:
        return;
    }

    await Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => screen),
    );
  }

  void _showExportDialog(BuildContext context, ProgressViewModel vm) {
    ProgressExportDialog.show(context, vm);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) =>
          viewModel ??
          ProgressViewModel(
            analyticsService: ctx.read<AnalyticsService>(),
            insightsService: ctx.read<InsightsService>(),
            onboardingService: ctx.read<OnboardingService>(),
            recordRepository: ctx.read<IHealthRecordRepository>(),
          ),
      child: Consumer<ProgressViewModel>(
        builder: (context, vm, _) {
          final numberFormat = NumberFormat('#,###');

          return Scaffold(
            backgroundColor: AppColors.scaffoldBackground,
            appBar: HealthMateHeader.dashboard(
              onAddPressed: () => _openAddRecord(context, vm),
            ),
            body: vm.isLoading
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : vm.errorMessage != null
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24.0),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Icon(Icons.error_outline_rounded, size: 48, color: Colors.redAccent),
                              const SizedBox(height: 12),
                              Text(
                                vm.errorMessage!,
                                textAlign: TextAlign.center,
                                style: const TextStyle(color: AppColors.textSecondary),
                              ),
                              const SizedBox(height: 16),
                              ElevatedButton(
                                onPressed: vm.loadProgress,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primaryDark,
                                  foregroundColor: Colors.white,
                                ),
                                child: const Text('Retry'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : RefreshIndicator(
                        color: AppColors.primary,
                        onRefresh: vm.loadProgress,
                        child: SingleChildScrollView(
                          physics: const AlwaysScrollableScrollPhysics(
                            parent: BouncingScrollPhysics(),
                          ),
                          padding: const EdgeInsets.symmetric(horizontal: 20.0),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 14),

                              // 1. Period Selector Header (Title, Subtitle, Date Range Badge, Week/Month Pills)
                              PeriodSelectorHeader(
                                selectedType: vm.periodType,
                                dateBadgeLabel: vm.periodDateBadgeLabel,
                                canGoNext: vm.canGoNext,
                                onTypeChanged: vm.setPeriodType,
                                onPrevious: vm.goToPreviousPeriod,
                                onNext: vm.goToNextPeriod,
                                onExport: () => _showExportDialog(context, vm),
                              ),
                              const SizedBox(height: 18),

                              // 2. Three Analytics Summary Cards
                              if (vm.analyticsData != null) ...[
                                Row(
                                  children: [
                                    // Avg steps
                                    Expanded(
                                      child: RecordSummaryCard(
                                        icon: Icons.directions_walk_rounded,
                                        iconColor: AppColors.primary,
                                        iconBgColor: const Color(0xFFD1FAE5),
                                        value: numberFormat.format(vm.analyticsData!.summary.averageSteps),
                                        label: 'Avg. steps/d',
                                      ),
                                    ),
                                    const SizedBox(width: 10),

                                    // Avg calories
                                    Expanded(
                                      child: RecordSummaryCard(
                                        icon: Icons.local_fire_department_rounded,
                                        iconColor: const Color(0xFFEA580C),
                                        iconBgColor: const Color(0xFFFFEDD5),
                                        value: numberFormat.format(vm.analyticsData!.summary.averageCalories),
                                        label: 'Avg. kcal/d',
                                      ),
                                    ),
                                    const SizedBox(width: 10),

                                    // Avg water
                                    Expanded(
                                      child: RecordSummaryCard(
                                        icon: Icons.water_drop_rounded,
                                        iconColor: const Color(0xFF0F766E),
                                        iconBgColor: const Color(0xFFCCFBF1),
                                        value: vm.analyticsData!.summary.formattedAverageWaterLitres,
                                        label: 'Avg. water/d',
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 20),

                                // 3. Steps Activity Card
                                StepsActivityChart(
                                  data: vm.analyticsData!,
                                  selectedIndex: vm.selectedDayIndex,
                                  onSelectDay: vm.selectDay,
                                ),
                                const SizedBox(height: 20),

                                // 4. Daily Goal Completion Section
                                DailyGoalCompletionSection(
                                  data: vm.analyticsData!,
                                ),
                                const SizedBox(height: 20),

                                // 5. Hydration Trend Chart
                                HydrationTrendChart(
                                  data: vm.analyticsData!,
                                  selectedIndex: vm.selectedDayIndex,
                                  onSelectDay: vm.selectDay,
                                ),
                                const SizedBox(height: 20),
                              ],

                              // 6. Personalized Insights Card
                              if (vm.currentInsight != null) ...[
                                ProgressInsightCard(insight: vm.currentInsight!),
                                const SizedBox(height: 20),
                              ],

                              // 7. View All Records Card
                              ViewAllRecordsCard(
                                totalRecordsCount: vm.totalAllRecordsCount,
                                onTap: () => _navigateToRecords(context, vm),
                              ),
                              const SizedBox(height: 16),

                              // 8. Wellness Tip Card
                              const WellnessTipCard(),
                              const SizedBox(height: 24),
                            ],
                          ),
                        ),
                      ),
            bottomNavigationBar: HealthMateBottomNavigation(
              currentIndex: 2,
              onTap: (index) => _onBottomNavTap(context, vm, index),
            ),
          );
        },
      ),
    );
  }
}
