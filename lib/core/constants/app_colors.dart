import 'package:flutter/material.dart';

/// App color palette matching the HealthMate Figma design specifications.
class AppColors {
  AppColors._();

  // Primary greens
  static const Color primaryDark = Color(0xFF073F38);
  static const Color primary = Color(0xFF047857);
  static const Color primaryLight = Color(0xFF10B981);
  static const Color accentGreen = Color(0xFF059669);

  // Mint & soft greens
  static const Color mint = Color(0xFFB7F7DE);
  static const Color mintSoft = Color(0xFFD1FAE5);
  static const Color mintSuperLight = Color(0xFFE8F8F2);
  static const Color mintBadge = Color(0xFFCCFBEF);

  // Backgrounds & cards
  static const Color scaffoldBackground = Color(0xFFF5FAF7);
  static const Color cardBackground = Colors.white;
  static const Color inputBackground = Colors.white;
  static const Color stepperBackground = Color(0xFFF3F4F6);
  static const Color infoBannerBackground = Color(0xFFF1F5F3);

  // Text colors
  static const Color textDark = Color(0xFF0B3B36);
  static const Color textHeadline = Color(0xFF073F38);
  static const Color textPrimary = Color(0xFF0F172A);
  static const Color textSecondary = Color(0xFF64748B);
  static const Color textMuted = Color(0xFF94A3B8);

  // Borders & Dividers
  static const Color border = Color(0xFFE2E8F0);
  static const Color borderLight = Color(0xFFEDF2F7);
  static const Color progressTrack = Color(0xFFE2E8F0);

  // BMI Category Spectrum
  static const Color bmiUnderweight = Color(0xFF93C5FD); // Light blue
  static const Color bmiNormal = Color(0xFF34D399); // Mint / green
  static const Color bmiOverweight = Color(0xFFFCD34D); // Soft warm yellow
  static const Color bmiObese = Color(0xFFFCA5A5); // Soft coral / pink-red

  // Badges & Status
  static const Color statusSuccess = Color(0xFF047857);
  static const Color statusSuccessBg = Color(0xFFD1FAE5);
  static const Color lockIcon = Color(0xFF047857);
}
