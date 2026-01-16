import 'package:ai_health/services/system_notification_service.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'dart:async';
import 'dart:developer' as developer;

class HydrationService {
  static const int _reminderAlarmId = 12345;

  // Initialize hydration service
  static Future<void> initialize() async {
    await AndroidAlarmManager.initialize();
  }

  // Setup daily hydration reminders
  static Future<void> setupDailyReminders({
    required int intervalMinutes,
    required int glassesPerDay,
  }) async {
    try {
      // Cancel existing alarms
      await AndroidAlarmManager.cancel(_reminderAlarmId);

      await AndroidAlarmManager.periodic(
        Duration(minutes: intervalMinutes),
        _reminderAlarmId,
        _reminderCallback,
        wakeup: true,
        rescheduleOnReboot: true,
      );
    } catch (e) {
      developer.log('Error setting up reminders: $e', error: e);
    }
  }

  // Callback function for alarm (must be static/top-level)
  @pragma('vm:entry-point')
  static Future<void> _reminderCallback() async {
    final now = DateTime.now();
    // Only notify between 6 AM and 11 PM
    if (now.hour < 6 || now.hour >= 23) return;

    // Initialize notification service in this isolate
    final notificationService = SystemNotificationService();
    await notificationService.initialize();

    await notificationService.showNotification(
      id: _reminderAlarmId,
      title: 'Hydration Time',
      body: 'Time to drink water! Stay hydrated! 💧',
    );
  }

  // Cancel all reminders
  static Future<void> cancelReminders() async {
    try {
      await AndroidAlarmManager.cancel(_reminderAlarmId);
    } catch (e) {
      developer.log('Error canceling reminders: $e', error: e);
    }
  }

  // Get daily water target in glasses
  static int getDailyTarget() {
    return 8; // 8 glasses per day (standard recommendation)
  }

  // Calculate glasses per interval
  static int getGlassesPerInterval(int intervalMinutes) {
    final dailyTarget = getDailyTarget();
    final intervalsPerDay = (24 * 60) ~/ intervalMinutes;
    return (dailyTarget / intervalsPerDay).ceil();
  }

  // Pause reminders (stop scheduling new ones)
  static Future<void> pauseReminders() async {
    await cancelReminders();
  }

  // Resume reminders
  static Future<void> resumeReminders({
    required int intervalMinutes,
  }) async {
    final glassesPerDay = getDailyTarget();
    await setupDailyReminders(
      intervalMinutes: intervalMinutes,
      glassesPerDay: glassesPerDay,
    );
  }
}
