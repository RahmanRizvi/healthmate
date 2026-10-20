import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/constants/app_colors.dart';
import '../../../domain/services/onboarding_service.dart';
import '../viewmodels/dashboard_viewmodel.dart';

/// Main HealthMate Dashboard Screen displaying daily activity and health metrics.
class DashboardScreen extends StatelessWidget {
  final DashboardViewModel? viewModel;

  const DashboardScreen({super.key, this.viewModel});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (ctx) =>
          viewModel ??
          DashboardViewModel(
            onboardingService: ctx.read<OnboardingService>(),
          ),
      child: Consumer<DashboardViewModel>(
        builder: (context, vm, _) {
          final numberFormat = NumberFormat('#,###');
          final formattedStepsGoal = numberFormat.format(vm.stepsGoal);
          final formattedWaterGoal =
              '${(vm.waterGoalMl / 1000).toStringAsFixed(1)} L';

          return Scaffold(
            backgroundColor: const Color(0xFFF6F8FC),
            appBar: AppBar(
              backgroundColor: const Color(0xFFF6F8FC),
              elevation: 0,
              title: Row(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(6),
                    child: Image.asset(
                      'assets/images/logo.png',
                      height: 28,
                      width: 28,
                      fit: BoxFit.contain,
                      errorBuilder: (context, error, stackTrace) => const Icon(
                        Icons.favorite_rounded,
                        color: Color(0xFF087F8C),
                        size: 28,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  const Text(
                    'HealthMate',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.primaryDark,
                    ),
                  ),
                ],
              ),
              actions: [
                IconButton(
                  onPressed: () {},
                  icon: const Icon(Icons.notifications_none_rounded),
                ),
                const SizedBox(width: 8),
              ],
            ),
            body: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Good morning, ${vm.greetingName} 👋',
                    style: const TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Every healthy choice counts.',
                    style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                  ),
                  const SizedBox(height: 25),

                  // Daily goal card
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(22),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFF073F38), Color(0xFF047857)],
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                "TODAY'S GOAL",
                                style: TextStyle(
                                  color: Colors.white70,
                                  letterSpacing: 1.3,
                                  fontSize: 12,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'You are doing great!',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 21,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),
                              const Text(
                                'Keep building healthy habits.',
                                style: TextStyle(color: Colors.white70),
                              ),
                              const SizedBox(height: 18),
                              FilledButton(
                                onPressed: () {},
                                style: FilledButton.styleFrom(
                                  backgroundColor: Colors.white,
                                  foregroundColor: AppColors.primaryDark,
                                ),
                                child: const Text('View Progress'),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        const SizedBox(
                          width: 85,
                          height: 85,
                          child: CircularProgressIndicator(
                            value: 0.72,
                            strokeWidth: 9,
                            backgroundColor: Colors.white30,
                            valueColor: AlwaysStoppedAnimation<Color>(
                              Colors.white,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 28),

                  const Text(
                    "Today's Activity",
                    style: TextStyle(
                      fontSize: 21,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Expanded(
                        child: _activityCard(
                          icon: Icons.directions_walk_rounded,
                          title: 'Steps',
                          value: '7,850',
                          target: 'Goal: $formattedStepsGoal',
                          progress: 0.785,
                          color: const Color(0xFF4F7DF3),
                        ),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: _activityCard(
                          icon: Icons.local_fire_department_rounded,
                          title: 'Calories',
                          value: '320',
                          target: 'Goal: ${vm.caloriesGoalKcal} kcal',
                          progress: 0.64,
                          color: const Color(0xFFFF914D),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  _activityCard(
                    icon: Icons.water_drop_rounded,
                    title: 'Water Intake',
                    value: '1.5 L',
                    target: 'Goal: $formattedWaterGoal',
                    progress: 0.60,
                    color: const Color(0xFF17AFA0),
                    horizontal: true,
                  ),

                  const SizedBox(height: 28),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Quick Actions',
                        style: TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      Text(
                        'Manage your health',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  Row(
                    children: [
                      Expanded(
                        child: _quickAction(
                          icon: Icons.add_circle_outline_rounded,
                          title: 'Add Record',
                          color: AppColors.primary,
                          onTap: () => _showMessage(
                            context,
                            'Connect this action to your record form.',
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _quickAction(
                          icon: Icons.calendar_month_rounded,
                          title: 'History',
                          color: const Color(0xFF7C5CDB),
                          onTap: () => _showMessage(
                            context,
                            'Connect this action to health history.',
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
            bottomNavigationBar: NavigationBar(
              selectedIndex: 0,
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Home',
                ),
                NavigationDestination(
                  icon: Icon(Icons.calendar_month_outlined),
                  label: 'History',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  label: 'Profile',
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  static Widget _activityCard({
    required IconData icon,
    required String title,
    required String value,
    required String target,
    required double progress,
    required Color color,
    bool horizontal = false,
  }) {
    final content = Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 30, color: color),
        const SizedBox(height: 14),
        Text(
          title,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 14),
        ),
        const SizedBox(height: 5),
        Text(
          value,
          style: const TextStyle(fontSize: 25, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 5),
        Text(
          target,
          style: TextStyle(fontSize: 12, color: Colors.grey.shade500),
        ),
        const SizedBox(height: 14),
        ClipRRect(
          borderRadius: BorderRadius.circular(10),
          child: LinearProgressIndicator(
            value: progress,
            minHeight: 7,
            color: color,
            backgroundColor: color.withAlpha(30),
          ),
        ),
      ],
    );

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFFEDF0F5)),
      ),
      child: content,
    );
  }

  static Widget _quickAction({
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 22),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: const Color(0xFFEDF0F5)),
          ),
          child: Column(
            children: [
              Icon(icon, color: color, size: 32),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      ),
    );
  }

  static void _showMessage(BuildContext context, String message) {
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }
}
