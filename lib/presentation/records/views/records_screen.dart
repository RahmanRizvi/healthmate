import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/bottom_navigation.dart';
import '../../../core/widgets/healthmate_header.dart';
import '../../../core/widgets/recent_record_card.dart';
import '../../../domain/services/health_record_service.dart';
import '../../../domain/services/onboarding_service.dart';
import '../../progress/views/progress_screen.dart';
import '../../settings/views/settings_screen.dart';
import '../viewmodels/records_viewmodel.dart';
import 'add_record_screen.dart';

/// Screen listing all historical health records with edit and delete capabilities.
class RecordsScreen extends StatelessWidget {
  final RecordsViewModel? viewModel;

  const RecordsScreen({super.key, this.viewModel});

  void _onBottomNavTap(BuildContext context, int index) {
    if (index == 1) return; // already here

    if (index == 0) {
      Navigator.maybePop(context);
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

  Future<void> _editRecord(
    BuildContext context,
    RecordsViewModel vm,
    DateTime recordDate,
  ) async {
    final result = await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddRecordScreen(selectedDate: recordDate),
      ),
    );

    if (result == true) {
      await vm.loadRecords();
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) =>
          viewModel ??
          RecordsViewModel(
            recordService: ctx.read<HealthRecordService>(),
            onboardingService: ctx.read<OnboardingService>(),
          ),
      child: Consumer<RecordsViewModel>(
        builder: (context, vm, _) {
          return Scaffold(
            backgroundColor: AppColors.scaffoldBackground,
            appBar: HealthMateHeader.detail(
              title: 'All Records',
              onBackPressed: () => Navigator.maybePop(context),
              onAddPressed: () => _editRecord(context, vm, DateTime.now()),
            ),
            body: Builder(
              builder: (context) {
                if (vm.isLoading) {
                  return const Center(
                    child: CircularProgressIndicator(color: AppColors.primary),
                  );
                }

                if (vm.records.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(32.0),
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
                            child: const Icon(
                              Icons.article_outlined,
                              color: AppColors.primary,
                              size: 32,
                            ),
                          ),
                          const SizedBox(height: 16),
                          const Text(
                            'No records logged yet',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textPrimary,
                            ),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                            'Log your activity daily to build your wellness history.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 14,
                              color: AppColors.textSecondary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          ElevatedButton.icon(
                            onPressed: () async {
                              final result = await Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => AddRecordScreen(
                                    selectedDate: DateTime.now(),
                                  ),
                                ),
                              );
                              if (result == true) {
                                await vm.loadRecords();
                              }
                            },
                            icon: const Icon(Icons.add_rounded),
                            label: const Text('Add Record'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primaryDark,
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(24),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: vm.loadRecords,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(
                      parent: BouncingScrollPhysics(),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20.0,
                      vertical: 16.0,
                    ),
                    itemCount: vm.records.length,
                    itemBuilder: (context, index) {
                      final record = vm.records[index];
                      return Dismissible(
                        key: ValueKey(record.id ?? record.date),
                        direction: DismissDirection.endToStart,
                        background: Container(
                          alignment: Alignment.centerRight,
                          padding: const EdgeInsets.only(right: 20),
                          margin: const EdgeInsets.only(bottom: 12.0),
                          decoration: BoxDecoration(
                            color: Colors.redAccent,
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(
                            Icons.delete_outline_rounded,
                            color: Colors.white,
                            size: 26,
                          ),
                        ),
                        confirmDismiss: (direction) async {
                          return await showDialog<bool>(
                            context: context,
                            builder: (ctx) => AlertDialog(
                              title: const Text('Delete record?'),
                              content: const Text(
                                'Are you sure you want to delete this daily health record?',
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(false),
                                  child: const Text('Cancel'),
                                ),
                                TextButton(
                                  onPressed: () => Navigator.of(ctx).pop(true),
                                  child: const Text(
                                    'Delete',
                                    style: TextStyle(color: Colors.redAccent),
                                  ),
                                ),
                              ],
                            ),
                          );
                        },
                        onDismissed: (_) {
                          if (record.id != null) {
                            vm.deleteRecord(record.id!);
                          }
                        },
                        child: RecentRecordCard(
                          record: record,
                          status: vm.getRecordStatus(record),
                          onTap: () => _editRecord(context, vm, record.dateTime),
                        ),
                      );
                    },
                  ),
                );
              },
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
}
