/// Utility for calculating and formatting age from date of birth.
class AgeCalculator {
  AgeCalculator._();

  /// Calculates chronological age in full years from [birthDate].
  /// An optional [currentDate] can be passed for deterministic unit testing.
  static int calculateAge(DateTime birthDate, [DateTime? currentDate]) {
    final now = currentDate ?? DateTime.now();

    if (birthDate.isAfter(now)) {
      return 0;
    }

    int age = now.year - birthDate.year;

    // If current date is before birthday in the current year, decrement age
    if (now.month < birthDate.month ||
        (now.month == birthDate.month && now.day < birthDate.day)) {
      age--;
    }

    return age >= 0 ? age : 0;
  }

  /// Formats the age as a user-friendly label (e.g. "Age: 26 years").
  static String formatAge(int? age) {
    if (age == null || age <= 0) {
      return 'Age: --';
    }
    return 'Age: $age ${age == 1 ? "year" : "years"}';
  }

  /// Formats age for summary display (e.g. "26 yrs").
  static String formatAgeShort(int? age) {
    if (age == null || age <= 0) {
      return '--';
    }
    return '$age yrs';
  }
}
