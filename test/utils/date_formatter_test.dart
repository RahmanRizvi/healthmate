import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/utils/date_formatter.dart';

void main() {
  group('DateFormatter Tests', () {
    final referenceDate = DateTime(2026, 10, 24);

    test('toIsoDateString formats date as yyyy-MM-dd', () {
      final date = DateTime(2026, 10, 24);
      expect(DateFormatter.toIsoDateString(date), equals('2026-10-24'));
    });

    test('parseIsoDate parses yyyy-MM-dd into DateTime', () {
      final parsed = DateFormatter.parseIsoDate('2026-10-24');
      expect(parsed.year, equals(2026));
      expect(parsed.month, equals(10));
      expect(parsed.day, equals(24));
    });

    test('formatGreetingDate produces TODAY, OCT 24 for today', () {
      final result = DateFormatter.formatGreetingDate(referenceDate, referenceDate);
      expect(result, equals('TODAY, OCT 24'));
    });

    test('formatGreetingDate produces month day for past dates', () {
      final pastDate = DateTime(2026, 10, 20);
      final result = DateFormatter.formatGreetingDate(pastDate, referenceDate);
      expect(result, equals('OCT 20'));
    });

    test('formatDateOfActivity handles Today, Yesterday, and Weekday', () {
      final today = referenceDate;
      final yesterday = DateTime(2026, 10, 23);
      final earlier = DateTime(2026, 10, 20); // Tuesday

      expect(
        DateFormatter.formatDateOfActivity(today, referenceDate),
        equals('Today, 24 October'),
      );
      expect(
        DateFormatter.formatDateOfActivity(yesterday, referenceDate),
        equals('Yesterday, 23 October'),
      );
      expect(
        DateFormatter.formatDateOfActivity(earlier, referenceDate),
        equals('Tuesday, 20 October'),
      );
    });

    test('formatRecentRecordDate handles Today, Yesterday, and Weekday short format', () {
      final today = referenceDate;
      final yesterday = DateTime(2026, 10, 23);
      final earlier = DateTime(2026, 10, 20);

      expect(
        DateFormatter.formatRecentRecordDate(today, referenceDate),
        equals('Today, Oct 24'),
      );
      expect(
        DateFormatter.formatRecentRecordDate(yesterday, referenceDate),
        equals('Yesterday, Oct 23'),
      );
      expect(
        DateFormatter.formatRecentRecordDate(earlier, referenceDate),
        equals('Tuesday, Oct 20'),
      );
    });
  });
}
