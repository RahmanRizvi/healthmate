import '../preferences/app_preferences.dart';

/// Accurate conversions between Metric (canonical SQLite storage) and Imperial display units.
class UnitConverter {
  UnitConverter._();

  // Conversion constants
  static const double cmPerInch = 2.54;
  static const double inchesPerFoot = 12.0;
  static const double lbsPerKg = 2.20462262185;
  static const double mlPerFlOz = 29.5735295625;

  // ================= Height Conversions =================

  /// Converts centimetres to total inches.
  static double cmToInches(double cm) {
    if (cm <= 0) return 0.0;
    return cm / cmPerInch;
  }

  /// Converts centimetres to feet and remaining inches (rounded).
  static ({int feet, int inches}) cmToFeetAndInches(double cm) {
    if (cm <= 0) return (feet: 0, inches: 0);
    final totalInches = (cm / cmPerInch).round();
    final feet = totalInches ~/ 12;
    final inches = totalInches % 12;
    return (feet: feet, inches: inches);
  }

  /// Converts feet and inches to centimetres.
  static double feetInchesToCm(int feet, int inches) {
    final totalInches = (feet * 12) + inches;
    return totalInches * cmPerInch;
  }

  /// Formats height for display according to unit system.
  static String formatHeight(double heightCm, MeasurementUnitSystem system) {
    if (heightCm <= 0) return '--';
    if (system == MeasurementUnitSystem.metric) {
      return '${heightCm.toStringAsFixed(0)} cm';
    } else {
      final fi = cmToFeetAndInches(heightCm);
      return "${fi.feet}' ${fi.inches}\"";
    }
  }

  /// Returns numeric value and unit separately for metric/imperial card displays.
  static ({String value, String unit}) splitHeight(
    double heightCm,
    MeasurementUnitSystem system,
  ) {
    if (heightCm <= 0) return (value: '--', unit: '');
    if (system == MeasurementUnitSystem.metric) {
      return (value: heightCm.toStringAsFixed(0), unit: 'cm');
    } else {
      final fi = cmToFeetAndInches(heightCm);
      return (value: "${fi.feet}'${fi.inches}\"", unit: '');
    }
  }

  // ================= Weight Conversions =================

  /// Converts kilograms to pounds.
  static double kgToLbs(double kg) {
    if (kg <= 0) return 0.0;
    return kg * lbsPerKg;
  }

  /// Converts pounds to kilograms.
  static double lbsToKg(double lbs) {
    if (lbs <= 0) return 0.0;
    return lbs / lbsPerKg;
  }

  /// Formats weight for display according to unit system.
  static String formatWeight(double weightKg, MeasurementUnitSystem system) {
    if (weightKg <= 0) return '--';
    if (system == MeasurementUnitSystem.metric) {
      return '${weightKg.toStringAsFixed(1)} kg';
    } else {
      final lbs = kgToLbs(weightKg);
      return '${lbs.toStringAsFixed(1)} lbs';
    }
  }

  /// Returns numeric value and unit separately for card displays.
  static ({String value, String unit}) splitWeight(
    double weightKg,
    MeasurementUnitSystem system,
  ) {
    if (weightKg <= 0) return (value: '--', unit: '');
    if (system == MeasurementUnitSystem.metric) {
      return (value: weightKg.toStringAsFixed(1), unit: 'kg');
    } else {
      final lbs = kgToLbs(weightKg);
      return (value: lbs.toStringAsFixed(1), unit: 'lbs');
    }
  }

  // ================= Water Conversions =================

  /// Converts millilitres to US fluid ounces.
  static double mlToFlOz(int ml) {
    if (ml <= 0) return 0.0;
    return ml / mlPerFlOz;
  }

  /// Converts US fluid ounces to millilitres.
  static int flOzToMl(double flOz) {
    if (flOz <= 0) return 0;
    return (flOz * mlPerFlOz).round();
  }

  /// Formats water intake for display according to unit system.
  static String formatWater(int waterMl, MeasurementUnitSystem system) {
    if (waterMl <= 0) return '0 ml';
    if (system == MeasurementUnitSystem.metric) {
      return '$waterMl ml';
    } else {
      final oz = mlToFlOz(waterMl);
      return '${oz.toStringAsFixed(0)} fl oz';
    }
  }

  /// Split water value and unit.
  static ({String value, String unit}) splitWater(
    int waterMl,
    MeasurementUnitSystem system,
  ) {
    if (system == MeasurementUnitSystem.metric) {
      return (value: waterMl.toString(), unit: 'ml');
    } else {
      final oz = mlToFlOz(waterMl).round();
      return (value: oz.toString(), unit: 'fl oz');
    }
  }
}
