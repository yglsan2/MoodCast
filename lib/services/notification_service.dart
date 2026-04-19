import 'package:flutter/foundation.dart'
    show debugPrint, defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:flutter_timezone/flutter_timezone.dart';
import 'package:timezone/timezone.dart' as tz;
import 'package:timezone/data/latest_all.dart' as tz_data;

import 'risk_days_service.dart';
import 'storage_service.dart';

/// Rappels quotidiens pour le rituel matin/soir et rappels « jours à risque ».
class NotificationService {
  NotificationService._();

  static final FlutterLocalNotificationsPlugin _plugin = FlutterLocalNotificationsPlugin();

  static const int _idRoutineMorning = 1;
  static const int _idRoutineEvening = 2;
  static const int _idRiskDaysBase = 20; // 21..27 pour weekdays 1..7

  static bool _initialized = false;

  static Future<void> init() async {
    if (_initialized) return;
    if (kIsWeb) {
      _initialized = true;
      return;
    }
    try {
      tz_data.initializeTimeZones();
      try {
        final tzInfo = await FlutterTimezone.getLocalTimezone();
        tz.setLocalLocation(tz.getLocation(tzInfo.identifier));
      } catch (_) {
        tz.setLocalLocation(tz.getLocation('Europe/Paris'));
      }

      const android = AndroidInitializationSettings('@mipmap/ic_launcher');
      const ios = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: false,
      );
      final initSettings = InitializationSettings(
        android: android,
        iOS: ios,
        linux: defaultTargetPlatform == TargetPlatform.linux
            ? const LinuxInitializationSettings(defaultActionName: 'Open')
            : null,
      );
      await _plugin.initialize(initSettings);

      final androidPlugin = _plugin.resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
      if (androidPlugin != null) {
        await androidPlugin.requestNotificationsPermission();
      }
      final iosPlugin = _plugin.resolvePlatformSpecificImplementation<IOSFlutterLocalNotificationsPlugin>();
      if (iosPlugin != null) {
        await iosPlugin.requestPermissions(alert: true);
      }
    } catch (e, st) {
      debugPrint('NotificationService.init: $e\n$st');
    }
    _initialized = true;
  }

  static Future<void> updateRoutineReminders() async {
    await init();
    if (kIsWeb) return;

    await _plugin.cancel(_idRoutineMorning);
    await _plugin.cancel(_idRoutineEvening);

    final morningEnabled = await StorageService.getRoutineReminderMorningEnabled();
    final morningTime = await StorageService.getRoutineReminderMorningTime();
    if (morningEnabled) {
      await _scheduleDaily(_idRoutineMorning, morningTime, 'Rituel matin 🌅', 'Prends un moment pour ton intention et ton micro-mood.');
    }

    final eveningEnabled = await StorageService.getRoutineReminderEveningEnabled();
    final eveningTime = await StorageService.getRoutineReminderEveningTime();
    if (eveningEnabled) {
      await _scheduleDaily(_idRoutineEvening, eveningTime, 'Rituel soir 🌙', 'Comment était ta journée ? Un petit mood pour clôturer.');
    }

    await updateRiskDaysReminders();
  }

  /// Rappels les jours où tu es souvent en baisse (analyse des MoodCasts).
  static Future<void> updateRiskDaysReminders() async {
    await init();
    if (kIsWeb) return;

    for (int w = 1; w <= 7; w++) {
      await _plugin.cancel(_idRiskDaysBase + w);
    }

    final enabled = await StorageService.getRiskDaysReminderEnabled();
    if (!enabled) return;

    final riskWeekdays = await RiskDaysService.getRiskWeekdays(limit: 3);
    if (riskWeekdays.isEmpty) return;

    const androidDetails = AndroidNotificationDetails(
      'moodcast_risk_days',
      'Rappels jours à risque',
      channelDescription: 'Rappel pour les jours où tu es souvent en baisse',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
    );
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    const hour = 9;
    const minute = 0;

    for (final weekday in riskWeekdays) {
      final id = _idRiskDaysBase + weekday;
      final now = tz.TZDateTime.now(tz.local);
      var scheduled = _nextWeekdayAt(now, weekday, hour, minute);
      if (scheduled.isBefore(now)) {
        scheduled = scheduled.add(const Duration(days: 7));
      }
      final dayName = RiskDaysService.weekdayNameCap(weekday);
      await _plugin.zonedSchedule(
        id,
        'Rituel MoodCast 📅',
        'En général le $dayName tu es plus souvent en baisse. Pense à ton rituel !',
        scheduled,
        details,
        // inexact : pas de permission SCHEDULE_EXACT_ALARM (évite crash / refus au démarrage).
        androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
        uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
        matchDateTimeComponents: DateTimeComponents.dayOfWeekAndTime,
      );
    }
  }

  static tz.TZDateTime _nextWeekdayAt(tz.TZDateTime from, int weekday, int hour, int minute) {
    var d = tz.TZDateTime(tz.local, from.year, from.month, from.day, hour, minute);
    while (d.weekday != weekday) {
      d = d.add(const Duration(days: 1));
    }
    if (d.isBefore(from)) {
      d = d.add(const Duration(days: 7));
    }
    return d;
  }

  static Future<void> _scheduleDaily(int id, String timeHHmm, String title, String body) async {
    final parts = timeHHmm.split(':');
    final hour = parts.isNotEmpty ? int.tryParse(parts[0]) ?? 8 : 8;
    final minute = parts.length > 1 ? int.tryParse(parts[1]) ?? 0 : 0;

    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) {
      scheduled = scheduled.add(const Duration(days: 1));
    }

    const androidDetails = AndroidNotificationDetails(
      'moodcast_routine',
      'Rappels MoodRoutine',
      channelDescription: 'Rappels pour le rituel matin et soir',
      importance: Importance.defaultImportance,
      priority: Priority.defaultPriority,
    );
    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: false,
    );
    const details = NotificationDetails(android: androidDetails, iOS: iosDetails);

    await _plugin.zonedSchedule(
      id,
      title,
      body,
      scheduled,
      details,
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
      uiLocalNotificationDateInterpretation: UILocalNotificationDateInterpretation.absoluteTime,
      matchDateTimeComponents: DateTimeComponents.time,
    );
  }
}
