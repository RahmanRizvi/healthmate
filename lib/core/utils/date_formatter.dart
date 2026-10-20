import 'package:intl/intl.dart';

/// Utility class for formatting dates consistently across HealthMate.
class DateFormatter {
  DateFormatter._();

  /// Converts a [DateTime] into a standard local ISO date string: `yyyy-MM-dd`.
  static String toIsoDateString(DateTime date) {
    return DateFormat('yyyy-MM-dd').format(date);
  }

  /// Parses a `yyyy-MM-dd` date string into a local [DateTime].
  static DateTime parseIsoDate(String dateStr) {
    return DateTime.parse(dateStr);
  }

  /// Formats date for the dashboard greeting section: e.g. `TODAY, OCT 24`.
  static String formatGreetingDate(DateTime date, [DateTime? currentDate]) {
    final now = currentDate ?? DateTime.now();
    final isToday = isSameDay(date, now);

    final monthDay = DateFormat('MMM d').format(date).toUpperCase();
    if (isToday) {
      return 'TODAY, $monthDay';
    }
    return monthDay;
  }

  /// Formats date for the Add Record date selection card: e.g. `Today, 24 October`.
  static String formatDateOfActivity(DateTime date, [DateTime? currentDate]) {
    final now = currentDate ?? DateTime.now();
    final dayMonth = DateFormat('d MMMM').format(date);

    if (isSameDay(date, now)) {
      return 'Today, $dayMonth';
    }

    final yesterday = now.subtract(const Duration(days: 1));
    if (isSameDay(date, yesterday)) {
      return 'Yesterday, $dayMonth';
    }

    // e.g. "Tuesday, 22 October"
    final weekday = DateFormat('EEEE').format(date);
    return '$weekday, $dayMonth';
  }

  /// Formats date for recent record cards: e.g. `Today, Oct 24`, `Yesterday, Oct 23`, `Tuesday, Oct 22`.
  static String formatRecentRecordDate(DateTime date, [DateTime? currentDate]) {
    final now = currentDate ?? DateTime.now();
    final monthDay = DateFormat('MMM d').format(date);

    if (isSameDay(date, now)) {
      return 'Today, $monthDay';
    }

    final yesterday = now.subtract(const Duration(days: 1));
    if (isSameDay(date, yesterday)) {
      return 'Yesterday, $monthDay';
    }

    final weekday = DateFormat('EEEE').format(date);
    return '$weekday, $monthDay';
  }

  /// Checks if two [DateTime] instances fall on the same calendar day.
  static bool isSameDay(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}
