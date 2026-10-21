import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/bottom_navigation.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/healthmate_header.dart';
import '../../../data/models/health_record.dart';
import '../../../domain/services/health_record_service.dart';
import '../../../domain/services/onboarding_service.dart';
import '../../progress/views/progress_screen.dart';
import '../../settings/views/settings_screen.dart';
import '../viewmodels/record_details_viewmodel.dart';
import 'add_record_screen.dart';

/// Screen displaying complete breakdown of a daily health record matching Figma Screenshot 1.
class RecordDetailsScreen extends StatelessWidget {
  final int recordId;
  final HealthRecord? initialRecord;
  final RecordDetailsViewModel? viewModel;

  const RecordDetailsScreen({
    super.key,
    required this.recordId,
    this.initialRecord,
    this.viewModel,
  });

  void _onBottomNavTap(BuildContext context, int index) {
    if (index == 1) return; // already in Records

    if (index == 0) {
      Navigator.of(context).popUntil((route) => route.isFirst);
      return;
    }

    Widget screen;
    switch (index) {
      case 2:
        screen = const ProgressScreen();
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

  Future<void> _handleEdit(BuildContext context, RecordDetailsViewModel vm) async {
    final record = vm.record;
    if (record == null) return;

    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddRecordScreen(
          selectedDate: record.dateTime,
          initialRecord: record,
          isEditMode: true,
        ),
      ),
    );

    if (updated == true) {
      await vm.loadRecord();
    }
  }

  Future<void> _handleDelete(BuildContext context, RecordDetailsViewModel vm) async {
    final record = vm.record;
    if (record == null) return;

    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete record?',
      message:
          'Are you sure you want to delete the health record for ${vm.formattedActivityDate}? This action cannot be undone.',
      confirmLabel: 'Delete Record',
    );

    if (confirmed) {
      final success = await vm.deleteRecord();
      if (!context.mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Record deleted successfully!'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 2),
          ),
        );
        Navigator.of(context).pop(true);
      } else if (vm.errorMessage != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(vm.errorMessage!),
            backgroundColor: Colors.redAccent,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) =>
          viewModel ??
          RecordDetailsViewModel(
            recordId: recordId,
            initialRecord: initialRecord,
            recordService: ctx.read<HealthRecordService>(),
            onboardingService: ctx.read<OnboardingService>(),
          ),
      child: Consumer<RecordDetailsViewModel>(
        builder: (context, vm, _) {
          final numberFormat = NumberFormat('#,###');

          return Scaffold(
            backgroundColor: AppColors.scaffoldBackground,
            appBar: HealthMateHeader.detail(
              title: 'Record Details',
              onBackPressed: () => Navigator.of(context).pop(true),
            ),
            body: vm.isLoading && vm.record == null
                ? const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  )
                : vm.record == null
                    ? Center(
                        child: Text(
                          vm.errorMessage ?? 'Record not found.',
                          style: const TextStyle(color: AppColors.textSecondary),
                        ),
                      )
                    : SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20.0,
                          vertical: 12.0,
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // 1. Date Summary Card
                            _buildDateSummaryCard(vm),
                            const SizedBox(height: 16),

                            // 2. Steps Walked Card
                            _buildMetricCard(
                              icon: Icons.directions_run_rounded,
                              iconColor: AppColors.primary,
                              title: 'Steps walked',
                              goalLabel: 'Goal: ${numberFormat.format(vm.goals.stepsGoal)}',
                              value: numberFormat.format(vm.record!.steps),
                              unit: 'steps',
                              progressRatio: vm.stepsProgressRatio,
                              progressColor: AppColors.primaryDark,
                              leftSubtext: '${vm.stepsPercentage.toStringAsFixed(1)}% completed',
                              rightSubtext: '${numberFormat.format(vm.remainingSteps)} steps remaining',
                            ),
                            const SizedBox(height: 16),

                            // 3. Calories Burned Card
                            _buildMetricCard(
                              icon: Icons.local_fire_department_rounded,
                              iconColor: const Color(0xFF047857),
                              title: 'Calories burned',
                              goalLabel: 'Goal: ${numberFormat.format(vm.goals.caloriesGoalKcal)} kcal',
                              value: numberFormat.format(vm.record!.calories),
                              unit: 'kcal',
                              progressRatio: vm.caloriesProgressRatio,
                              progressColor: const Color(0xFF34D399),
                              leftSubtext: '${vm.caloriesPercentage.round()}% of daily burn target',
                              rightSubtext: '${numberFormat.format(vm.remainingCalories)} kcal remaining',
                            ),
                            const SizedBox(height: 16),

                            // 4. Water Intake Card
                            _buildMetricCard(
                              icon: Icons.water_drop_rounded,
                              iconColor: const Color(0xFF0F766E),
                              title: 'Water intake',
                              goalLabel: 'Goal: ${numberFormat.format(vm.goals.waterGoalMl)} ml',
                              value: numberFormat.format(vm.record!.water),
                              unit: 'ml',
                              progressRatio: vm.waterProgressRatio,
                              progressColor: const Color(0xFF0F766E),
                              leftSubtext: '${vm.waterPercentage.round()}% of hydration target',
                              rightSubtext: '${numberFormat.format(vm.remainingWater)} ml remaining',
                            ),
                            const SizedBox(height: 16),

                            // 5. Daily Progress Breakdown Card
                            _buildDailyProgressCard(vm, numberFormat),
                            const SizedBox(height: 24),

                            // 6. Action Buttons (Edit Record & Delete Record)
                            _buildActionButtons(context, vm),
                            const SizedBox(height: 20),

                            // 7. Record Metadata Timestamps
                            Center(
                              child: Column(
                                children: [
                                  Text(
                                    vm.recordedAtTimestamp,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w400,
                                    ),
                                  ),
                                  const SizedBox(height: 3),
                                  Text(
                                    vm.lastUpdatedTimestamp,
                                    style: const TextStyle(
                                      fontSize: 12,
                                      color: AppColors.textMuted,
                                      fontWeight: FontWeight.w400,
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
              currentIndex: 1,
              onTap: (index) => _onBottomNavTap(context, index),
            ),
          );
        },
      ),
    );
  }

  // ================= 1. Date Summary Card =================
  Widget _buildDateSummaryCard(RecordDetailsViewModel vm) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXXL),
        border: Border.all(color: AppColors.border.withAlpha(140)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
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
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.primary,
                  size: 22,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      vm.formattedActivityDate,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                        letterSpacing: -0.3,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vm.weekdayName,
                      style: const TextStyle(
                        fontSize: 13,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Badges Row
          Row(
            children: [
              // Daily summary pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F3),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                ),
                child: const Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.eco_rounded,
                      color: AppColors.primary,
                      size: 14,
                    ),
                    SizedBox(width: 5),
                    Text(
                      'Daily summary',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Goals on track pill
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10.0, vertical: 5.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFF1F5F3),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.check_circle_outline_rounded,
                      color: AppColors.primary,
                      size: 14,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${vm.goalsMetCount} goals on track',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= 2, 3, 4. Metric Breakdown Card =================
  Widget _buildMetricCard({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String goalLabel,
    required String value,
    required String unit,
    required double progressRatio,
    required Color progressColor,
    required String leftSubtext,
    required String rightSubtext,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXXL),
        border: Border.all(color: AppColors.border.withAlpha(140)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Row
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  icon,
                  color: iconColor,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primaryDark,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFF3F4F6),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                ),
                child: Text(
                  goalLabel,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Metric Value & Unit
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                value,
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                  letterSpacing: -0.6,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                unit,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // Progress Bar
          ClipRRect(
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
            child: LinearProgressIndicator(
              value: progressRatio,
              backgroundColor: const Color(0xFFE2E8F0),
              valueColor: AlwaysStoppedAnimation<Color>(progressColor),
              minHeight: 8,
            ),
          ),
          const SizedBox(height: 10),

          // Subtext Row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Flexible(
                child: Text(
                  leftSubtext,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                rightSubtext,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ================= 5. Daily Progress Breakdown Card =================
  Widget _buildDailyProgressCard(RecordDetailsViewModel vm, NumberFormat numberFormat) {
    final record = vm.record!;
    final stepsRatio = vm.stepsProgressRatio;
    final calRatio = vm.caloriesProgressRatio;
    final waterRatio = vm.waterProgressRatio;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXXL),
        border: Border.all(color: AppColors.border.withAlpha(140)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 10,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header: Daily progress & Overall 78% Badge
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                'Daily progress',
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFBEF),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                ),
                child: Text(
                  'Overall ${vm.overallProgressPercentage}%',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Steps Progress Row
          _buildProgressItem(
            icon: Icons.directions_run_rounded,
            iconColor: AppColors.primary,
            label: 'Steps (${numberFormat.format(record.steps)} / ${numberFormat.format(vm.goals.stepsGoal)})',
            percentage: '${(stepsRatio * 100).round()}%',
            progressRatio: stepsRatio,
            progressColor: AppColors.primaryDark,
          ),
          const SizedBox(height: 14),

          // Calories Progress Row
          _buildProgressItem(
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFF047857),
            label: 'Calories (${numberFormat.format(record.calories)} / ${numberFormat.format(vm.goals.caloriesGoalKcal)} kcal)',
            percentage: '${(calRatio * 100).round()}%',
            progressRatio: calRatio,
            progressColor: const Color(0xFF34D399),
          ),
          const SizedBox(height: 14),

          // Water Progress Row
          _buildProgressItem(
            icon: Icons.water_drop_rounded,
            iconColor: const Color(0xFF0F766E),
            label: 'Water (${numberFormat.format(record.water)} / ${numberFormat.format(vm.goals.waterGoalMl)} ml)',
            percentage: '${(waterRatio * 100).round()}%',
            progressRatio: waterRatio,
            progressColor: const Color(0xFF0F766E),
          ),
        ],
      ),
    );
  }

  Widget _buildProgressItem({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String percentage,
    required double progressRatio,
    required Color progressColor,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Row(
                children: [
                  Icon(icon, size: 16, color: iconColor),
                  const SizedBox(width: 8),
                  Flexible(
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.primaryDark,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Text(
              percentage,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ClipRRect(
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          child: LinearProgressIndicator(
            value: progressRatio,
            backgroundColor: const Color(0xFFE2E8F0),
            valueColor: AlwaysStoppedAnimation<Color>(progressColor),
            minHeight: 6,
          ),
        ),
      ],
    );
  }

  // ================= 6. Action Buttons =================
  Widget _buildActionButtons(BuildContext context, RecordDetailsViewModel vm) {
    return Column(
      children: [
        // Edit Record Button (Dark Green)
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => _handleEdit(context, vm),
            icon: const Icon(Icons.edit_outlined, size: 19),
            label: const Text(
              'Edit Record',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primaryDark,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
              ),
            ),
          ),
        ),
        const SizedBox(height: 12),

        // Delete Record Button (Soft Red)
        SizedBox(
          width: double.infinity,
          height: 52,
          child: ElevatedButton.icon(
            onPressed: () => _handleDelete(context, vm),
            icon: const Icon(Icons.delete_outline_rounded, size: 20),
            label: const Text(
              'Delete Record',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
              ),
            ),
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFEE2E2),
              foregroundColor: const Color(0xFFDC2626),
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
