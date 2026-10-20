import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/healthmate_header.dart';
import '../../../core/widgets/info_banner.dart';
import '../../../core/widgets/onboarding_progress.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../domain/services/onboarding_service.dart';
import '../viewmodels/personal_details_viewmodel.dart';
import 'bmi_analysis_screen.dart';

/// Screen 2: Personal Details entry and validation.
class PersonalDetailsScreen extends StatefulWidget {
  final PersonalDetailsViewModel? viewModel;

  const PersonalDetailsScreen({super.key, this.viewModel});

  @override
  State<PersonalDetailsScreen> createState() => _PersonalDetailsScreenState();
}

class _PersonalDetailsScreenState extends State<PersonalDetailsScreen> {
  late final TextEditingController _nameController;
  late final TextEditingController _dobController;
  late final TextEditingController _heightController;
  late final TextEditingController _weightController;

  @override
  void initState({PersonalDetailsViewModel? viewModel}) {
    super.initState();
    _nameController = TextEditingController();
    _dobController = TextEditingController();
    _heightController = TextEditingController();
    _weightController = TextEditingController();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _dobController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  void _syncControllers(PersonalDetailsViewModel vm) {
    if (_nameController.text != vm.fullName && vm.fullName.isNotEmpty) {
      _nameController.text = vm.fullName;
    }
    if (vm.dateOfBirth != null) {
      final formatted = DateFormat('dd MMMM yyyy').format(vm.dateOfBirth!);
      if (_dobController.text != formatted) {
        _dobController.text = formatted;
      }
    }
    if (vm.heightCm != null && _heightController.text.isEmpty) {
      _heightController.text = vm.heightCm!.toStringAsFixed(0);
    }
    if (vm.weightKg != null && _weightController.text.isEmpty) {
      _weightController.text = vm.weightKg!.toStringAsFixed(0);
    }
  }

  Future<void> _pickDateOfBirth(
    BuildContext context,
    PersonalDetailsViewModel vm,
  ) async {
    final now = DateTime.now();
    final initialDate = vm.dateOfBirth ?? DateTime(1998, 5, 14);
    final firstDate = DateTime(1920);
    final lastDate = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: initialDate.isBefore(lastDate) ? initialDate : lastDate,
      firstDate: firstDate,
      lastDate: lastDate,
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
      vm.setDateOfBirth(picked);
      _dobController.text = DateFormat('dd MMMM yyyy').format(picked);
    }
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) =>
          widget.viewModel ??
          PersonalDetailsViewModel(
            onboardingService: ctx.read<OnboardingService>(),
          ),
      child: Consumer<PersonalDetailsViewModel>(
        builder: (context, vm, _) {
          _syncControllers(vm);

          return Scaffold(
            appBar: HealthMateHeader(
              onBackPressed: () => Navigator.maybePop(context),
            ),
            body: SafeArea(
              child: LayoutBuilder(
                builder: (context, constraints) {
                  return SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: ConstrainedBox(
                      constraints: BoxConstraints(
                        minHeight: constraints.maxHeight,
                      ),
                      child: IntrinsicHeight(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const SizedBox(height: 12),

                            // Progress Indicator
                            const OnboardingProgress(
                              currentStep: 1,
                              stepTitle: 'Personal Details',
                            ),
                            const SizedBox(height: 24),

                            // Heading
                            const Text(
                              "Let's get to know you",
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w800,
                                color: AppColors.primaryDark,
                                letterSpacing: -0.6,
                              ),
                            ),
                            const SizedBox(height: 6),
                            const Text(
                              'Personalize your wellness journey.',
                              style: TextStyle(
                                fontSize: 14.5,
                                color: AppColors.textSecondary,
                                fontWeight: FontWeight.w400,
                              ),
                            ),
                            const SizedBox(height: 24),

                            // Full Name Input
                            AppTextField(
                              label: 'Full Name',
                              hintText: 'Alex Morgan',
                              controller: _nameController,
                              isValid: vm.isFullNameValid,
                              onChanged: vm.setFullName,
                              keyboardType: TextInputType.name,
                            ),
                            const SizedBox(height: 18),

                            // Date of Birth Input
                            AppTextField(
                              label: 'Date of Birth',
                              hintText: '14 May 1998',
                              controller: _dobController,
                              readOnly: true,
                              onTap: () => _pickDateOfBirth(context, vm),
                              prefixIcon: const Icon(
                                Icons.calendar_today_outlined,
                                color: AppColors.textSecondary,
                                size: 20,
                              ),
                            ),
                            const SizedBox(height: 12),

                            // Calculated Age Banner with Lock Icon
                            InfoBanner.age(
                              ageLabel: vm.dateOfBirth != null
                                  ? 'Age: ${vm.age ?? 0} years'
                                  : 'Age: --',
                            ),
                            const SizedBox(height: 18),

                            // Gender Dropdown
                            _buildGenderDropdown(vm),
                            const SizedBox(height: 18),

                            // Height & Weight Row
                            Row(
                              children: [
                                Expanded(
                                  child: AppTextField(
                                    label: 'Height',
                                    hintText: '172',
                                    controller: _heightController,
                                    suffixText: 'cm',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d*'),
                                      ),
                                    ],
                                    onChanged: vm.setHeight,
                                  ),
                                ),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: AppTextField(
                                    label: 'Weight',
                                    hintText: '68',
                                    controller: _weightController,
                                    suffixText: 'kg',
                                    keyboardType:
                                        const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                    inputFormatters: [
                                      FilteringTextInputFormatter.allow(
                                        RegExp(r'^\d*\.?\d*'),
                                      ),
                                    ],
                                    onChanged: vm.setWeight,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 22),

                            // Information Note
                            InfoBanner.neutral(
                              message:
                                  'Your details help personalize your wellness experience.',
                            ),

                            const Spacer(),
                            const SizedBox(height: 24),

                            // Continue Button
                            PrimaryButton(
                              text: 'Continue',
                              isLoading: vm.isLoading,
                              onPressed: () async {
                                final success = await vm.saveProfile();
                                if (!context.mounted) return;

                                if (success) {
                                  Navigator.of(context).push(
                                    MaterialPageRoute(
                                      builder: (_) => const BmiAnalysisScreen(),
                                    ),
                                  );
                                } else if (vm.errorMessage != null) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(vm.errorMessage!),
                                      backgroundColor: AppColors.primaryDark,
                                    ),
                                  );
                                }
                              },
                            ),
                            const SizedBox(height: 16),
                          ],
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildGenderDropdown(PersonalDetailsViewModel vm) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Gender',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            border: Border.all(color: AppColors.border),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: vm.gender,
              isExpanded: true,
              icon: const Icon(
                Icons.keyboard_arrow_down_rounded,
                color: AppColors.textPrimary,
                size: 24,
              ),
              items: vm.genderOptions.map((String value) {
                return DropdownMenuItem<String>(
                  value: value,
                  child: Text(
                    value,
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w500,
                      color: AppColors.textPrimary,
                    ),
                  ),
                );
              }).toList(),
              onChanged: (val) {
                if (val != null) {
                  vm.setGender(val);
                }
              },
            ),
          ),
        ),
      ],
    );
  }
}
