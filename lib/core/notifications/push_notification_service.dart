import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../analytics/analytics_service.dart';
import '../logging/app_logger.dart';
import 'local_notification_service.dart';
import 'notification_handler.dart';

/// Background/terminated message handler — MUST be top-level (annotated
/// @pragma('vm:entry-point') so release builds keep it). Requires
/// `FirebaseMessaging.onBackgroundMessage` registration before runApp.
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  // No Flutter plugin UI work here; FCM data payloads are delivered as
  // system notifications by the native layer when `notification` is present.
  debugPrint('FCM background message ${message.messageId}');
}

class PushNotificationService {
  PushNotificationService(this._messaging, this._dio, {FlutterLocalNotificationsPlugin? localPlugin, AnalyticsService? analytics})
      : _local = localPlugin != null ? LocalNotificationService(localPlugin) : null,
        _analytics = analytics;
  final FirebaseMessaging _messaging;
  final Dio _dio;
  final LocalNotificationService? _local;
  final AnalyticsService? _analytics;

  /// Emits the navigation target whenever the user opens a push (background
  /// tap, terminated-state tap, or foreground local-notification tap).
  Stream<String?> get navigationRequests => _nav.stream;
  final _nav = StreamController<String?>.broadcast();

  Future<void> init() async {
    await _messaging.requestPermission(alert: true, badge: true, sound: true);
    // Foreground: show local notification + log.
    FirebaseMessaging.onMessage.listen(_onMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onOpened);
    FirebaseMessaging.instance.onTokenRefresh.listen((t) async {
      AppLogger.i('FCM token refreshed len=${t.length}');
      await _analytics?.log(AnalyticsEvents.pushTokenRegister, params: {'len': t.length});
      await _registerWithServer(t);
    });
    // Cold start from terminated via notification.
    final initial = await _messaging.getInitialMessage();
    if (initial != null) _onOpened(initial);
    // Local notification taps (foreground mirrors) → same navigation stream.
    _local?.taps.listen(_nav.add);
  }

  Future<void> registerToken() async {
    final token = await _messaging.getToken();
    if (token == null) return;
    await _registerWithServer(token);
  }

  Future<void> _registerWithServer(String token) async {
    final platform = kIsWeb ? 'web' : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android');
    try {
      await _dio.post<dynamic>('/device-tokens', data: {
        'token': token,
        'platform': platform,
      });
      await _analytics?.log(AnalyticsEvents.pushTokenRegister);
      AppLogger.i('device-token registered len=${token.length}');
    } catch (e) {
      AppLogger.w('device-token register failed: $e');
    }
  }

  Future<void> unregisterToken() async {
    final token = await _messaging.getToken();
    if (token == null) return;
    try {
      await _messaging.deleteToken();
      // Server expects DELETE /device-tokens/{token} per guide; fallback to body.
      try {
        await _dio.delete<dynamic>('/device-tokens/${Uri.encodeComponent(token)}');
      } catch (_) {
        await _dio.delete<dynamic>('/device-tokens', data: {'token': token});
      }
    } catch (e) {
      AppLogger.w('device-token unregister failed: $e');
    }
  }

  void _onMessage(RemoteMessage m) {
    AppLogger.i('FCM onMessage ${m.messageId} data=${m.data}');
    _analytics?.log(AnalyticsEvents.notificationOpen, params: {'source': 'foreground'});
    // Mirror to local notification so user sees banner in foreground (Android hides FCM heads-up when foregrounded).
    if (_local != null && m.notification != null) {
      _local.show(
        id: m.hashCode & 0x7fffffff,
        title: m.notification!.title ?? 'CivilCal',
        body: m.notification!.body ?? '',
        payload: m.data['deep_link'] as String? ?? m.data['route'] as String?,
      );
    }
  }

  void _onOpened(RemoteMessage m) {
    AppLogger.i('FCM onOpened ${m.data}');
    _analytics?.log(AnalyticsEvents.notificationOpen, params: {'source': 'opened'});
    // Notification taps route via NotificationHandler.routeFor, falling back
    // to an explicit deep_link/route data payload when the server sends one.
    _nav.add(m.data['deep_link'] as String? ??
        m.data['route'] as String? ??
        NotificationHandler.routeFor(m.data));
  }
}
