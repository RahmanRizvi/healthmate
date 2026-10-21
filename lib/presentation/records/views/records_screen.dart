import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/utils/date_formatter.dart';
import '../../../core/widgets/bottom_navigation.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/healthmate_header.dart';
import '../../../core/widgets/record_history_card.dart';
import '../../../core/widgets/record_summary_card.dart';
import '../../../data/models/health_record.dart';
import '../../../domain/services/health_record_service.dart';
import '../../../domain/services/onboarding_service.dart';
import '../../progress/views/progress_screen.dart';
import '../../settings/views/settings_screen.dart';
import '../viewmodels/records_viewmodel.dart';
import 'add_record_screen.dart';
import 'record_details_screen.dart';

/// Screen listing historical health records with search, date filters, sorting, statistics, and detail view.
/// Matches Figma Screenshot 2.
class RecordsScreen extends StatefulWidget {
  final RecordsViewModel? viewModel;

  const RecordsScreen({super.key, this.viewModel});

  @override
  State<RecordsScreen> createState() => _RecordsScreenState();
}

class _RecordsScreenState extends State<RecordsScreen> {
  late final TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _onBottomNavTap(BuildContext context, int index) {
    if (index == 1) return; // already here

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

  Future<void> _openAddRecord(BuildContext context, RecordsViewModel vm) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddRecordScreen(
          selectedDate: DateTime.now(),
        ),
      ),
    );

    if (result == true) {
      await vm.loadRecords();
    }
  }

  Future<void> _openRecordDetails(
    BuildContext context,
    RecordsViewModel vm,
    HealthRecord record,
  ) async {
    if (record.id == null) return;

    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => RecordDetailsScreen(
          recordId: record.id!,
          initialRecord: record,
        ),
      ),
    );

    if (result == true) {
      await vm.loadRecords();
    }
  }

  Future<void> _openEditRecord(
    BuildContext context,
    RecordsViewModel vm,
    HealthRecord record,
  ) async {
    final result = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => AddRecordScreen(
          selectedDate: record.dateTime,
          initialRecord: record,
          isEditMode: true,
        ),
      ),
    );

    if (result == true) {
      await vm.loadRecords();
    }
  }

  Future<void> _handleDeleteRecord(
    BuildContext context,
    RecordsViewModel vm,
    HealthRecord record,
  ) async {
    final confirmed = await ConfirmationDialog.show(
      context: context,
      title: 'Delete record?',
      message:
          'Are you sure you want to delete the record for ${DateFormatter.formatFullDate(record.dateTime)}? This action cannot be undone.',
      confirmLabel: 'Delete',
    );

    if (confirmed && record.id != null) {
      final success = await vm.deleteRecord(record.id!);
      if (!context.mounted) return;

      if (success) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Record deleted successfully!'),
            backgroundColor: AppColors.primary,
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _pickCustomDate(BuildContext context, RecordsViewModel vm) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.customSelectedDate ?? now,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 365)),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              onSurface: AppColors.textPrimary,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      vm.setCustomDate(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) =>
          widget.viewModel ??
          RecordsViewModel(
            recordService: ctx.read<HealthRecordService>(),
            onboardingService: ctx.read<OnboardingService>(),
          ),
      child: Consumer<RecordsViewModel>(
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
                : RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: vm.loadRecords,
                    child: SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(
                        parent: BouncingScrollPhysics(),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 20.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const SizedBox(height: 12),

                          // Heading & Subtitle
                          const Text(
                            'Your records',
                            style: TextStyle(
                              fontSize: 26,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                              letterSpacing: -0.6,
                            ),
                          ),
                          const SizedBox(height: 4),
                          const Text(
                            'Review your daily health activity.',
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                          const SizedBox(height: 18),

                          // 3 Summary Statistics Cards
                          Row(
                            children: [
                              Expanded(
                                child: RecordSummaryCard(
                                  icon: Icons.article_outlined,
                                  value: vm.totalRecordsCount.toString(),
                                  label: 'Total records',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: RecordSummaryCard(
                                  icon: Icons.directions_run_rounded,
                                  value: numberFormat.format(vm.averageSteps),
                                  label: 'Avg steps',
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: RecordSummaryCard(
                                  icon: Icons.water_drop_outlined,
                                  value: vm.totalWaterFormatted,
                                  label: 'Total water',
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),

                          // Search Bar
                          _buildSearchBar(vm),
                          const SizedBox(height: 14),

                          // Date Filter Chips Row
                          _buildFilterChips(context, vm),
                          const SizedBox(height: 18),

                          // + Add Record Prominent Button
                          _buildAddRecordButton(context, vm),
                          const SizedBox(height: 22),

                          // Daily history Section Header & Sorting
                          _buildDailyHistoryHeader(vm),
                          const SizedBox(height: 14),

                          // List of Record Cards or Empty State
                          if (vm.filteredRecords.isEmpty)
                            _buildEmptyState(context, vm)
                          else
                            ...vm.filteredRecords.map(
                              (record) => RecordHistoryCard(
                                record: record,
                                goals: vm.goals,
                                onTap: () => _openRecordDetails(context, vm, record),
                                onEdit: () => _openEditRecord(context, vm, record),
                                onDelete: () => _handleDeleteRecord(context, vm, record),
                              ),
                            ),

                          const SizedBox(height: 28),
                        ],
                      ),
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

  // ================= Search Bar =================
  Widget _buildSearchBar(RecordsViewModel vm) {
    return Container(
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(color: AppColors.border.withAlpha(160)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(5),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: TextField(
        controller: _searchController,
        onChanged: vm.setSearchQuery,
        style: const TextStyle(
          fontSize: 14,
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w500,
        ),
        decoration: InputDecoration(
          hintText: 'Search records by date (e.g. Oct 24)',
          hintStyle: const TextStyle(
            fontSize: 13.5,
            color: AppColors.textMuted,
            fontWeight: FontWeight.w400,
          ),
          prefixIcon: const Icon(
            Icons.search_rounded,
            color: AppColors.textSecondary,
            size: 20,
          ),
          suffixIcon: _searchController.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(
                    Icons.close_rounded,
                    color: AppColors.textSecondary,
                    size: 18,
                  ),
                  onPressed: () {
                    _searchController.clear();
                    vm.clearSearch();
                  },
                )
              : null,
          filled: false,
          fillColor: Colors.transparent,
          border: InputBorder.none,
          enabledBorder: InputBorder.none,
          focusedBorder: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14.0,
            vertical: 12.0,
          ),
        ),
      ),
    );
  }

  // ================= Filter Chips Row =================
  Widget _buildFilterChips(BuildContext context, RecordsViewModel vm) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      physics: const BouncingScrollPhysics(),
      child: Row(
        children: [
          // "Filter by date" button
          InkWell(
            onTap: () => _pickCustomDate(context, vm),
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 8.0),
              decoration: BoxDecoration(
                color: vm.selectedFilter == DateFilterType.custom
                    ? AppColors.primaryDark
                    : Colors.white,
                borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                border: Border.all(
                  color: vm.selectedFilter == DateFilterType.custom
                      ? AppColors.primaryDark
                      : AppColors.border,
                ),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withAlpha(4),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.tune_rounded,
                    size: 16,
                    color: vm.selectedFilter == DateFilterType.custom
                        ? Colors.white
                        : AppColors.textPrimary,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    vm.filterButtonLabel,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: vm.selectedFilter == DateFilterType.custom
                          ? Colors.white
                          : AppColors.textPrimary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(width: 8),

          // "All" chip
          _buildFilterChip(
            label: 'All',
            isActive: vm.selectedFilter == DateFilterType.all,
            onTap: () => vm.setFilter(DateFilterType.all),
          ),
          const SizedBox(width: 8),

          // "Today" chip
          _buildFilterChip(
            label: 'Today',
            isActive: vm.selectedFilter == DateFilterType.today,
            onTap: () => vm.setFilter(DateFilterType.today),
          ),
          const SizedBox(width: 8),

          // "This week" chip
          _buildFilterChip(
            label: 'This week',
            isActive: vm.selectedFilter == DateFilterType.thisWeek,
            onTap: () => vm.setFilter(DateFilterType.thisWeek),
          ),
          const SizedBox(width: 8),

          // "This month" chip
          _buildFilterChip(
            label: 'This month',
            isActive: vm.selectedFilter == DateFilterType.thisMonth,
            onTap: () => vm.setFilter(DateFilterType.thisMonth),
          ),
        ],
      ),
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primaryDark : Colors.white,
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          border: Border.all(
            color: isActive ? AppColors.primaryDark : AppColors.border,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withAlpha(4),
              blurRadius: 6,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: isActive ? Colors.white : AppColors.textPrimary,
          ),
        ),
      ),
    );
  }

  // ================= + Add Record Button =================
  Widget _buildAddRecordButton(BuildContext context, RecordsViewModel vm) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: ElevatedButton.icon(
        onPressed: () => _openAddRecord(context, vm),
        icon: Container(
          width: 22,
          height: 22,
          decoration: BoxDecoration(
            color: Colors.white.withAlpha(40),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.add_rounded,
            size: 17,
            color: Colors.white,
          ),
        ),
        label: const Text(
          'Add Record',
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w700,
            letterSpacing: -0.2,
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
    );
  }

  // ================= Daily history Section Header =================
  Widget _buildDailyHistoryHeader(RecordsViewModel vm) {
    final sortLabel = vm.sortOrder == RecordSortOrder.newestFirst
        ? 'Newest first'
        : 'Oldest first';

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Wrap(
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: 8,
            runSpacing: 4,
            children: [
              const Text(
                'Daily history',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primaryDark,
                  letterSpacing: -0.4,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 3.0),
                decoration: BoxDecoration(
                  color: const Color(0xFFCCFBEF),
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                ),
                child: Text(
                  '${vm.filteredRecords.length} records',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),

        // Sorting Control Button
        InkWell(
          onTap: vm.toggleSortOrder,
          borderRadius: BorderRadius.circular(6),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  sortLabel,
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 4),
                const Icon(
                  Icons.swap_vert_rounded,
                  size: 16,
                  color: AppColors.textSecondary,
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // ================= Empty State =================
  Widget _buildEmptyState(BuildContext context, RecordsViewModel vm) {
    final isFiltered = vm.hasActiveFilterOrSearch;

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 40.0, horizontal: 20.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: const BoxDecoration(
                color: AppColors.mintBadge,
                shape: BoxShape.circle,
              ),
              child: Icon(
                isFiltered ? Icons.search_off_rounded : Icons.article_outlined,
                color: AppColors.primary,
                size: 30,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              isFiltered ? 'No matching records found' : 'No records logged yet',
              style: const TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              isFiltered
                  ? 'Try adjusting your search query or clear your active filters.'
                  : 'Log your activity daily to build your wellness history.',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 20),
            if (isFiltered)
              OutlinedButton.icon(
                onPressed: () {
                  _searchController.clear();
                  vm.resetFilters();
                },
                icon: const Icon(Icons.refresh_rounded, size: 18),
                label: const Text('Reset filters'),
                style: OutlinedButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  side: const BorderSide(color: AppColors.primary),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 11),
                ),
              )
            else
              ElevatedButton.icon(
                onPressed: () => _openAddRecord(context, vm),
                icon: const Icon(Icons.add_rounded, size: 18),
                label: const Text('Add your first record'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primaryDark,
                  foregroundColor: Colors.white,
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                  ),
                  padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
