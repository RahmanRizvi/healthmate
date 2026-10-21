import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../../core/utils/age_calculator.dart';
import '../../../core/utils/unit_converter.dart';
import '../../../core/widgets/app_text_field.dart';
import '../../../core/widgets/confirmation_dialog.dart';
import '../../../core/widgets/healthmate_header.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../data/models/user_profile.dart';
import '../../../domain/services/onboarding_service.dart';

/// Screen allowing the user to update their saved profile.
class EditProfileScreen extends StatefulWidget {
  final UserProfile profile;
  final MeasurementUnitSystem unitSystem;

  const EditProfileScreen({
    super.key,
    required this.profile,
    required this.unitSystem,
  });

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _heightController;
  late TextEditingController _weightController;

  late DateTime _selectedDob;
  late String _selectedGender;
  bool _isSaving = false;
  bool _hasModified = false;

  final List<String> _genderOptions = [
    'Male',
    'Female',
    'Other',
    'Prefer not to say',
  ];

  @override
  void initState() {
    super.initState();
    _selectedDob = widget.profile.dateOfBirth;
    _selectedGender = widget.profile.gender;

    _nameController = TextEditingController(text: widget.profile.fullName);

    if (widget.unitSystem == MeasurementUnitSystem.metric) {
      _heightController = TextEditingController(
        text: widget.profile.heightCm.toStringAsFixed(0),
      );
      _weightController = TextEditingController(
        text: widget.profile.weightKg.toStringAsFixed(1),
      );
    } else {
      final inches = UnitConverter.cmToInches(widget.profile.heightCm);
      final lbs = UnitConverter.kgToLbs(widget.profile.weightKg);
      _heightController = TextEditingController(
        text: inches.toStringAsFixed(1),
      );
      _weightController = TextEditingController(
        text: lbs.toStringAsFixed(1),
      );
    }

    _nameController.addListener(_onFieldChanged);
    _heightController.addListener(_onFieldChanged);
    _weightController.addListener(_onFieldChanged);
  }

  void _onFieldChanged() {
    if (!_hasModified) {
      setState(() {
        _hasModified = true;
      });
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _heightController.dispose();
    _weightController.dispose();
    super.dispose();
  }

  int get _calculatedAge => AgeCalculator.calculateAge(_selectedDob);

  Future<void> _pickDateOfBirth() async {
    final now = DateTime.now();
    final firstDate = DateTime(now.year - 120, 1, 1);
    final lastDate = now;

    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDob.isBefore(lastDate) ? _selectedDob : DateTime(2000, 1, 1),
      firstDate: firstDate,
      lastDate: lastDate,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppColors.primary,
              onPrimary: Colors.white,
              surface: Theme.of(context).cardColor,
              onSurface: Theme.of(context).colorScheme.onSurface,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && picked != _selectedDob) {
      setState(() {
        _selectedDob = picked;
        _hasModified = true;
      });
    }
  }

  Future<bool> _onWillPop() async {
    if (!_hasModified) return true;

    final discard = await ConfirmationDialog.show(
      context: context,
      title: 'Discard Changes?',
      message: 'You have unsaved changes to your profile. Are you sure you want to discard them?',
      confirmLabel: 'Discard',
      cancelLabel: 'Keep Editing',
    );
    return discard;
  }

  Future<void> _saveProfile() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSaving = true;
    });

    try {
      final name = _nameController.text.trim();
      double parsedHeight = double.tryParse(_heightController.text.trim()) ?? 0.0;
      double parsedWeight = double.tryParse(_weightController.text.trim()) ?? 0.0;

      // Convert from imperial back to canonical metric if necessary
      double canonicalHeightCm = parsedHeight;
      double canonicalWeightKg = parsedWeight;

      if (widget.unitSystem == MeasurementUnitSystem.imperial) {
        canonicalHeightCm = parsedHeight * UnitConverter.cmPerInch;
        canonicalWeightKg = UnitConverter.lbsToKg(parsedWeight);
      }

      if (canonicalHeightCm <= 0 || canonicalWeightKg <= 0) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Please enter positive height and weight values.'),
            backgroundColor: Colors.redAccent,
          ),
        );
        setState(() => _isSaving = false);
        return;
      }

      final updatedProfile = widget.profile.copyWith(
        id: 1, // Single profile row
        fullName: name,
        dateOfBirth: _selectedDob,
        gender: _selectedGender,
        heightCm: double.parse(canonicalHeightCm.toStringAsFixed(1)),
        weightKg: double.parse(canonicalWeightKg.toStringAsFixed(1)),
        updatedAt: DateTime.now(),
      );

      final onboardingService = context.read<OnboardingService>();
      await onboardingService.saveProfile(updatedProfile);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Profile updated successfully'),
          backgroundColor: AppColors.statusSuccess,
          behavior: SnackBarBehavior.floating,
        ),
      );

      Navigator.of(context).pop(true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to update profile: $e'),
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
    final dobFormat = DateFormat('MMMM d, yyyy');

    final heightSuffix = widget.unitSystem == MeasurementUnitSystem.metric ? 'cm' : 'inches';
    final weightSuffix = widget.unitSystem == MeasurementUnitSystem.metric ? 'kg' : 'lbs';

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
          title: 'Edit Profile',
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
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Update Personal Details',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: isDark ? AppColors.mint : AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Changes will update your BMI and activity metrics across HealthMate.',
                    style: TextStyle(
                      fontSize: 13.5,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 20),

                  // Full Name
                  AppTextField(
                    label: 'Full Name',
                    hintText: 'e.g. Alex Morgan',
                    controller: _nameController,
                    prefixIcon: const Icon(Icons.person_outline_rounded),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your full name';
                      }
                      if (value.trim().length < 2) {
                        return 'Name must be at least 2 characters';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Date of Birth & Calculated Age
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Date of Birth',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      InkWell(
                        onTap: _pickDateOfBirth,
                        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 14,
                          ),
                          decoration: BoxDecoration(
                            color: isDark
                                ? AppColors.inputBackgroundDark
                                : AppColors.inputBackground,
                            borderRadius:
                                BorderRadius.circular(AppDimensions.radiusL),
                            border: Border.all(
                              color: isDark ? AppColors.borderDark : AppColors.border,
                            ),
                          ),
                          child: Row(
                            children: [
                              Icon(
                                Icons.calendar_today_rounded,
                                size: 20,
                                color: isDark ? AppColors.mint : AppColors.primary,
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  dobFormat.format(_selectedDob),
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w500,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? AppColors.pillBackgroundDark
                                      : AppColors.mintSoft,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  '$_calculatedAge yrs',
                                  style: TextStyle(
                                    fontSize: 12.5,
                                    fontWeight: FontWeight.w700,
                                    color: isDark ? AppColors.mint : AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Gender Dropdown
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Gender',
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        decoration: BoxDecoration(
                          color: isDark
                              ? AppColors.inputBackgroundDark
                              : AppColors.inputBackground,
                          borderRadius: BorderRadius.circular(AppDimensions.radiusL),
                          border: Border.all(
                            color: isDark ? AppColors.borderDark : AppColors.border,
                          ),
                        ),
                        child: DropdownButtonHideUnderline(
                          child: DropdownButton<String>(
                            value: _genderOptions.contains(_selectedGender)
                                ? _selectedGender
                                : _genderOptions.first,
                            isExpanded: true,
                            dropdownColor: isDark
                                ? AppColors.cardBackgroundDark
                                : AppColors.cardBackground,
                            items: _genderOptions.map((String gender) {
                              return DropdownMenuItem<String>(
                                value: gender,
                                child: Text(
                                  gender,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              );
                            }).toList(),
                            onChanged: (newGender) {
                              if (newGender != null && newGender != _selectedGender) {
                                setState(() {
                                  _selectedGender = newGender;
                                  _hasModified = true;
                                });
                              }
                            },
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Height
                  AppTextField(
                    label: 'Height ($heightSuffix)',
                    hintText: widget.unitSystem == MeasurementUnitSystem.metric
                        ? 'e.g. 178'
                        : 'e.g. 70.1',
                    controller: _heightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: const Icon(Icons.height_rounded),
                    suffixText: heightSuffix,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter height';
                      }
                      final numVal = double.tryParse(value.trim());
                      if (numVal == null || numVal <= 0) {
                        return 'Enter a positive number';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Weight
                  AppTextField(
                    label: 'Weight ($weightSuffix)',
                    hintText: widget.unitSystem == MeasurementUnitSystem.metric
                        ? 'e.g. 72.4'
                        : 'e.g. 159.6',
                    controller: _weightController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    prefixIcon: const Icon(Icons.monitor_weight_outlined),
                    suffixText: weightSuffix,
                    inputFormatters: [
                      FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d*')),
                    ],
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter weight';
                      }
                      final numVal = double.tryParse(value.trim());
                      if (numVal == null || numVal <= 0) {
                        return 'Enter a positive number';
                      }
                      return null;
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
                          onPressed: _saveProfile,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
