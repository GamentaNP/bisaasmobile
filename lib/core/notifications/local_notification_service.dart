// ignore_for_file: missing_required_argument, extra_positional_arguments_could_be_named, inference_failure_on_function_invocation

import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;

class LocalNotificationService {
  LocalNotificationService(this._plugin);
  final FlutterLocalNotificationsPlugin _plugin;

  final StreamController<String?> _taps = StreamController<String?>.broadcast();

  /// Payloads of tapped notifications (foreground + backgrounded app).
  /// Payloads are router locations (`/quiz`) or deep-link URIs (`civilcal://…`).
  Stream<String?> get taps => _taps.stream;

  Future<void> init() async {
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const ios = DarwinInitializationSettings();
    await _plugin.initialize(
      settings: const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (response) =>
          _taps.add(response.payload),
    );
  }

  Future<void> show({
    required int id,
    required String title,
    required String body,
    String? payload,
  }) =>
      _plugin.show(
        id: id,
        title: title,
        body: body,
        notificationDetails: const NotificationDetails(
          android: AndroidNotificationDetails(
            'civilcal_default',
            'CivilCal',
            importance: Importance.high,
          ),
        ),
        payload: payload,
      );

  /// Daily 8am study reminder — timezone-aware, survives reboot via `exactAllowWhileIdle`.
  Future<void> scheduleDailyQuizReminder() async {
    await _plugin.zonedSchedule(
      id: 1001,
      title: 'Daily Sprint ready ⚡',
      body: 'Your 10 calibrated MCQs are waiting — keep the streak alive!',
      scheduledDate: _nextInstanceOfTime(8, 0),
      notificationDetails: const NotificationDetails(
        android: AndroidNotificationDetails(
          'civilcal_daily',
          'Daily Quiz',
          importance: Importance.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.exactAllowWhileIdle,
      matchDateTimeComponents: DateTimeComponents.time,
      payload: '/quiz',
    );
  }

  tz.TZDateTime _nextInstanceOfTime(int hour, int minute) {
    final now = tz.TZDateTime.now(tz.local);
    var scheduled = tz.TZDateTime(tz.local, now.year, now.month, now.day, hour, minute);
    if (scheduled.isBefore(now)) scheduled = scheduled.add(const Duration(days: 1));
    return scheduled;
  }

  Future<void> cancelDaily() => _plugin.cancel(id: 1001);

  Future<void> dispose() async => _taps.close();
}
