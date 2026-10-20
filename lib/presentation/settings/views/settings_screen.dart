import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/bottom_navigation.dart';
import '../../../core/widgets/healthmate_header.dart';
import '../../../data/models/daily_goals.dart';
import '../../../data/models/user_profile.dart';
import '../../../domain/services/onboarding_service.dart';
import '../../progress/views/progress_screen.dart';
import '../../records/views/records_screen.dart';

/// Settings screen displaying user profile summary, daily target preferences, and app version.
class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  UserProfile? _profile;
  DailyGoals? _goals;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final onboardingService = context.read<OnboardingService>();
    final profile = await onboardingService.getProfile();
    final goals = await onboardingService.getGoals();

    setState(() {
      _profile = profile;
      _goals = goals;
      _isLoading = false;
    });
  }

  void _onBottomNavTap(int index) {
    if (index == 3) return; // already in Settings

    if (index == 0) {
      Navigator.maybePop(context);
      return;
    }

    Widget screen;
    switch (index) {
      case 1:
        screen = const RecordsScreen();
        break;
      case 2:
        screen = const ProgressScreen();
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
        title: 'Settings',
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
                  // Profile Section
                  _buildSectionHeader('User Profile'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                      border: Border.all(color: AppColors.border.withAlpha(160)),
                    ),
                    child: Column(
                      children: [
                        _buildSettingRow(
                          label: 'Full Name',
                          value: _profile?.fullName ?? 'Alex Morgan',
                        ),
                        const Divider(height: 24),
                        _buildSettingRow(
                          label: 'Age',
                          value: _profile != null ? '${_profile!.age} years' : '--',
                        ),
                        const Divider(height: 24),
                        _buildSettingRow(
                          label: 'Height',
                          value: _profile != null
                              ? '${_profile!.heightCm.toStringAsFixed(0)} cm'
                              : '--',
                        ),
                        const Divider(height: 24),
                        _buildSettingRow(
                          label: 'Weight',
                          value: _profile != null
                              ? '${_profile!.weightKg.toStringAsFixed(0)} kg'
                              : '--',
                        ),
                        const Divider(height: 24),
                        _buildSettingRow(
                          label: 'Gender',
                          value: _profile?.gender ?? 'Female',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Daily Goals Section
                  _buildSectionHeader('Daily Targets'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                      border: Border.all(color: AppColors.border.withAlpha(160)),
                    ),
                    child: Column(
                      children: [
                        _buildSettingRow(
                          label: 'Steps Goal',
                          value:
                              '${numberFormat.format(_goals?.stepsGoal ?? 10000)} steps',
                        ),
                        const Divider(height: 24),
                        _buildSettingRow(
                          label: 'Water Goal',
                          value:
                              '${numberFormat.format(_goals?.waterGoalMl ?? 2500)} ml',
                        ),
                        const Divider(height: 24),
                        _buildSettingRow(
                          label: 'Calories Goal',
                          value:
                              '${numberFormat.format(_goals?.caloriesGoalKcal ?? 500)} kcal',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),

                  // About Section
                  _buildSectionHeader('About'),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18.0),
                    decoration: BoxDecoration(
                      color: AppColors.cardBackground,
                      borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
                      border: Border.all(color: AppColors.border.withAlpha(160)),
                    ),
                    child: Column(
                      children: [
                        _buildSettingRow(label: 'Version', value: '1.0.0'),
                        const Divider(height: 24),
                        _buildSettingRow(
                          label: 'Storage',
                          value: 'Local SQLite (Encrypted / Private)',
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
      bottomNavigationBar: HealthMateBottomNavigation(
        currentIndex: 3,
        onTap: _onBottomNavTap,
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Padding(
      padding: const EdgeInsets.only(left: 4.0, bottom: 8.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w700,
          color: AppColors.primaryDark,
        ),
      ),
    );
  }

  Widget _buildSettingRow({required String label, required String value}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: const TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary,
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 14.5,
            fontWeight: FontWeight.w700,
            color: AppColors.textPrimary,
          ),
        ),
      ],
    );
  }
}
