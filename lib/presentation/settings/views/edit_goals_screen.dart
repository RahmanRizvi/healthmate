import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../../core/utils/unit_converter.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/healthmate_header.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/daily_goals.dart';
import '../../../domain/services/onboarding_service.dart';

/// Screen allowing the user to update their daily health targets.
class EditGoalsScreen extends StatefulWidget {
  final DailyGoals goals;
  final MeasurementUnitSystem unitSystem;

  const EditGoalsScreen({
    super.key,
    required this.goals,
    required this.unitSystem,
  });

  @override
  State<EditGoalsScreen> createState() => _EditGoalsScreenState();
}

class _EditGoalsScreenState extends State<EditGoalsScreen> {
  late int _steps;
  late int _waterMl;
  late int _calories;

  bool _isSaving = false;
  bool _hasModified = false;

  @override
  void initState() {
    super.initState();
    _steps = widget.goals.stepsGoal;
    _waterMl = widget.goals.waterGoalMl;
    _calories = widget.goals.caloriesGoalKcal;
  }

  void _markModified() {
    if (!_hasModified) {
      setState(() {
        _hasModified = true;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasModified) return true;

    final discard = await ConfirmationDialog.show(
      context: context,
      title: 'Discard Goal Changes?',
      message: 'You have unsaved changes to your daily targets. Are you sure you want to discard them?',
      confirmLabel: 'Discard',
      cancelLabel: 'Keep Editing',
    );
    return discard;
  }

  Future<void> _saveGoals() async {
    setState(() {
      _isSaving = true;
    });

    try {
      if (_steps <= 0 || _waterMl <= 0 || _calories <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('All targets must be greater than zero.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => _isSaving = false);
        return;
      }

      final updatedGoals = widget.goals.copyWith(
        id: 1, // Single daily goals row
        stepsGoal: _steps,
        waterGoalMl: _waterMl,
        caloriesGoalKcal: _calories,
        updatedAt: DateTime.now(),
      );

      final onboardingService = context.read<OnboardingService>();
      await onboardingService.saveGoals(updatedGoals);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Daily goals updated successfully'),
          backgroundColor: AppColors.statusSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update daily goals: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
      setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final numberFormat = NumberFormat('#,###');

    final waterDisplay = UnitConverter.splitWater(_waterMl, widget.unitSystem);

    return PopScope(
      canPop: !_hasModified,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) {
          Navigator.of(context).pop(false);
        }
      },
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: HealthMateHeader.detail(
          title: 'Edit Daily Goals',
          onBackPressed: () async {
            final shouldPop = await _onWillPop();
            if (shouldPop && context.mounted) {
              Navigator.of(context).pop(false);
            }
          },
        ),
        body: SafeArea(
          child: SingleChildScrollView(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Set Your Daily Benchmarks',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.mint : AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Adjust your daily targets. These drive the progress indicators on your dashboard and records.',
                  style: TextStyle(
                    fontSize: 13.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 20),

                // Steps Card
                _buildGoalCard(
                  icon: Icons.directions_walk_rounded,
                  iconColor: const Color(0xFF047857),
                  iconBg: const Color(0xFFB7F7DE),
                  title: 'Daily Steps',
                  subtitle: 'Daily activity marker',
                  valueString: numberFormat.format(_steps),
                  unitString: 'steps',
                  onDecrement: _steps > DailyGoals.minSteps
                      ? () {
                          setState(() {
                            _steps -= DailyGoals.stepIncrement;
                            _markModified();
                          });
                        }
                      : null,
                  onIncrement: () {
                    setState(() {
                      _steps += DailyGoals.stepIncrement;
                      _markModified();
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Water Card
                _buildGoalCard(
                  icon: Icons.water_drop_rounded,
                  iconColor: const Color(0xFF0284C7),
                  iconBg: const Color(0xFFE0F2FE),
                  title: 'Water Intake',
                  subtitle: 'Hydration target',
                  valueString: waterDisplay.value,
                  unitString: waterDisplay.unit,
                  onDecrement: _waterMl > DailyGoals.minWaterMl
                      ? () {
                          setState(() {
                            _waterMl -= DailyGoals.waterIncrement;
                            _markModified();
                          });
                        }
                      : null,
                  onIncrement: () {
                    setState(() {
                      _waterMl += DailyGoals.waterIncrement;
                      _markModified();
                    });
                  },
                ),
                const SizedBox(height: 16),

                // Calories Card
                _buildGoalCard(
                  icon: Icons.local_fire_department_rounded,
                  iconColor: const Color(0xFFD97706),
                  iconBg: const Color(0xFFFEF3C7),
                  title: 'Active Calories',
                  subtitle: 'Movement energy',
                  valueString: numberFormat.format(_calories),
                  unitString: 'kcal',
                  onDecrement: _calories > DailyGoals.minCaloriesKcal
                      ? () {
                          setState(() {
                            _calories -= DailyGoals.caloriesIncrement;
                            _markModified();
                          });
                        }
                      : null,
                  onIncrement: () {
                    setState(() {
                      _calories += DailyGoals.caloriesIncrement;
                      _markModified();
                    });
                  },
                ),
                const SizedBox(height: 32),

                // Actions
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton(
                        onPressed: _isSaving
                            ? null
                            : () async {
                                final shouldPop = await _onWillPop();
                                if (shouldPop && context.mounted) {
                                  Navigator.of(context).pop(false);
                                }
                              },
                        style: OutlinedButton.styleFrom(
                          side: BorderSide(
                            color: isDark ? AppColors.borderDark : AppColors.border,
                          ),
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          shape: RoundedRectangleBorder(
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusL),
                          ),
                        ),
                        child: Text(
                          'Cancel',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      flex: 2,
                      child: PrimaryButton(
                        text: 'Save Changes',
                        icon: null,
                        isLoading: _isSaving,
                        onPressed: _saveGoals,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildGoalCard({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String valueString,
    required String unitString,
    required VoidCallback? onDecrement,
    required VoidCallback onIncrement,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border.withAlpha(160),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(isDark ? 30 : 8),
            blurRadius: 10,
            offset: const Offset(0, 3),
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
                  color: isDark ? iconColor.withAlpha(40) : iconBg,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    icon,
                    color: isDark ? AppColors.mint : iconColor,
                    size: 24,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 12.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: isDark
                  ? AppColors.cardElevatedDark
                  : AppColors.stepperBackground,
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                _buildStepperButton(
                  icon: Icons.remove_rounded,
                  onPressed: onDecrement,
                  isEnabled: onDecrement != null,
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      valueString,
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.mint : AppColors.primaryDark,
                        letterSpacing: -0.5,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      unitString,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
                _buildStepperButton(
                  icon: Icons.add_rounded,
                  onPressed: onIncrement,
                  isEnabled: true,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepperButton({
    required IconData icon,
    required VoidCallback? onPressed,
    required bool isEnabled,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: isDark
            ? (isEnabled ? AppColors.pillBackgroundDark : AppColors.cardBackgroundDark)
            : (isEnabled ? Colors.white : Colors.white.withAlpha(160)),
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.border.withAlpha(120),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          onTap: onPressed,
          child: Center(
            child: Icon(
              icon,
              size: 22,
              color: isEnabled
                  ? (isDark ? Colors.white : AppColors.primaryDark)
                  : (isDark ? AppColors.textMutedDark : AppColors.textMuted),
            ),
          ),
        ),
      ),
    );
  }
}
