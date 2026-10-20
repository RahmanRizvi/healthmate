import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/widgets/goal_stepper_card.dart';
import '../../../core/widgets/healthmate_header.dart';
import '../../../core/widgets/onboarding_progress.dart';
import '../../../core/widgets/primary_button.dart';
import '../../../domain/services/onboarding_service.dart';
import '../../dashboard/views/dashboard_screen.dart';
import '../viewmodels/daily_goals_viewmodel.dart';

/// Screen 4: Daily Goals configuration and onboarding completion.
class DailyGoalsScreen extends StatelessWidget {
  final DailyGoalsViewModel? viewModel;

  const DailyGoalsScreen({super.key, this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) =>
          viewModel ??
          DailyGoalsViewModel(
            onboardingService: ctx.read<OnboardingService>(),
          ),
      child: Scaffold(
        appBar: HealthMateHeader(
          onBackPressed: () => Navigator.maybePop(context),
        ),
        body: SafeArea(
          child: Consumer<DailyGoalsViewModel>(
            builder: (context, vm, _) {
              return SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 12),

                    // Progress Indicator
                    const OnboardingProgress(
                      currentStep: 3,
                      stepTitle: 'Daily Goals',
                    ),
                    const SizedBox(height: 24),

                    // Heading
                    const Text(
                      'Set your daily goals',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: AppColors.primaryDark,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    const Text(
                      'Start small. You can adjust these targets anytime.',
                      style: TextStyle(
                        fontSize: 14.5,
                        color: AppColors.textSecondary,
                        fontWeight: FontWeight.w400,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Goal Card 1: Steps per day
                    GoalStepperCard(
                      icon: Icons.directions_walk_rounded,
                      title: 'Steps per day',
                      subtitle: 'Recommended baseline for active wellness',
                      value: vm.steps,
                      unit: 'steps',
                      step: 500,
                      minValue: 500,
                      onIncrement: vm.incrementSteps,
                      onDecrement: vm.decrementSteps,
                    ),
                    const SizedBox(height: 16),

                    // Goal Card 2: Water per day
                    GoalStepperCard(
                      icon: Icons.water_drop_outlined,
                      title: 'Water per day',
                      subtitle: 'About 8–10 glasses per day',
                      value: vm.waterMl,
                      unit: 'ml',
                      step: 250,
                      minValue: 250,
                      onIncrement: vm.incrementWater,
                      onDecrement: vm.decrementWater,
                    ),
                    const SizedBox(height: 16),

                    // Goal Card 3: Daily calories goal
                    GoalStepperCard(
                      icon: Icons.local_fire_department_outlined,
                      title: 'Daily calories goal',
                      subtitle: 'Suggested target (optional & customizable)',
                      isSubtitleHighlighted: true,
                      value: vm.caloriesKcal,
                      unit: 'kcal',
                      step: 50,
                      minValue: 50,
                      onIncrement: vm.incrementCalories,
                      onDecrement: vm.decrementCalories,
                      footerNote:
                          'Set an active calorie target that aligns with your current fitness level.',
                    ),
                    const SizedBox(height: 24),

                    // Disclaimer Note
                    const Center(
                      child: Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0),
                        child: Text(
                          'These are personal tracking goals, not medical recommendations.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 12.5,
                            color: AppColors.textSecondary,
                            height: 1.35,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Start HealthMate CTA Button
                    PrimaryButton(
                      text: 'Start HealthMate',
                      isLoading: vm.isLoading,
                      onPressed: () async {
                        final success = await vm.saveGoals();
                        if (!context.mounted) return;

                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Welcome to HealthMate!'),
                              backgroundColor: AppColors.primary,
                              duration: Duration(seconds: 2),
                            ),
                          );

                          Navigator.of(context).pushAndRemoveUntil(
                            MaterialPageRoute(
                              builder: (_) => const DashboardScreen(),
                            ),
                            (route) => false,
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
                    const SizedBox(height: 24),
                  ],
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}
