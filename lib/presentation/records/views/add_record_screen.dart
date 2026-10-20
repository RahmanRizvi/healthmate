import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/bottom_navigation.dart';
import '../../../core/widgets/healthmate_header.dart';
import '../../../domain/services/health_record_service.dart';
import '../../../domain/services/onboarding_service.dart';
import '../../progress/views/progress_screen.dart';
import '../../settings/views/settings_screen.dart';
import '../viewmodels/add_record_viewmodel.dart';

/// Screen 3: Add/Edit Record screen matching the Figma design.
class AddRecordScreen extends StatefulWidget {
  final DateTime selectedDate;
  final AddRecordViewModel? viewModel;

  const AddRecordScreen({
    super.key,
    required this.selectedDate,
    this.viewModel,
  });

  @override
  State<AddRecordScreen> createState() => _AddRecordScreenState();
}

class _AddRecordScreenState extends State<AddRecordScreen> {
  late final TextEditingController _stepsController;
  late final TextEditingController _caloriesController;
  late final TextEditingController _waterController;

  @override
  void initState() {
    super.initState();
    _stepsController = TextEditingController();
    _caloriesController = TextEditingController();
    _waterController = TextEditingController();
  }

  @override
  void dispose() {
    _stepsController.dispose();
    _caloriesController.dispose();
    _waterController.dispose();
    super.dispose();
  }

  void _syncControllers(AddRecordViewModel vm) {
    if (_stepsController.text != vm.steps.toString()) {
      _stepsController.text = vm.steps > 0 ? vm.steps.toString() : '';
    }
    if (_caloriesController.text != vm.calories.toString()) {
      _caloriesController.text = vm.calories > 0 ? vm.calories.toString() : '';
    }
    if (_waterController.text != vm.water.toString()) {
      _waterController.text = vm.water > 0 ? vm.water.toString() : '';
    }
  }

  Future<void> _pickDate(BuildContext context, AddRecordViewModel vm) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: vm.selectedDate,
      firstDate: DateTime(2020),
      lastDate: now,
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
      await vm.setDate(picked);
      _syncControllers(vm);
    }
  }

  void _handleCancel(BuildContext context) {
    Navigator.maybePop(context);
  }

  void _onBottomNavTap(BuildContext context, int index) {
    if (index == 1) return; // already in Records

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

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) =>
          widget.viewModel ??
          AddRecordViewModel(
            initialDate: widget.selectedDate,
            recordService: ctx.read<HealthRecordService>(),
            onboardingService: ctx.read<OnboardingService>(),
          ),
      child: Scaffold(
        backgroundColor: AppColors.scaffoldBackground,
        appBar: HealthMateHeader.detail(
          title: 'Add Record',
          onBackPressed: () => _handleCancel(context),
        ),
        body: Consumer<AddRecordViewModel>(
          builder: (context, vm, _) {
            _syncControllers(vm);

            return SafeArea(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 20.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // Main Heading
                    const Text(
                      'Log your daily activity',
                      style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 4),
                    const Text(
                      'Record your steps, calories, and water intake.',
                      style: TextStyle(
                        fontSize: 14,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // 1. Date of Activity Card
                    _buildDateCard(context, vm),
                    const SizedBox(height: 16),

                    // 2. Steps Walked Card
                    _buildStepsCard(vm),
                    const SizedBox(height: 16),

                    // 3. Calories Burned Card
                    _buildCaloriesCard(vm),
                    const SizedBox(height: 16),

                    // 4. Water Intake Card
                    _buildWaterCard(vm),
                    const SizedBox(height: 24),

                    // Action Buttons (Cancel and Save Record)
                    _buildActionButtons(context, vm),
                    const SizedBox(height: 24),
                  ],
                ),
              ),
            );
          },
        ),
        bottomNavigationBar: HealthMateBottomNavigation(
          currentIndex: 1,
          onTap: (index) => _onBottomNavTap(context, index),
        ),
      ),
    );
  }

  // ================= 1. Date Card =================
  Widget _buildDateCard(BuildContext context, AddRecordViewModel vm) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 14.0),
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
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
          onTap: () => _pickDate(context, vm),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: const BoxDecoration(
                  color: AppColors.mintBadge,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.calendar_month_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Date of activity',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      vm.formattedDateOfActivity,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textPrimary,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ================= 2. Steps Card =================
  Widget _buildStepsCard(AddRecordViewModel vm) {
    final numberFormat = NumberFormat('#,###');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXXL),
        border: Border.all(color: AppColors.border.withAlpha(160)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.mintBadge,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.directions_walk_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Steps walked',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Enter the total steps you walked today.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Stepper Input Row
          Row(
            children: [
              // Numeric Pill Field
              Expanded(
                child: Container(
                  height: 52,
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF3F5F4),
                    borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                  ),
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _stepsController,
                          keyboardType: TextInputType.number,
                          inputFormatters: [
                            FilteringTextInputFormatter.digitsOnly,
                          ],
                          onChanged: (val) {
                            vm.setSteps(int.tryParse(val) ?? 0);
                          },
                          style: const TextStyle(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                          ),
                          decoration: const InputDecoration(
                            hintText: '0',
                            filled: false,
                            fillColor: Colors.transparent,
                            border: InputBorder.none,
                            enabledBorder: InputBorder.none,
                            focusedBorder: InputBorder.none,
                            contentPadding: EdgeInsets.zero,
                          ),
                        ),
                      ),
                      const Text(
                        'steps',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w500,
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Minus Button
              _buildMintStepperButton(
                icon: Icons.remove_rounded,
                onTap: () {
                  vm.decrementSteps(250);
                  _stepsController.text = vm.steps.toString();
                },
              ),
              const SizedBox(width: 8),

              // Plus Button
              _buildMintStepperButton(
                icon: Icons.add_rounded,
                onTap: () {
                  vm.incrementSteps(250);
                  _stepsController.text = vm.steps.toString();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Goal Status Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF6FAF8),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.verified_outlined,
                      size: 17,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Daily goal: ${numberFormat.format(vm.stepsGoal)} steps',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${vm.stepsProgressPercent}%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= 3. Calories Card =================
  Widget _buildCaloriesCard(AddRecordViewModel vm) {
    final numberFormat = NumberFormat('#,###');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXXL),
        border: Border.all(color: AppColors.border.withAlpha(160)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.mintBadge,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.local_fire_department_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Calories burned',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Enter your estimated active calories today.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Numeric Pill Input
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F5F4),
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _caloriesController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (val) {
                      vm.setCalories(int.tryParse(val) ?? 0);
                    },
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                    decoration: const InputDecoration(
                      hintText: '0',
                      filled: false,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const Text(
                  'kcal',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Goal Status Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF6FAF8),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.bolt_rounded,
                      size: 18,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Daily goal: ${numberFormat.format(vm.caloriesGoal)} kcal',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                const Text(
                  'Active burn',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= 4. Water Card =================
  Widget _buildWaterCard(AddRecordViewModel vm) {
    final numberFormat = NumberFormat('#,###');

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20.0),
      decoration: BoxDecoration(
        color: AppColors.cardBackground,
        borderRadius: BorderRadius.circular(AppDimensions.radiusXXL),
        border: Border.all(color: AppColors.border.withAlpha(160)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(6),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: const BoxDecoration(
                  color: AppColors.mintBadge,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.water_drop_rounded,
                  color: AppColors.primary,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: const [
                    Text(
                      'Water intake',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textPrimary,
                      ),
                    ),
                    SizedBox(height: 2),
                    Text(
                      'Track the water you drank today.',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // Numeric Pill Input
          Container(
            height: 52,
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF3F5F4),
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _waterController,
                    keyboardType: TextInputType.number,
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly,
                    ],
                    onChanged: (val) {
                      vm.setWater(int.tryParse(val) ?? 0);
                    },
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                    decoration: const InputDecoration(
                      hintText: '0',
                      filled: false,
                      fillColor: Colors.transparent,
                      border: InputBorder.none,
                      enabledBorder: InputBorder.none,
                      focusedBorder: InputBorder.none,
                      contentPadding: EdgeInsets.zero,
                    ),
                  ),
                ),
                const Text(
                  'ml',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: AppColors.textSecondary,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),

          // Quick-Add Buttons Row: +150ml, +250ml, +350ml, +500ml
          Row(
            children: [
              _buildWaterQuickAddChip(
                label: '+150 ml',
                onTap: () {
                  vm.addWater(150);
                  _waterController.text = vm.water.toString();
                },
              ),
              const SizedBox(width: 8),
              _buildWaterQuickAddChip(
                label: '+250 ml',
                onTap: () {
                  vm.addWater(250);
                  _waterController.text = vm.water.toString();
                },
              ),
              const SizedBox(width: 8),
              _buildWaterQuickAddChip(
                label: '+350 ml',
                onTap: () {
                  vm.addWater(350);
                  _waterController.text = vm.water.toString();
                },
              ),
              const SizedBox(width: 8),
              _buildWaterQuickAddChip(
                label: '+500 ml',
                onTap: () {
                  vm.addWater(500);
                  _waterController.text = vm.water.toString();
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Goal Status Banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14.0, vertical: 10.0),
            decoration: BoxDecoration(
              color: const Color(0xFFF6FAF8),
              borderRadius: BorderRadius.circular(AppDimensions.radiusM),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.water_drop_outlined,
                      size: 17,
                      color: AppColors.primary,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Daily goal: ${numberFormat.format(vm.waterGoalMl)} ml',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w500,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ],
                ),
                Text(
                  '${vm.waterProgressPercent}%',
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ================= Action Buttons =================
  Widget _buildActionButtons(BuildContext context, AddRecordViewModel vm) {
    return Row(
      children: [
        // Cancel Button
        Expanded(
          child: SizedBox(
            height: 52,
            child: OutlinedButton(
              onPressed: () => _handleCancel(context),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.primaryDark,
                side: const BorderSide(color: AppColors.border),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
                ),
              ),
              child: const Text(
                'Cancel',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),

        // Save Record Button
        Expanded(
          flex: 1,
          child: SizedBox(
            height: 52,
            child: ElevatedButton.icon(
              onPressed: vm.isSaving
                  ? null
                  : () async {
                      final success = await vm.saveRecord();
                      if (!context.mounted) return;

                      if (success) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Record saved successfully!'),
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
                    },
              icon: vm.isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                      ),
                    )
                  : const Icon(
                      Icons.check_circle_outline_rounded,
                      size: 19,
                    ),
              label: Text(
                vm.isSaving ? 'Saving...' : 'Save Record',
                style: const TextStyle(
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
        ),
      ],
    );
  }

  Widget _buildMintStepperButton({
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return Container(
      width: 44,
      height: 44,
      decoration: BoxDecoration(
        color: AppColors.mintBadge,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(AppDimensions.radiusM),
        child: InkWell(
          borderRadius: BorderRadius.circular(AppDimensions.radiusM),
          onTap: onTap,
          child: Center(
            child: Icon(
              icon,
              size: 20,
              color: AppColors.primaryDark,
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildWaterQuickAddChip({
    required String label,
    required VoidCallback onTap,
  }) {
    return Expanded(
      child: Container(
        height: 38,
        decoration: BoxDecoration(
          color: AppColors.mintBadge,
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
          child: InkWell(
            borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
            onTap: onTap,
            child: Center(
              child: Text(
                label,
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w700,
                  color: AppColors.primaryDark,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
