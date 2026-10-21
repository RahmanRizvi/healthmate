import 'package:intl/intl.dart';

enum DatePeriodType {
  day,
  week,
  month;

  String get label {
    switch (this) {
      case DatePeriodType.day:
        return 'Day';
      case DatePeriodType.week:
        return 'Week';
      case DatePeriodType.month:
        return 'Month';
    }
  }
}

/// Represents a closed date range [startDate, endDate] inclusive.
class DateRange {
  final DateTime startDate;
  final DateTime endDate;
  final DatePeriodType periodType;

  DateRange({
    required DateTime start,
    required DateTime end,
    required this.periodType,
  })  : startDate = DateTime(start.year, start.month, start.day),
        endDate = DateTime(end.year, end.month, end.day);

  /// Total number of calendar days in this range.
  int get totalCalendarDays => endDate.difference(startDate).inDays + 1;

  /// Returns all calendar days from [startDate] to [endDate] inclusive.
  List<DateTime> get days {
    final list = <DateTime>[];
    for (int i = 0; i < totalCalendarDays; i++) {
      list.add(startDate.add(Duration(days: i)));
    }
    return list;
  }

  /// ISO formatted strings for database queries.
  String get startIso => DateFormat('yyyy-MM-dd').format(startDate);
  String get endIso => DateFormat('yyyy-MM-dd').format(endDate);

  /// Label for period badge: e.g. `Oct 14 - 20`, `Oct 2026`, or `Oct 20, 2026`.
  String get displayLabel {
    if (periodType == DatePeriodType.day) {
      return DateFormat('MMM d, yyyy').format(startDate);
    } else if (periodType == DatePeriodType.week) {
      if (startDate.year == endDate.year) {
        if (startDate.month == endDate.month) {
          // e.g. "Oct 14 - 20"
          final monthStr = DateFormat('MMM').format(startDate);
          return '$monthStr ${startDate.day} - ${endDate.day}';
        } else {
          // e.g. "Oct 28 - Nov 3"
          final startMonth = DateFormat('MMM').format(startDate);
          final endMonth = DateFormat('MMM').format(endDate);
          return '$startMonth ${startDate.day} - $endMonth ${endDate.day}';
        }
      } else {
        // e.g. "Dec 28, 2025 - Jan 3, 2026"
        final startFmt = DateFormat('MMM d, yyyy').format(startDate);
        final endFmt = DateFormat('MMM d, yyyy').format(endDate);
        return '$startFmt - $endFmt';
      }
    } else {
      // Month e.g. "October 2026" or "Oct 2026"
      return DateFormat('MMM yyyy').format(startDate);
    }
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DateRange &&
          runtimeType == other.runtimeType &&
          startDate == other.startDate &&
          endDate == other.endDate &&
          periodType == other.periodType;

  @override
  int get hashCode => startDate.hashCode ^ endDate.hashCode ^ periodType.hashCode;
}

/// Date range helper utilities for weekly and monthly analytics periods.
class DateRangeUtils {
  DateRangeUtils._();

  /// Normalizes a date to midnight local time.
  static DateTime toMidnight(DateTime date) {
    return DateTime(date.year, date.month, date.day);
  }

  /// Calculates a single day range containing [referenceDate].
  static DateRange getDayRange(DateTime referenceDate) {
    final clean = toMidnight(referenceDate);
    return DateRange(
      start: clean,
      end: clean,
      periodType: DatePeriodType.day,
    );
  }

  /// Calculates the previous day range.
  static DateRange getPreviousDayRange(DateRange currentDay) {
    final prev = currentDay.startDate.subtract(const Duration(days: 1));
    return getDayRange(prev);
  }

  /// Calculates the next day range.
  static DateRange getNextDayRange(DateRange currentDay) {
    final next = currentDay.startDate.add(const Duration(days: 1));
    return getDayRange(next);
  }

  /// Calculates a Monday-to-Sunday 7-day range containing [referenceDate].
  static DateRange getWeekRange(DateTime referenceDate) {
    final clean = toMidnight(referenceDate);
    // weekday: 1 = Monday, 7 = Sunday
    final monday = clean.subtract(Duration(days: clean.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));

    return DateRange(
      start: monday,
      end: sunday,
      periodType: DatePeriodType.week,
    );
  }

  /// Calculates the previous week range.
  static DateRange getPreviousWeekRange(DateRange currentWeek) {
    final prevMonday = currentWeek.startDate.subtract(const Duration(days: 7));
    return getWeekRange(prevMonday);
  }

  /// Calculates the next week range.
  static DateRange getNextWeekRange(DateRange currentWeek) {
    final nextMonday = currentWeek.startDate.add(const Duration(days: 7));
    return getWeekRange(nextMonday);
  }

  /// Calculates the 1st to last day of month containing [referenceDate].
  static DateRange getMonthRange(DateTime referenceDate) {
    final firstDay = DateTime(referenceDate.year, referenceDate.month, 1);
    final lastDay = DateTime(referenceDate.year, referenceDate.month + 1, 0);

    return DateRange(
      start: firstDay,
      end: lastDay,
      periodType: DatePeriodType.month,
    );
  }

  /// Calculates the previous month range.
  static DateRange getPreviousMonthRange(DateRange currentMonth) {
    final prevMonthRef = DateTime(
      currentMonth.startDate.year,
      currentMonth.startDate.month - 1,
      1,
    );
    return getMonthRange(prevMonthRef);
  }

  /// Calculates the next month range.
  static DateRange getNextMonthRange(DateRange currentMonth) {
    final nextMonthRef = DateTime(
      currentMonth.startDate.year,
      currentMonth.startDate.month + 1,
      1,
    );
    return getMonthRange(nextMonthRef);
  }

  /// Checks if the next period would extend into the future relative to [now].
  static bool canNavigateNext(DateRange currentRange, [DateTime? currentDate]) {
    final now = toMidnight(currentDate ?? DateTime.now());
    if (currentRange.periodType == DatePeriodType.day) {
      final nextDay = currentRange.startDate.add(const Duration(days: 1));
      return !nextDay.isAfter(now);
    } else if (currentRange.periodType == DatePeriodType.week) {
      final nextMonday = currentRange.startDate.add(const Duration(days: 7));
      return !nextMonday.isAfter(now);
    } else {
      final nextMonthFirst = DateTime(
        currentRange.startDate.year,
        currentRange.startDate.month + 1,
        1,
      );
      return !nextMonthFirst.isAfter(now);
    }
  }

  /// Returns the equivalent previous period for comparison (yesterday, previous week or previous month).
  static DateRange getEquivalentPreviousPeriod(DateRange range) {
    if (range.periodType == DatePeriodType.day) {
      return getPreviousDayRange(range);
    } else if (range.periodType == DatePeriodType.week) {
      return getPreviousWeekRange(range);
    } else {
      return getPreviousMonthRange(range);
    }
  }
}
