

import 'dart:async';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:timezone/timezone.dart' as tz;
import '../../app/localization/l10n.dart';

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
    await _ensureAndroidChannels();
  }

  /// Pre-creates the Android channels. A background FCM `notification` payload
  /// can arrive before any foreground mirror has ever run; the manifest points
  /// `default_notification_channel_id` at `civilcal_default`, and without this
  /// the channel would not exist yet — FCM would invent its own
  /// "Miscellaneous" channel the user cannot silence per-feature.
  Future<void> _ensureAndroidChannels() async {
    final impl = _plugin
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>();
    if (impl == null) return;
    final defaultChannel = AndroidNotificationChannel(
      'civilcal_default',
      // Brand name — the same proper noun in every locale.
      'CivilCal',
      importance: Importance.high,
    );
    final dailyChannel = AndroidNotificationChannel(
      'civilcal_daily',
      appL10n().notificationChannelDaily,
      importance: Importance.high,
    );
    await impl.createNotificationChannel(defaultChannel);
    await impl.createNotificationChannel(dailyChannel);
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

  /// Daily 8am study reminder — timezone-aware, survives reboot.
  ///
  /// Deliberately `inexactAllowWhileIdle`, not `exactAllowWhileIdle`. The
  /// exact modes need `SCHEDULE_EXACT_ALARM` / `USE_EXACT_ALARM`, which
  /// throw `PlatformException: exact_alarms_not_permitted` on Android 12+
  /// without a user-grant flow, and are Play-policy restricted to alarm-clock
  /// and calendar apps. A daily study nudge has no need for second-precision,
  /// and the inexact mode is battery-friendly by design.
  Future<void> scheduleDailyQuizReminder() async {
    await _plugin.zonedSchedule(
      id: 1001,
      title: appL10n().notificationDailyTitle,
      body: appL10n().notificationDailyBody,
      scheduledDate: _nextInstanceOfTime(8, 0),
      notificationDetails: NotificationDetails(
        android: AndroidNotificationDetails(
          'civilcal_daily',
          appL10n().notificationChannelDaily,
          importance: Importance.high,
        ),
      ),
      androidScheduleMode: AndroidScheduleMode.inexactAllowWhileIdle,
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
