import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../domain/services/onboarding_service.dart';
import '../../dashboard/views/dashboard_screen.dart';
import '../../onboarding/views/bmi_analysis_screen.dart';
import '../../onboarding/views/daily_goals_screen.dart';
import '../../onboarding/views/personal_details_screen.dart';
import '../../onboarding/views/welcome_screen.dart';

/// Branded splash screen displaying the HealthMate logo, title, and tagline with smooth animation.
class SplashScreen extends StatefulWidget {
  final Duration minDisplayDuration;

  const SplashScreen({
    super.key,
    this.minDisplayDuration = const Duration(milliseconds: 1400),
  });

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnimation;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    );

    _scaleAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeOutBack,
    );

    _fadeAnimation = CurvedAnimation(
      parent: _animController,
      curve: Curves.easeIn,
    );

    _animController.forward();
    _resolveStartupNavigation();
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _resolveStartupNavigation() async {
    final stopwatch = Stopwatch()..start();

    OnboardingResumeStep resumeStep = OnboardingResumeStep.welcome;
    try {
      final onboardingService =
          Provider.of<OnboardingService>(context, listen: false);
      resumeStep = await onboardingService.getResumeStep();
    } catch (e) {
      debugPrint('SplashScreen startup error: $e');
    }

    // Ensure the splash is visible long enough for a smooth, premium brand impression
    final elapsed = stopwatch.elapsed;
    if (elapsed < widget.minDisplayDuration) {
      await Future.delayed(widget.minDisplayDuration - elapsed);
    }

    if (!mounted) return;

    final targetScreen = _getTargetScreen(resumeStep);

    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, animation, secondaryAnimation) => targetScreen,
        transitionsBuilder: (context, animation, secondaryAnimation, child) {
          return FadeTransition(opacity: animation, child: child);
        },
        transitionDuration: const Duration(milliseconds: 400),
      ),
    );
  }

  Widget _getTargetScreen(OnboardingResumeStep resumeStep) {
    switch (resumeStep) {
      case OnboardingResumeStep.completed:
        return const DashboardScreen();
      case OnboardingResumeStep.bmiAnalysis:
        return const BmiAnalysisScreen();
      case OnboardingResumeStep.dailyGoals:
        return const DailyGoalsScreen();
      case OnboardingResumeStep.personalDetails:
        return const PersonalDetailsScreen();
      case OnboardingResumeStep.welcome:
        return const WelcomeScreen();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? AppColors.scaffoldBackgroundDark : const Color(0xFFF5FAF7),
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),

              // Animated Logo Container
              ScaleTransition(
                scale: _scaleAnimation,
                child: FadeTransition(
                  opacity: _fadeAnimation,
                  child: Container(
                    width: 130,
                    height: 130,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardElevatedDark : Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withAlpha(isDark ? 30 : 25),
                          blurRadius: 28,
                          offset: const Offset(0, 10),
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: Image.asset(
                        'assets/images/logo.png',
                        fit: BoxFit.contain,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                          Icons.favorite_rounded,
                          size: 64,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 28),

              // App Name & Tagline
              FadeTransition(
                opacity: _fadeAnimation,
                child: Column(
                  children: [
                    Text(
                      'HealthMate',
                      style: TextStyle(
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppColors.mint : AppColors.primaryDark,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Mindful vitality companion',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),

              const Spacer(flex: 3),

              // Bottom Brand Loading Indicator
              FadeTransition(
                opacity: _fadeAnimation,
                child: SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 2.8,
                    color: isDark ? AppColors.mint : AppColors.primary,
                  ),
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}
