import 'package:flutter_test/flutter_test.dart';
import 'package:healthmate/core/preferences/app_preferences.dart';
import 'package:healthmate/core/utils/unit_converter.dart';

void main() {
  group('UnitConverter Tests', () {
    test('Height conversion: metric and imperial', () {
      const heightCm = 178.0;

      // Metric formatting
      expect(
        UnitConverter.formatHeight(heightCm, MeasurementUnitSystem.metric),
        '178 cm',
      );
      final splitMetric = UnitConverter.splitHeight(
        heightCm,
        MeasurementUnitSystem.metric,
      );
      expect(splitMetric.value, '178');
      expect(splitMetric.unit, 'cm');

      // Imperial conversion: 178 cm / 2.54 = ~70.078 inches -> 5 ft 10 in
      final feetInches = UnitConverter.cmToFeetAndInches(heightCm);
      expect(feetInches.feet, 5);
      expect(feetInches.inches, 10);
      expect(
        UnitConverter.formatHeight(heightCm, MeasurementUnitSystem.imperial),
        '5\' 10"',
      );

      // Reconversion back to cm
      final convertedBackCm = UnitConverter.feetInchesToCm(5, 10);
      expect(convertedBackCm, closeTo(177.8, 0.1));
    });

    test('Weight conversion: metric and imperial', () {
      const weightKg = 72.4;

      // Metric formatting
      expect(
        UnitConverter.formatWeight(weightKg, MeasurementUnitSystem.metric),
        '72.4 kg',
      );
      final splitMetric = UnitConverter.splitWeight(
        weightKg,
        MeasurementUnitSystem.metric,
      );
      expect(splitMetric.value, '72.4');
      expect(splitMetric.unit, 'kg');

      // Imperial conversion: 72.4 kg * 2.20462 = ~159.6 lbs
      final lbs = UnitConverter.kgToLbs(weightKg);
      expect(lbs, closeTo(159.6, 0.1));
      expect(
        UnitConverter.formatWeight(weightKg, MeasurementUnitSystem.imperial),
        '159.6 lbs',
      );

      // Reconversion back to kg
      final convertedBackKg = UnitConverter.lbsToKg(lbs);
      expect(convertedBackKg, closeTo(72.4, 0.01));
    });

    test('Water conversion: metric and imperial', () {
      const waterMl = 2500;

      // Metric formatting
      expect(
        UnitConverter.formatWater(waterMl, MeasurementUnitSystem.metric),
        '2500 ml',
      );
      final splitMetric = UnitConverter.splitWater(
        waterMl,
        MeasurementUnitSystem.metric,
      );
      expect(splitMetric.value, '2500');
      expect(splitMetric.unit, 'ml');

      // Imperial conversion: 2500 ml / 29.5735 = ~85 fl oz
      final flOz = UnitConverter.mlToFlOz(waterMl);
      expect(flOz, closeTo(84.53, 0.1));
      final splitImperial = UnitConverter.splitWater(
        waterMl,
        MeasurementUnitSystem.imperial,
      );
      expect(splitImperial.unit, 'fl oz');
      expect(splitImperial.value, '85');

      // Reconversion back to ml
      final convertedBackMl = UnitConverter.flOzToMl(flOz);
      expect(convertedBackMl, waterMl);
    });

    test('Handles non-positive inputs safely', () {
      expect(
        UnitConverter.formatHeight(0, MeasurementUnitSystem.metric),
        '--',
      );
      expect(
        UnitConverter.formatWeight(0, MeasurementUnitSystem.metric),
        '--',
      );
      expect(
        UnitConverter.formatWater(0, MeasurementUnitSystem.metric),
        '0 ml',
      );
    });
  });
}
