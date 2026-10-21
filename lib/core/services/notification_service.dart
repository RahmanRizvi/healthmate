import 'package:flutter/foundation.dart';
import 'package:flutter/painting.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Service managing local scheduled reminders and wellness notifications.
class NotificationService {
  static const int dailyReminderId = 1001;
  static const int weeklyDigestId = 1002;
  static const String channelId = 'healthmate_reminders_channel';
  static const String channelName = 'HealthMate Reminders';
  static const String channelDescription =
      'Daily hydration, activity check-ins and weekly wellness digests';

  final FlutterLocalNotificationsPlugin _plugin;
  bool _initialized = false;

  NotificationService({FlutterLocalNotificationsPlugin? plugin})
      : _plugin = plugin ?? FlutterLocalNotificationsPlugin();

  bool get isInitialized => _initialized;

  /// Initializes platform notification settings.
  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@drawable/ic_notification');
    const darwinSettings = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );

    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: darwinSettings,
      macOS: darwinSettings,
    );

    try {
      await _plugin.initialize(settings: initSettings);
      _initialized = true;
    } catch (e) {
      debugPrint('NotificationService initialization: $e');
    }
  }

  /// Requests notification permissions on Android 13+ and iOS/macOS.
  Future<bool> requestPermissions() async {
    try {
      // Android 13+ permission
      final androidImplementation = _plugin
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>();
      if (androidImplementation != null) {
        final granted =
            await androidImplementation.requestNotificationsPermission();
        return granted ?? false;
      }

      // iOS permission
      final iosImplementation = _plugin
          .resolvePlatformSpecificImplementation<
              IOSFlutterLocalNotificationsPlugin>();
      if (iosImplementation != null) {
        final granted = await iosImplementation.requestPermissions(
          alert: true,
          badge: true,
          sound: true,
        );
        return granted ?? false;
      }
      return true;
    } catch (e) {
      debugPrint('Notification permission error: $e');
      return false;
    }
  }

  /// Schedules daily hydration and activity reminder.
  Future<void> scheduleDailyReminder({
    required int hour,
    required int minute,
    String title = 'Time to check in with HealthMate!',
    String body = 'Log your water intake, step count, and daily movement.',
  }) async {
    await initialize();
    try {
      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@drawable/ic_notification',
        color: Color(0xFF047857),
      );
      const darwinDetails = DarwinNotificationDetails();
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _plugin.periodicallyShow(
        id: dailyReminderId,
        repeatInterval: RepeatInterval.daily,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
      );
    } catch (e) {
      debugPrint('Error scheduling daily reminder: $e');
    }
  }

  /// Cancels daily reminder.
  Future<void> cancelDailyReminder() async {
    try {
      await _plugin.cancel(id: dailyReminderId);
    } catch (e) {
      debugPrint('Error canceling daily reminder: $e');
    }
  }

  /// Schedules weekly health digest reminder (every week).
  Future<void> scheduleWeeklyDigest({
    String title = 'Weekly Health Digest Ready',
    String body =
        'Check out your weekly progress, hydration summary, and step achievements!',
  }) async {
    await initialize();
    try {
      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.defaultImportance,
        priority: Priority.defaultPriority,
        icon: '@drawable/ic_notification',
        color: Color(0xFF047857),
      );
      const darwinDetails = DarwinNotificationDetails();
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _plugin.periodicallyShow(
        id: weeklyDigestId,
        repeatInterval: RepeatInterval.weekly,
        notificationDetails: notificationDetails,
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        title: title,
        body: body,
      );
    } catch (e) {
      debugPrint('Error scheduling weekly digest: $e');
    }
  }

  /// Cancels weekly digest reminder.
  Future<void> cancelWeeklyDigest() async {
    try {
      await _plugin.cancel(id: weeklyDigestId);
    } catch (e) {
      debugPrint('Error canceling weekly digest: $e');
    }
  }

  /// Displays an instant notification immediately (useful for testing and instant confirmation).
  Future<void> showInstantNotification({
    String title = 'HealthMate Reminders Enabled',
    String body = 'Daily check-in alerts are active! Stay hydrated and keep moving.',
  }) async {
    await initialize();
    try {
      const androidDetails = AndroidNotificationDetails(
        channelId,
        channelName,
        channelDescription: channelDescription,
        importance: Importance.high,
        priority: Priority.high,
        icon: '@drawable/ic_notification',
        color: Color(0xFF047857),
      );
      const darwinDetails = DarwinNotificationDetails();
      const notificationDetails = NotificationDetails(
        android: androidDetails,
        iOS: darwinDetails,
      );

      await _plugin.show(
        id: 9999,
        title: title,
        body: body,
        notificationDetails: notificationDetails,
      );
    } catch (e) {
      debugPrint('Error showing instant notification: $e');
    }
  }

  /// Cancels all scheduled notifications.
  Future<void> cancelAll() async {
    try {
      await _plugin.cancelAll();
    } catch (e) {
      debugPrint('Error canceling all notifications: $e');
    }
  }
}
