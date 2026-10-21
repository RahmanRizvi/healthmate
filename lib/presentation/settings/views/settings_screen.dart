import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/preferences/app_preferences.dart';
import '../../../core/services/notification_service.dart';
import '../../../core/theme/theme_controller.dart';
import '../../../core/utils/bmi_calculator.dart';
import '../../../core/utils/unit_converter.dart';
import '../../../core/widgets/bottom_navigation.dart';
import '../../../core/widgets/healthmate_header.dart';
import '../../../data/models/daily_goals.dart';
import '../../../domain/services/bmi_service.dart';
import '../../../domain/services/onboarding_service.dart';
import '../../progress/views/progress_screen.dart';
import '../../records/views/add_record_screen.dart';
import '../../records/views/records_screen.dart';
import '../viewmodels/settings_viewmodel.dart';
import 'about_screen.dart';
import 'bmi_details_screen.dart';
import 'edit_goals_screen.dart';
import 'edit_profile_screen.dart';
import 'privacy_security_screen.dart';
import 'terms_of_service_screen.dart';
import 'weekly_digest_screen.dart';

/// Complete Settings screen reproducing the HealthMate design specifications.
class SettingsScreen extends StatefulWidget {
  final SettingsViewModel? viewModel;

  const SettingsScreen({super.key, this.viewModel});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  SettingsViewModel? _internalViewModel;
  String _appVersion = '1.4.2';

  SettingsViewModel get _vm => widget.viewModel ?? _internalViewModel!;

  @override
  void initState() {
    super.initState();
    _loadAppVersion();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (widget.viewModel == null && _internalViewModel == null) {
      final onboardingService = context.read<OnboardingService>();
      final bmiService = context.read<BmiService>();
      final preferences = context.read<AppPreferences>();
      final themeController = context.read<ThemeController>();
      final notificationService = context.read<NotificationService>();

      _internalViewModel = SettingsViewModel(
        onboardingService: onboardingService,
        bmiService: bmiService,
        preferences: preferences,
        themeController: themeController,
        notificationService: notificationService,
      );

      _internalViewModel!.loadSettings();
    }
  }

  Future<void> _loadAppVersion() async {
    try {
      final info = await PackageInfo.fromPlatform();
      if (mounted && info.version.isNotEmpty) {
        setState(() {
          _appVersion = info.version;
        });
      }
    } catch (_) {}
  }

  void _onBottomNavTap(int index) {
    if (index == 3) return; // already in Settings

    if (index == 0) {
      Navigator.of(context).pop();
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

  Future<void> _navigateToAddRecord() async {
    await Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => AddRecordScreen(selectedDate: DateTime.now()),
      ),
    );
  }

  Future<void> _openEditProfile() async {
    final profile = _vm.profile;
    if (profile == null) return;

    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditProfileScreen(
          profile: profile,
          unitSystem: _vm.measurementUnit,
        ),
      ),
    );

    if (updated == true) {
      await _vm.loadSettings();
    }
  }

  Future<void> _openEditGoals() async {
    final goals = _vm.goals;
    if (goals == null) return;

    final updated = await Navigator.of(context).push<bool>(
      MaterialPageRoute(
        builder: (_) => EditGoalsScreen(
          goals: goals,
          unitSystem: _vm.measurementUnit,
        ),
      ),
    );

    if (updated == true) {
      await _vm.loadSettings();
    }
  }

  void _openBmiDetails() {
    final profile = _vm.profile;
    final bmi = _vm.bmiResult;
    if (profile == null || bmi == null) return;

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => BmiDetailsScreen(
          bmiResult: bmi,
          heightCm: profile.heightCm,
          weightKg: profile.weightKg,
          age: profile.age,
        ),
      ),
    );
  }

  void _openWeeklyDigest() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => WeeklyDigestScreen(unitSystem: _vm.measurementUnit),
      ),
    );
  }

  void _openAbout() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const AboutScreen()),
    );
  }

  void _openPrivacy() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const PrivacySecurityScreen()),
    );
  }

  void _openTerms() {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => const TermsOfServiceScreen()),
    );
  }

  void _showUnitPicker() {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      backgroundColor: theme.scaffoldBackgroundColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Select Measurement Units',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                    color: isDark ? AppColors.mint : AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Choose your preferred measurement system. Canonical records remain intact in your database.',
                  style: TextStyle(
                    fontSize: 13,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 18),
                ListTile(
                  title: const Text('Metric (cm, kg, ml)'),
                  subtitle: const Text('Standard international metric system'),
                  leading: Icon(
                    _vm.measurementUnit == MeasurementUnitSystem.metric
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: _vm.measurementUnit == MeasurementUnitSystem.metric
                        ? AppColors.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  onTap: () {
                    _vm.setMeasurementUnit(MeasurementUnitSystem.metric);
                    Navigator.of(ctx).pop();
                  },
                ),
                ListTile(
                  title: const Text('Imperial (ft, lbs, fl oz)'),
                  subtitle: const Text('US / Imperial measurement system'),
                  leading: Icon(
                    _vm.measurementUnit == MeasurementUnitSystem.imperial
                        ? Icons.radio_button_checked_rounded
                        : Icons.radio_button_unchecked_rounded,
                    color: _vm.measurementUnit == MeasurementUnitSystem.imperial
                        ? AppColors.primary
                        : theme.colorScheme.onSurfaceVariant,
                  ),
                  onTap: () {
                    _vm.setMeasurementUnit(MeasurementUnitSystem.imperial);
                    Navigator.of(ctx).pop();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _vm,
      builder: (context, _) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Scaffold(
          backgroundColor: theme.scaffoldBackgroundColor,
          appBar: HealthMateHeader.dashboard(
            onAddPressed: _navigateToAddRecord,
          ),
          body: _vm.isLoading
              ? const Center(
                  child: CircularProgressIndicator(color: AppColors.primary),
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
                      // Screen Title & Subtitle
                      Text(
                        'Settings',
                        style: TextStyle(
                          fontSize: 26,
                          fontWeight: FontWeight.w800,
                          color: isDark ? AppColors.mint : AppColors.primaryDark,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Manage your profile and preferences.',
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 18),

                      // Card 1: User Profile Card
                      _buildProfileCard(context),
                      const SizedBox(height: 18),

                      // Card 2: Body Mass Index (BMI) Card
                      _buildBmiCard(context),
                      const SizedBox(height: 18),

                      // Card 3: Daily Goals Card
                      _buildDailyGoalsCard(context),
                      const SizedBox(height: 18),

                      // Card 4: Preferences Card
                      _buildPreferencesCard(context),
                      const SizedBox(height: 18),

                      // Card 5: About HealthMate Card
                      _buildAboutCard(context),
                      const SizedBox(height: 18),

                      // Card 6: Legal & Data Security Card
                      _buildLegalSecurityCard(context),
                      const SizedBox(height: 30),
                    ],
                  ),
                ),
          bottomNavigationBar: HealthMateBottomNavigation(
            currentIndex: 3,
            onTap: _onBottomNavTap,
          ),
        );
      },
    );
  }

  // ================= Profile Card =================
  Widget _buildProfileCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final profile = _vm.profile;

    if (profile == null) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.all(20),
        decoration: _cardDecoration(context),
        child: Column(
          children: [
            const Icon(Icons.person_off_outlined, size: 36, color: AppColors.textMuted),
            const SizedBox(height: 8),
            const Text(
              'No profile found',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 4),
            const Text(
              'Please complete onboarding or set up your profile.',
              style: TextStyle(fontSize: 13, color: AppColors.textSecondary),
            ),
          ],
        ),
      );
    }

    final heightSplit = UnitConverter.splitHeight(profile.heightCm, _vm.measurementUnit);
    final weightSplit = UnitConverter.splitWeight(profile.weightKg, _vm.measurementUnit);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Avatar, Name & Age Pill, Edit Button
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Initials Avatar
              Container(
                width: 52,
                height: 52,
                decoration: const BoxDecoration(
                  color: AppColors.mint,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Text(
                    _vm.initials,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Name & Gender/Age Pill
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      profile.fullName,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: theme.colorScheme.onSurface,
                        letterSpacing: -0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 3),
                      decoration: BoxDecoration(
                        color: isDark ? AppColors.pillBackgroundDark : AppColors.infoBannerBackground,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${profile.gender} • ${profile.age} yrs',
                        style: TextStyle(
                          fontSize: 11.5,
                          fontWeight: FontWeight.w600,
                          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),

              // Edit Button
              InkWell(
                key: const Key('edit_profile_button'),
                onTap: _openEditProfile,
                borderRadius: BorderRadius.circular(20),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.pillBackgroundDark : AppColors.mintBadge,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.edit_outlined,
                        size: 14,
                        color: isDark ? AppColors.mint : AppColors.primary,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'Edit',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.mint : AppColors.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 18),

          // 4 Sub-boxes: Height, Weight, Gender, Age
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  label: 'Height',
                  value: heightSplit.value,
                  unit: heightSplit.unit,
                  context: context,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildMetricTile(
                  label: 'Weight',
                  value: weightSplit.value,
                  unit: weightSplit.unit,
                  context: context,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildMetricTile(
                  label: 'Gender',
                  value: profile.gender,
                  unit: '',
                  context: context,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                child: _buildMetricTile(
                  label: 'Age',
                  value: '${profile.age}',
                  unit: 'y',
                  context: context,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required String unit,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 2),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardElevatedDark : const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 4),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(
                  value,
                  style: TextStyle(
                    fontSize: value.length > 5 ? 12.0 : 14.5,
                    fontWeight: FontWeight.w800,
                    color: isDark ? AppColors.mint : AppColors.primaryDark,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (unit.isNotEmpty) ...[
                const SizedBox(width: 1),
                Text(
                  unit,
                  style: TextStyle(
                    fontSize: 9.0,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ================= BMI Card =================
  Widget _buildBmiCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bmi = _vm.bmiResult ?? BmiResult.empty();
    final profile = _vm.profile;

    final heightStr = profile != null
        ? UnitConverter.formatHeight(profile.heightCm, _vm.measurementUnit)
        : '--';
    final weightStr = profile != null
        ? UnitConverter.formatWeight(profile.weightKg, _vm.measurementUnit)
        : '--';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Top Row: Icon, Title, Badge
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: isDark ? AppColors.pillBackgroundDark : AppColors.mintBadge,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.speed_rounded,
                  color: isDark ? AppColors.mint : AppColors.primary,
                  size: 18,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Body Mass Index',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.pillBackgroundDark : const Color(0xFFD1FAE5),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 6,
                      height: 6,
                      decoration: BoxDecoration(
                        color: bmi.category.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${bmi.category == BmiCategory.normal ? "Normal" : bmi.categoryLabel} (${bmi.bmi.toStringAsFixed(1)})',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: isDark ? AppColors.mint : bmi.category.color,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Big BMI Value
          Row(
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                bmi.bmi > 0 ? bmi.bmi.toStringAsFixed(1) : '--',
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.mint : AppColors.primaryDark,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(width: 6),
              Text(
                'kg/m²',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),

          // Spectrum Pointer + Bar
          _buildBmiSpectrum(context, bmi.gaugePosition),
          const SizedBox(height: 8),

          // Range labels below spectrum bar
          Row(
            children: [
              Expanded(
                child: Align(
                  alignment: Alignment.centerLeft,
                  child: _buildRangeLabel('< 18.5', bmi.category == BmiCategory.underweight, context),
                ),
              ),
              Expanded(
                child: Center(
                  child: _buildRangeLabel('18.5 - 24.9', bmi.category == BmiCategory.normal, context),
                ),
              ),
              Expanded(
                child: Center(
                  child: _buildRangeLabel('25 - 29.9', bmi.category == BmiCategory.overweight, context),
                ),
              ),
              Expanded(
                child: Align(
                  alignment: Alignment.centerRight,
                  child: _buildRangeLabel('30+', bmi.category == BmiCategory.obese, context),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          // Bottom Row: "Based on 178 cm & 72.4 kg" + "Details >"
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  'Based on $heightStr & $weightStr',
                  style: TextStyle(
                    fontSize: 11.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 8),
              InkWell(
                key: const Key('bmi_details_button'),
                onTap: _openBmiDetails,
                borderRadius: BorderRadius.circular(4),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 4),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Details',
                        style: TextStyle(
                          fontSize: 12.5,
                          fontWeight: FontWeight.w700,
                          color: isDark ? AppColors.mint : AppColors.primary,
                        ),
                      ),
                      Icon(
                        Icons.chevron_right_rounded,
                        size: 16,
                        color: isDark ? AppColors.mint : AppColors.primary,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBmiSpectrum(BuildContext context, double gaugePosition) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final pointerX = (gaugePosition * (width - 12)).clamp(0.0, width - 12);

        return Column(
          children: [
            // Downward Pointer
            SizedBox(
              height: 10,
              width: width,
              child: Stack(
                children: [
                  Positioned(
                    left: pointerX,
                    child: const Icon(
                      Icons.arrow_drop_down_rounded,
                      color: AppColors.statusSuccess,
                      size: 18,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 2),

            // Horizontal 4-Segment Spectrum Bar
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: SizedBox(
                height: 8,
                width: width,
                child: Row(
                  children: [
                    Expanded(
                      flex: 25,
                      child: Container(color: AppColors.bmiUnderweight),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      flex: 25,
                      child: Container(color: AppColors.bmiNormal),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      flex: 25,
                      child: Container(color: AppColors.bmiOverweight),
                    ),
                    const SizedBox(width: 2),
                    Expanded(
                      flex: 25,
                      child: Container(color: AppColors.bmiObese),
                    ),
                  ],
                ),
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildRangeLabel(String text, bool isHighlighted, BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Text(
      text,
      style: TextStyle(
        fontSize: 10,
        fontWeight: isHighlighted ? FontWeight.w800 : FontWeight.w500,
        color: isHighlighted
            ? (isDark ? AppColors.mint : AppColors.primary)
            : theme.colorScheme.onSurfaceVariant,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  // ================= Daily Goals Card =================
  Widget _buildDailyGoalsCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final goals = _vm.goals ?? DailyGoals.defaults();
    final numberFormat = NumberFormat('#,###');

    final waterSplit = UnitConverter.splitWater(goals.waterGoalMl, _vm.measurementUnit);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with Edit Icon
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily goals',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Targets for dashboard metrics',
                      style: TextStyle(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                key: const Key('edit_goals_button'),
                icon: const Icon(Icons.edit_outlined, size: 20),
                color: isDark ? AppColors.mint : AppColors.textSecondary,
                onPressed: _openEditGoals,
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Steps Goal Row
          _buildGoalRow(
            icon: Icons.directions_walk_rounded,
            iconColor: const Color(0xFF047857),
            iconBg: const Color(0xFFB7F7DE),
            title: 'Steps per day',
            subtitle: 'Daily activity marker',
            valueString: numberFormat.format(goals.stepsGoal),
            unitString: '',
            context: context,
          ),
          const SizedBox(height: 12),

          // Water Goal Row
          _buildGoalRow(
            icon: Icons.water_drop_rounded,
            iconColor: const Color(0xFF0284C7),
            iconBg: const Color(0xFFE0F2FE),
            title: 'Water intake',
            subtitle: 'Hydration target',
            valueString: numberFormat.format(int.tryParse(waterSplit.value) ?? goals.waterGoalMl),
            unitString: waterSplit.unit,
            context: context,
          ),
          const SizedBox(height: 12),

          // Calorie Goal Row
          _buildGoalRow(
            icon: Icons.local_fire_department_rounded,
            iconColor: const Color(0xFFD97706),
            iconBg: const Color(0xFFFEF3C7),
            title: 'Active burn',
            subtitle: 'Movement energy',
            valueString: numberFormat.format(goals.caloriesGoalKcal),
            unitString: 'kcal',
            context: context,
          ),
        ],
      ),
    );
  }

  Widget _buildGoalRow({
    required IconData icon,
    required Color iconColor,
    required Color iconBg,
    required String title,
    required String subtitle,
    required String valueString,
    required String unitString,
    required BuildContext context,
  }) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardElevatedDark : const Color(0xFFF8FAF9),
        borderRadius: BorderRadius.circular(AppDimensions.radiusL),
        border: Border.all(
          color: isDark ? AppColors.borderDark : AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: isDark ? iconColor.withAlpha(40) : iconBg,
              shape: BoxShape.circle,
            ),
            child: Icon(
              icon,
              color: isDark ? AppColors.mint : iconColor,
              size: 20,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  subtitle,
                  style: TextStyle(
                    fontSize: 11.5,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Text(
                valueString,
                style: TextStyle(
                  fontSize: 15.5,
                  fontWeight: FontWeight.w800,
                  color: isDark ? AppColors.mint : AppColors.primaryDark,
                ),
              ),
              if (unitString.isNotEmpty) ...[
                const SizedBox(width: 3),
                Text(
                  unitString,
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w500,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // ================= Preferences Card =================
  Widget _buildPreferencesCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: _cardDecoration(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Preferences',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 14),

          // Daily Reminders Row
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Daily reminders',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Hydration & check-in alerts',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
              Switch(
                key: const Key('daily_reminders_switch'),
                value: _vm.dailyRemindersEnabled,
                activeThumbColor: Colors.white,
                activeTrackColor: AppColors.accentGreen,
                onChanged: (val) async {
                  final messenger = ScaffoldMessenger.of(context);
                  final success = await _vm.setDailyRemindersEnabled(val);
                  if (!success && mounted) {
                    messenger.showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Notification permission was denied. Please allow notifications in device settings.',
                        ),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Measurement Units Row
          InkWell(
            key: const Key('measurement_units_tile'),
            onTap: _showUnitPicker,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Measurement units',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _vm.measurementUnit == MeasurementUnitSystem.metric
                              ? 'Standard metric system'
                              : 'Imperial measurement system',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardElevatedDark : const Color(0xFFF1F5F3),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          _vm.measurementUnit.label,
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(width: 3),
                        Icon(
                          Icons.chevron_right_rounded,
                          size: 16,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Weekly Health Digest Row
          InkWell(
            key: const Key('weekly_digest_tile'),
            onTap: _openWeeklyDigest,
            borderRadius: BorderRadius.circular(10),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Weekly health digest',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Summary insights every Monday',
                          style: TextStyle(
                            fontSize: 11.5,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Switch(
                    key: const Key('weekly_digest_switch'),
                    value: _vm.weeklyDigestEnabled,
                    activeThumbColor: Colors.white,
                    activeTrackColor: AppColors.accentGreen,
                    onChanged: (val) async {
                      final messenger = ScaffoldMessenger.of(context);
                      final success = await _vm.setWeeklyDigestEnabled(val);
                      if (!success && mounted) {
                        messenger.showSnackBar(
                          const SnackBar(
                            content: Text(
                              'Notification permission was denied. Please allow notifications in device settings.',
                            ),
                          ),
                        );
                      }
                    },
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ================= About Card =================
  Widget _buildAboutCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return InkWell(
      key: const Key('about_card_tap'),
      onTap: _openAbout,
      borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(16),
        decoration: _cardDecoration(context),
        child: Row(
          children: [
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/logo.png',
                height: 36,
                width: 36,
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) => Container(
                  width: 36,
                  height: 36,
                  decoration: const BoxDecoration(
                    color: AppColors.mintBadge,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.favorite_rounded,
                    color: AppColors.primary,
                    size: 20,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          'HealthMate',
                          style: TextStyle(
                            fontSize: 15.5,
                            fontWeight: FontWeight.w800,
                            color: theme.colorScheme.onSurface,
                            letterSpacing: -0.3,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.cardElevatedDark : const Color(0xFFF1F5F3),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Text(
                          'v$_appVersion',
                          style: TextStyle(
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Mindful vitality companion',
                    style: TextStyle(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            Icon(
              Icons.chevron_right_rounded,
              color: theme.colorScheme.onSurfaceVariant,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }

  // ================= Legal & Security Card =================
  Widget _buildLegalSecurityCard(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: _cardDecoration(context),
      child: Column(
        children: [
          // Privacy Row
          InkWell(
            key: const Key('privacy_security_tile'),
            onTap: _openPrivacy,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Privacy & Data Security',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const Divider(height: 14),

          // Terms Row
          InkWell(
            key: const Key('terms_of_service_tile'),
            onTap: _openTerms,
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      'Terms of Service',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                  ),
                  Icon(
                    Icons.chevron_right_rounded,
                    color: theme.colorScheme.onSurfaceVariant,
                    size: 20,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),

          // Storage disclosure banner
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isDark ? AppColors.cardElevatedDark : const Color(0xFFF1F5F3),
              borderRadius: BorderRadius.circular(AppDimensions.radiusL),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(
                  Icons.lock_rounded,
                  size: 16,
                  color: AppColors.statusSuccess,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Your health data is securely encrypted on this device. HealthMate never sells personal metrics.',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: theme.colorScheme.onSurfaceVariant,
                      height: 1.35,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  BoxDecoration _cardDecoration(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return BoxDecoration(
      color: isDark ? AppColors.cardBackgroundDark : AppColors.cardBackground,
      borderRadius: BorderRadius.circular(AppDimensions.radiusXL),
      border: Border.all(
        color: isDark ? AppColors.borderDark : AppColors.border.withAlpha(160),
      ),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withAlpha(isDark ? 24 : 6),
          blurRadius: 10,
          offset: const Offset(0, 3),
        ),
      ],
    );
  }
}
