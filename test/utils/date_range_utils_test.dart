import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/utils/date_range_utils.dart';

void main() {
  group('DateRangeUtils Tests', () {
    test('getWeekRange returns Monday through Sunday for a given date', () {
      // 2026-10-20 is a Tuesday (weekday 2)
      final tuesday = DateTime(2026, 10, 20);
      final range = DateRangeUtils.getWeekRange(tuesday);

      expect(range.startDate, DateTime(2026, 10, 19)); // Monday
      expect(range.endDate, DateTime(2026, 10, 25)); // Sunday
      expect(range.totalCalendarDays, 7);
      expect(range.displayLabel, 'Oct 19 - 25');
    });

    test('getWeekRange crossing month boundaries formats label properly', () {
      // 2026-10-30 is a Friday
      final friday = DateTime(2026, 10, 30);
      final range = DateRangeUtils.getWeekRange(friday);

      expect(range.startDate, DateTime(2026, 10, 26));
      expect(range.endDate, DateTime(2026, 11, 1));
      expect(range.displayLabel, 'Oct 26 - Nov 1');
    });

    test('getWeekRange crossing year boundaries formats label properly', () {
      // 2026-01-01 is Thursday
      final thursday = DateTime(2026, 1, 1);
      final range = DateRangeUtils.getWeekRange(thursday);

      expect(range.startDate, DateTime(2025, 12, 29));
      expect(range.endDate, DateTime(2026, 1, 4));
      expect(range.totalCalendarDays, 7);
    });

    test('getMonthRange handles 31, 30, and 28/29 day months accurately', () {
      // October has 31 days
      final octRange = DateRangeUtils.getMonthRange(DateTime(2026, 10, 15));
      expect(octRange.startDate, DateTime(2026, 10, 1));
      expect(octRange.endDate, DateTime(2026, 10, 31));
      expect(octRange.totalCalendarDays, 31);
      expect(octRange.displayLabel, 'Oct 2026');

      // April has 30 days
      final aprRange = DateRangeUtils.getMonthRange(DateTime(2026, 4, 10));
      expect(aprRange.startDate, DateTime(2026, 4, 1));
      expect(aprRange.endDate, DateTime(2026, 4, 30));
      expect(aprRange.totalCalendarDays, 30);

      // Non-leap February (2026) has 28 days
      final feb2026 = DateRangeUtils.getMonthRange(DateTime(2026, 2, 10));
      expect(feb2026.totalCalendarDays, 28);

      // Leap February (2024) has 29 days
      final feb2024 = DateRangeUtils.getMonthRange(DateTime(2024, 2, 10));
      expect(feb2024.totalCalendarDays, 29);
    });

    test('Navigation respects future boundaries', () {
      final now = DateTime(2026, 10, 20);
      final currentWeek = DateRangeUtils.getWeekRange(now);

      // Current week cannot navigate to next week
      expect(DateRangeUtils.canNavigateNext(currentWeek, now), isFalse);

      // Previous week can navigate to next week
      final prevWeek = DateRangeUtils.getPreviousWeekRange(currentWeek);
      expect(DateRangeUtils.canNavigateNext(prevWeek, now), isTrue);

      // Current month cannot navigate to next month
      final currentMonth = DateRangeUtils.getMonthRange(now);
      expect(DateRangeUtils.canNavigateNext(currentMonth, now), isFalse);

      // Previous month can navigate to next month
      final prevMonth = DateRangeUtils.getPreviousMonthRange(currentMonth);
      expect(DateRangeUtils.canNavigateNext(prevMonth, now), isTrue);
    });

    test('getDayRange returns single-day range and navigates properly', () {
      final tuesday = DateTime(2026, 10, 20);
      final dayRange = DateRangeUtils.getDayRange(tuesday);

      expect(dayRange.periodType, DatePeriodType.day);
      expect(dayRange.totalCalendarDays, 1);
      expect(dayRange.startDate, DateTime(2026, 10, 20));
      expect(dayRange.endDate, DateTime(2026, 10, 20));
      expect(dayRange.displayLabel, 'Oct 20, 2026');

      // Cannot navigate forward beyond today
      expect(DateRangeUtils.canNavigateNext(dayRange, tuesday), isFalse);

      // Previous day (yesterday)
      final yesterday = DateRangeUtils.getPreviousDayRange(dayRange);
      expect(yesterday.startDate, DateTime(2026, 10, 19));
      expect(DateRangeUtils.canNavigateNext(yesterday, tuesday), isTrue);

      // Equivalent comparison period
      final eq = DateRangeUtils.getEquivalentPreviousPeriod(dayRange);
      expect(eq.startDate, DateTime(2026, 10, 19));
    });
  });
}
