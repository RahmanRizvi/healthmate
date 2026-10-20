import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'core/constants/app_colors.dart';
import 'core/theme/app_theme.dart';
import 'data/database/app_database.dart';
import 'data/repositories/onboarding_repository.dart';
import 'domain/services/bmi_service.dart';
import 'domain/services/onboarding_service.dart';
import 'presentation/dashboard/views/dashboard_screen.dart';
import 'presentation/onboarding/views/bmi_analysis_screen.dart';
import 'presentation/onboarding/views/daily_goals_screen.dart';
import 'presentation/onboarding/views/personal_details_screen.dart';
import 'presentation/onboarding/views/welcome_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const HealthMateApp());
}

/// Root widget of the HealthMate application.
class HealthMateApp extends StatelessWidget {
  final OnboardingService? onboardingService;
  final Widget? home;

  const HealthMateApp({
    super.key,
    this.onboardingService,
    this.home,
  });

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        Provider<AppDatabase>(
          create: (_) => AppDatabase(),
          dispose: (_, db) => db.close(),
        ),
        ProxyProvider<AppDatabase, IOnboardingRepository>(
          update: (context, db, previous) => OnboardingRepository(db: db),
        ),
        ProxyProvider<IOnboardingRepository, OnboardingService>(
          update: (context, repo, previous) =>
              onboardingService ?? OnboardingService(repository: repo),
        ),
        Provider<BmiService>(
          create: (_) => BmiService(),
        ),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'HealthMate',
        theme: AppTheme.lightTheme,
        home: home ?? const AppEntryRouter(),
      ),
    );
  }
}

/// Determines the starting screen based on SQLite onboarding persistence state.
class AppEntryRouter extends StatefulWidget {
  const AppEntryRouter({super.key});

  @override
  State<AppEntryRouter> createState() => _AppEntryRouterState();
}

class _AppEntryRouterState extends State<AppEntryRouter> {
  late Future<OnboardingResumeStep> _resumeStepFuture;

  @override
  void initState() {
    super.initState();
    final onboardingService =
        Provider.of<OnboardingService>(context, listen: false);
    _resumeStepFuture = onboardingService.getResumeStep();
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<OnboardingResumeStep>(
      future: _resumeStepFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(
              child: CircularProgressIndicator(
                color: AppColors.primary,
              ),
            ),
          );
        }

        final resumeStep = snapshot.data ?? OnboardingResumeStep.welcome;

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
      },
    );
  }
}
