import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/data/models/health_record.dart';

void main() {
  group('HealthRecord Model Tests', () {
    test('serializes toMap and deserializes fromMap accurately', () {
      final now = DateTime(2026, 10, 24, 10, 30);
      final record = HealthRecord(
        id: 1,
        date: '2026-10-24',
        steps: 7850,
        calories: 420,
        water: 1750,
        createdAt: now,
        updatedAt: now,
      );

      final map = record.toMap();
      final fromMap = HealthRecord.fromMap(map);

      expect(fromMap.id, equals(1));
      expect(fromMap.date, equals('2026-10-24'));
      expect(fromMap.steps, equals(7850));
      expect(fromMap.calories, equals(420));
      expect(fromMap.water, equals(1750));
    });

    test('copyWith clamps negative values to 0', () {
      final record = HealthRecord.empty(DateTime(2026, 10, 24));
      final updated = record.copyWith(
        steps: -50,
        calories: -100,
        water: -500,
      );

      expect(updated.steps, equals(0));
      expect(updated.calories, equals(0));
      expect(updated.water, equals(0));
    });
  });
}
