import 'package:flutter/material.dart';

/// App layout dimensions, paddings, and border radii.
class AppDimensions {
  AppDimensions._();

  // Spacings
  static const double spaceXS = 4.0;
  static const double spaceS = 8.0;
  static const double spaceM = 12.0;
  static const double spaceL = 16.0;
  static const double spaceXL = 20.0;
  static const double spaceXXL = 24.0;
  static const double space3XL = 32.0;

  // Screen Padding
  static const EdgeInsets screenPadding = EdgeInsets.symmetric(horizontal: 24.0);
  static const EdgeInsets contentPadding = EdgeInsets.all(20.0);

  // Border Radii
  static const double radiusS = 8.0;
  static const double radiusM = 12.0;
  static const double radiusL = 16.0;
  static const double radiusXL = 20.0;
  static const double radiusXXL = 24.0;
  static const double radiusPill = 999.0;

  // Component heights
  static const double buttonHeight = 56.0;
  static const double inputHeight = 56.0;
  static const double headerHeight = 60.0;
  static const double progressHeight = 6.0;
}
