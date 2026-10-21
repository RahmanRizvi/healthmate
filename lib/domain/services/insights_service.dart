import 'package:intl/intl.dart';
import '../../core/utils/date_range_utils.dart';
import 'analytics_service.dart';

/// Represents a deterministic, data-driven insight for the progress screen.
class ProgressInsight {
  final String title;
  final String message;
  final bool isNew;

  const ProgressInsight({
    required this.title,
    required this.message,
    this.isNew = true,
  });
}

/// Generates personalized, deterministic health habit insights based on actual SQLite data.
class InsightsService {
  /// Generates the most relevant insight for the given [data].
  ProgressInsight generateInsight(ProgressAnalyticsData data) {
    final numberFormat = NumberFormat('#,###');
    final periodName = data.range.periodType == DatePeriodType.week ? 'this week' : 'this month';

    // 1. Empty period state
    if (!data.hasData) {
      return const ProgressInsight(
        title: 'Your insight',
        message:
            'No activity recorded yet for this period. Tap the + button in the top header to log your daily steps, hydration, and calories!',
        isNew: false,
      );
    }

    // 2. High steps goal consistency (matches Figma screenshot example)
    if (data.goalStats.stepsDaysAchieved >= 2) {
      return ProgressInsight(
        title: 'Your insight',
        message:
            'You reached your walking goal on ${data.goalStats.stepsDaysAchieved} recorded days $periodName and averaged ${numberFormat.format(data.summary.averageSteps)} steps/day. Consistency is building strong momentum!',
        isNew: true,
      );
    }

    // 3. Significant positive period-over-period improvement
    if (data.comparison.percentageChange != null && data.comparison.percentageChange! >= 5.0) {
      return ProgressInsight(
        title: 'Your insight',
        message:
            'Your walking activity increased by ${data.comparison.percentageChange!.round()}% compared to ${data.comparison.periodName}. Keep up the steady progress!',
        isNew: true,
      );
    }

    // 4. Hydration consistency
    if (data.goalStats.waterDaysAchieved >= 2) {
      return ProgressInsight(
        title: 'Your insight',
        message:
            'Hydration target achieved on ${data.goalStats.waterDaysAchieved} days $periodName! Maintaining steady fluid intake supports energy and focus.',
        isNew: true,
      );
    }

    // 5. Hydration reminder if below goal
    if (data.goals.waterGoalMl > 0 &&
        data.summary.totalWaterMl > 0 &&
        (data.summary.averageWaterLitres * 1000) < data.goals.waterGoalMl) {
      final goalL = (data.goals.waterGoalMl / 1000.0).toStringAsFixed(1);
      return ProgressInsight(
        title: 'Your insight',
        message:
            'Daily fluid intake is averaging ${data.summary.formattedAverageWaterLitres}/day against your $goalL L goal. Consider sipping water throughout the afternoon.',
        isNew: true,
      );
    }

    // 6. Only 1 record entered
    if (data.summary.totalRecords == 1) {
      return ProgressInsight(
        title: 'Your insight',
        message:
            'First entry logged for $periodName! Continue recording your daily steps and hydration to unlock complete trend analytics.',
        isNew: true,
      );
    }

    // 7. General positive progress
    return ProgressInsight(
      title: 'Your insight',
      message:
          'Recorded ${data.summary.totalRecords} days $periodName with ${numberFormat.format(data.summary.totalSteps)} total steps. Keep building healthy daily habits!',
      isNew: true,
    );
  }
}
