import 'package:dio/dio.dart';
import 'package:firebase_messaging/firebase_messaging.dart';

import '../logging/app_logger.dart';

class PushNotificationService {
  PushNotificationService(this._messaging, this._dio);
  final FirebaseMessaging _messaging;
  final Dio _dio;

  Future<void> init() async {
    await _messaging.requestPermission();
    FirebaseMessaging.onMessage.listen(_onMessage);
    FirebaseMessaging.onMessageOpenedApp.listen(_onOpened);
  }

  Future<void> registerToken() async {
    final token = await _messaging.getToken();
    if (token == null) return;
    try {
      await _dio.post<dynamic>('/device-tokens', data: {
        'token': token,
        'platform': 'android',
      });
    } catch (e) {
      AppLogger.w('device-token register failed: $e');
    }
  }

  Future<void> unregisterToken() async {
    final token = await _messaging.getToken();
    if (token == null) return;
    try {
      await _messaging.deleteToken();
      await _dio.delete<dynamic>('/device-tokens', data: {'token': token});
    } catch (e) {
      AppLogger.w('device-token unregister failed: $e');
    }
  }

  void _onMessage(RemoteMessage m) => AppLogger.i('FCM onMessage ${m.messageId}');
  void _onOpened(RemoteMessage m) => AppLogger.i('FCM onOpened ${m.data}');
}
