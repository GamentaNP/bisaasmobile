library;

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:timezone/data/latest.dart' as tz;

import '../core/analytics/crash_reporting.dart';
import '../core/device/system_ui_service.dart';
import '../core/logging/app_logger.dart';
import '../core/network/dio_client.dart';
import '../core/security/token_manager.dart';

Future<void> bootstrap() async {
  // Timezone for local notifications.
  tz.initializeTimeZones();

  SystemUiService.setPreferredOrientations();
  await SystemUiService.setTransparentStatusBar();

  // Firebase — guarded (works without google-services.json in dev).
  try {
    await Firebase.initializeApp();
    CrashReporting.enableInDev();
    AppLogger.i('Firebase initialized');
  } catch (e, st) {
    AppLogger.w('Firebase not configured (dev without google-services.json): $e');
    if (kDebugMode) AppLogger.d(st);
  }

  final tokens = TokenManager();
  final existing = await tokens.readDeviceName();
  if (existing == null) {
    await tokens.setDeviceName('android-${DateTime.now().millisecondsSinceEpoch}');
  }
  await DioClient.init(tokens: tokens);

  // Global flutter error handler → Crashlytics.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    CrashReporting.record(details.exception, details.stack ?? StackTrace.current);
  };
  PlatformDispatcher.instance.onError = (e, st) {
    CrashReporting.record(e, st, reason: 'PlatformDispatcher');
    return true;
  };

  // License for flutter_markdown etc. — no extra setup.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}
