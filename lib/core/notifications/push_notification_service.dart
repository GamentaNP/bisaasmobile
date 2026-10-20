import 'dart:async';

import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart'
    show TargetPlatform, debugPrint, defaultTargetPlatform, kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../analytics/analytics_service.dart';
import '../consent/consent_gate.dart';
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
  PushNotificationService(
    this._messaging,
    this._dio, {
    FlutterLocalNotificationsPlugin? localPlugin,
    ConsentGatedAnalytics? analytics,
  }) : _local = localPlugin != null
           ? LocalNotificationService(localPlugin)
           : null,
       _analytics = analytics;
  final FirebaseMessaging _messaging;
  final Dio _dio;
  final LocalNotificationService? _local;
  final ConsentGatedAnalytics? _analytics;

  /// Emits the navigation target whenever the user opens a push (background
  /// tap, terminated-state tap, or foreground local-notification tap).
  Stream<String?> get navigationRequests => _nav.stream;
  final _nav = StreamController<String?>.broadcast();

  Future<void> init() async {
    // Push is optional. This method is called from an unawaited login flow,
    // so a device/plugin failure must never escape into the root zone.
    try {
      await _messaging.requestPermission(alert: true, badge: true, sound: true);
    } catch (e, st) {
      AppLogger.w('FCM permission request failed: $e', e, st);
    }

    // Foreground: show local notification + log. Stream subscription errors
    // are routed to onError rather than becoming unhandled async errors.
    try {
      FirebaseMessaging.onMessage.listen(
        _onMessageSafely,
        onError: (Object e, StackTrace st) =>
            _logListenerError('onMessage', e, st),
      );
    } catch (e, st) {
      _logListenerError('onMessage registration', e, st);
    }
    try {
      FirebaseMessaging.onMessageOpenedApp.listen(
        _onOpenedSafely,
        onError: (Object e, StackTrace st) =>
            _logListenerError('onMessageOpenedApp', e, st),
      );
    } catch (e, st) {
      _logListenerError('onMessageOpenedApp registration', e, st);
    }
    try {
      _messaging.onTokenRefresh.listen(
        _handleTokenRefresh,
        onError: (Object e, StackTrace st) =>
            _logListenerError('onTokenRefresh', e, st),
      );
    } catch (e, st) {
      _logListenerError('onTokenRefresh registration', e, st);
    }

    // Cold start from terminated via notification.
    try {
      final initial = await _messaging.getInitialMessage();
      if (initial != null) _onOpened(initial);
    } catch (e, st) {
      AppLogger.w('FCM initial message failed: $e', e, st);
    }

    // Local notification taps (foreground mirrors) → same navigation stream.
    try {
      _local?.taps.listen(
        _nav.add,
        onError: (Object e, StackTrace st) =>
            _logListenerError('local notification taps', e, st),
      );
    } catch (e, st) {
      _logListenerError('local notification taps registration', e, st);
    }
  }

  Future<void> _handleTokenRefresh(String token) async {
    try {
      AppLogger.i('FCM token refreshed len=${token.length}');
      await _analytics?.log(
        AnalyticsEvents.pushTokenRegister,
        params: {'len': token.length},
      );
      await _registerWithServer(token);
    } catch (e, st) {
      AppLogger.w('FCM token refresh handling failed: $e', e, st);
    }
  }

  void _logListenerError(String source, Object error, StackTrace stackTrace) {
    AppLogger.w('FCM $source failed: $error', error, stackTrace);
  }

  void _onMessageSafely(RemoteMessage message) {
    try {
      _onMessage(message);
    } catch (e, st) {
      _logListenerError('onMessage handler', e, st);
    }
  }

  void _onOpenedSafely(RemoteMessage message) {
    try {
      _onOpened(message);
    } catch (e, st) {
      _logListenerError('onMessageOpenedApp handler', e, st);
    }
  }

  Future<void> _logAnalytics(
    String event, {
    Map<String, Object>? params,
    required String source,
  }) async {
    try {
      await _analytics?.log(event, params: params);
    } catch (e, st) {
      AppLogger.w('FCM $source analytics failed: $e', e, st);
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    final local = _local;
    final notification = message.notification;
    if (local == null || notification == null) return;
    try {
      await local.show(
        id: message.hashCode & 0x7fffffff,
        title: notification.title ?? 'CivilCal',
        body: notification.body ?? '',
        payload:
            message.data['deep_link'] as String? ??
            message.data['route'] as String?,
      );
    } catch (e, st) {
      AppLogger.w('Local push notification failed: $e', e, st);
    }
  }

  /// Fetch the FCM token and register it with the server.
  ///
  /// Every call is guarded. A device without working Play Services (or with
  /// Firebase Installations unreachable) makes `getToken()` throw a
  /// `PlatformException` / `MissingPluginException` — observed live on a
  /// Redmi 6A as an **unhandled** `PlatformDispatcher` exception
  /// ("[firebase_messaging/unknown] java.io.IOException: FCM Registration
  /// failed!") on every login, because nothing here caught it. That is a
  /// legitimate device configuration, not an app error: push simply does not
  /// work, and the rest of the app must carry on as normal.
  Future<void> registerToken() async {
    final String? token;
    try {
      token = await _messaging.getToken();
    } catch (e) {
      AppLogger.w('FCM getToken unavailable (no Play Services?): $e');
      return;
    }
    if (token == null || token.isEmpty) {
      AppLogger.w('FCM returned no token; push registration skipped');
      return;
    }
    await _registerWithServer(token);
  }

  Future<void> _registerWithServer(String token) async {
    final platform = kIsWeb
        ? 'web'
        : (defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android');
    try {
      await _dio.post<dynamic>(
        '/device-tokens',
        data: {
          'token': token,
          'platform': platform,
        },
      );
      await _analytics?.log(AnalyticsEvents.pushTokenRegister);
      AppLogger.i('device-token registered len=${token.length}');
    } catch (e) {
      AppLogger.w('device-token register failed: $e');
    }
  }

  Future<void> unregisterToken() async {
    final String? token;
    try {
      token = await _messaging.getToken();
    } catch (e) {
      // Same failure mode as registerToken — nothing to unregister.
      AppLogger.w('FCM getToken unavailable during unregister: $e');
      return;
    }
    if (token == null || token.isEmpty) return;
    try {
      await _messaging.deleteToken();
      // Server expects DELETE /device-tokens/{token} per guide; fallback to body.
      try {
        await _dio.delete<dynamic>(
          '/device-tokens/${Uri.encodeComponent(token)}',
        );
      } catch (_) {
        await _dio.delete<dynamic>('/device-tokens', data: {'token': token});
      }
    } catch (e) {
      AppLogger.w('device-token unregister failed: $e');
    }
  }

  void _onMessage(RemoteMessage m) {
    AppLogger.i('FCM onMessage ${m.messageId} data=${m.data}');
    unawaited(
      _logAnalytics(
        AnalyticsEvents.notificationOpen,
        params: {'source': 'foreground'},
        source: 'foreground',
      ),
    );
    // Mirror to local notification so user sees banner in foreground (Android hides FCM heads-up when foregrounded).
    unawaited(_showLocalNotification(m));
  }

  void _onOpened(RemoteMessage m) {
    AppLogger.i('FCM onOpened ${m.data}');
    unawaited(
      _logAnalytics(
        AnalyticsEvents.notificationOpen,
        params: {'source': 'opened'},
        source: 'opened',
      ),
    );
    // Notification taps route via NotificationHandler.routeFor, falling back
    // to an explicit deep_link/route data payload when the server sends one.
    _nav.add(
      m.data['deep_link'] as String? ??
          m.data['route'] as String? ??
          NotificationHandler.routeFor(m.data),
    );
  }
}
