import 'dart:convert';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:permission_handler/permission_handler.dart';
import '../models/task_model.dart';

const int _alarmId = 500;
const String _tasksKey = 'tasks_v1';

class NotificationService {
  static final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  /// Call once in main() before runApp().
  static Future<void> init() async {
    const androidInit = AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidInit);
    await _plugin.initialize(initSettings);

    const channel = AndroidNotificationChannel(
      'tasks_reminder_channel',
      'تذكير المهام',
      description: 'تنبيهات المهام غير المكتملة',
      importance: Importance.max,
      playSound: true,
      enableVibration: true,
    );
    await _plugin
        .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>()
        ?.createNotificationChannel(channel);

    await AndroidAlarmManager.initialize();
  }

  /// Requests the runtime permissions needed on modern Android versions.
  static Future<void> requestPermissions() async {
    await Permission.notification.request();
    await Permission.scheduleExactAlarm.request();
  }

  /// Cancels any pending chain and (re)starts it at the correct next time.
  static Future<void> startReminderChain() async {
    await AndroidAlarmManager.cancel(_alarmId);
    final next = _computeInitialTrigger();
    await AndroidAlarmManager.oneShotAt(
      next,
      _alarmId,
      _alarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  }

  static DateTime _computeInitialTrigger() {
    final now = DateTime.now();
    final todayAt845 = DateTime(now.year, now.month, now.day, 8, 45);
    if (now.isBefore(todayAt845)) {
      return todayAt845;
    }
    // Already past 8:45 today -> check almost immediately, then the chain
    // keeps itself hourly and re-aligns to 8:45 the next day.
    return now.add(const Duration(seconds: 15));
  }

  /// Runs in a background isolate. Must be a top-level or static function.
  @pragma('vm:entry-point')
  static Future<void> _alarmCallback() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_tasksKey);

    List<TaskItem> tasks = [];
    if (raw != null) {
      try {
        tasks = (jsonDecode(raw) as List)
            .map((e) => TaskItem.fromJson(e as Map<String, dynamic>))
            .toList();
      } catch (_) {}
    }

    final incomplete = tasks.where((t) => !t.completed).toList();

    if (incomplete.isNotEmpty) {
      final lateCount =
          incomplete.where((t) => t.status == TaskStatus.late).length;
      final body = lateCount > 0
          ? 'لديك ${incomplete.length} مهمة غير مكتملة، منها $lateCount متأخرة.'
          : 'لديك ${incomplete.length} مهمة غير مكتملة اليوم.';

      const androidDetails = AndroidNotificationDetails(
        'tasks_reminder_channel',
        'تذكير المهام',
        channelDescription: 'تنبيهات المهام غير المكتملة',
        importance: Importance.max,
        priority: Priority.high,
        playSound: true,
        enableVibration: true,
      );
      await _plugin.initialize(
        const InitializationSettings(
          android: AndroidInitializationSettings('@mipmap/ic_launcher'),
        ),
      );
      await _plugin.show(
        1001,
        'تذكير بالمهام',
        body,
        const NotificationDetails(android: androidDetails),
      );
    }

    // Reschedule: next hour, but if that would land before 8:45 (i.e. the
    // hourly chain rolled past midnight), snap forward to 8:45 that day.
    final now = DateTime.now();
    var next = now.add(const Duration(hours: 1));
    final nextAt845 = DateTime(next.year, next.month, next.day, 8, 45);
    if (next.isBefore(nextAt845)) {
      next = nextAt845;
    }

    await AndroidAlarmManager.oneShotAt(
      next,
      _alarmId,
      _alarmCallback,
      exact: true,
      wakeup: true,
      rescheduleOnReboot: true,
    );
  }
}
