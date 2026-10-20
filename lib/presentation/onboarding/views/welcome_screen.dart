import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/constants/app_dimensions.dart';
import '../../../core/widgets/primary_button.dart';
import 'personal_details_screen.dart';

/// Screen 1: Welcome Screen introducing HealthMate.
class WelcomeScreen extends StatelessWidget {
  const WelcomeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFFDFF6EC),
              Color(0xFFEDFAF3),
              Color(0xFFF7FAF8),
              Colors.white,
            ],
            stops: [0.0, 0.35, 0.65, 1.0],
          ),
        ),
        child: SafeArea(
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
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        const SizedBox(height: 20),

                        // Center decorative rings illustration with badges and logo
                        _buildIllustration(size),

                        const SizedBox(height: 36),

                        // Brand header
                        const Text(
                          'Healthmate',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primaryDark,
                            letterSpacing: -0.3,
                          ),
                        ),
                        const SizedBox(height: 12),

                        // Main headline
                        const Text(
                          'Your wellness journey\nstarts here.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 30,
                            height: 1.25,
                            fontWeight: FontWeight.w800,
                            color: AppColors.primaryDark,
                            letterSpacing: -0.8,
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Subtitle
                        const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 16.0),
                          child: Text(
                            'Build healthy habits, track your progress, and take small steps toward a healthier you.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              height: 1.45,
                              color: AppColors.textSecondary,
                              fontWeight: FontWeight.w400,
                            ),
                          ),
                        ),

                        const Spacer(),
                        const SizedBox(height: 32),

                        // Continue Button
                        PrimaryButton(
                          text: 'Continue',
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => const PersonalDetailsScreen(),
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 16),

                        // Footer note
                        const Text(
                          'Your personal health companion',
                          style: TextStyle(
                            fontSize: 13,
                            color: AppColors.textMuted,
                            fontWeight: FontWeight.w500,
                          ),
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
      ),
    );
  }

  /// Builds the concentric circular illustration with floating feature badges.
  Widget _buildIllustration(Size screenSize) {
    return SizedBox(
      width: 320,
      height: 320,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Outer decorative circle
          Container(
            width: 290,
            height: 290,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.mint.withAlpha(40),
              border: Border.all(
                color: AppColors.mint.withAlpha(160),
                width: 1.5,
              ),
            ),
          ),

          // Middle circle
          Container(
            width: 230,
            height: 230,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.border.withAlpha(180),
                width: 1.2,
              ),
            ),
          ),

          // Inner circle
          Container(
            width: 170,
            height: 170,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.border.withAlpha(120),
                width: 1,
              ),
            ),
          ),

          // Floating Badge 1: Activity (Top Left)
          Positioned(
            top: 28,
            left: 8,
            child: _buildFeaturePill(
              icon: Icons.directions_run_rounded,
              label: 'Activity',
            ),
          ),

          // Floating Badge 2: Hydration (Top Right)
          Positioned(
            top: 60,
            right: 8,
            child: _buildFeaturePill(
              icon: Icons.water_drop_rounded,
              label: 'Hydration',
            ),
          ),

          // Floating Badge 3: Vitals (Bottom Right)
          Positioned(
            bottom: 40,
            right: 18,
            child: _buildFeaturePill(
              icon: Icons.favorite_outline_rounded,
              label: 'Vitals',
            ),
          ),

          // Central HealthMate Logo Card
          Container(
            width: 124,
            height: 124,
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(28),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withAlpha(18),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
                BoxShadow(
                  color: AppColors.primary.withAlpha(25),
                  blurRadius: 30,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: Image.asset(
                  'assets/images/logo.png',
                  width: 96,
                  height: 96,
                  fit: BoxFit.contain,
                  errorBuilder: (context, error, stackTrace) => const Icon(
                    Icons.favorite_rounded,
                    size: 60,
                    color: AppColors.primary,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  /// Helper for floating pill badges with dot, icon, and text.
  Widget _buildFeaturePill({
    required IconData icon,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(AppDimensions.radiusPill),
        border: Border.all(color: AppColors.border.withAlpha(160)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withAlpha(12),
            blurRadius: 8,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            icon,
            size: 16,
            color: AppColors.primary,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w600,
              color: AppColors.textPrimary,
            ),
          ),
        ],
      ),
    );
  }
}
