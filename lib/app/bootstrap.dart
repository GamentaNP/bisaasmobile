library;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:sentry_flutter/sentry_flutter.dart';
import 'package:timezone/data/latest.dart' as tz;

import 'package:flutter_local_notifications/flutter_local_notifications.dart';

import '../core/analytics/crash_reporting.dart';
import '../core/device/system_ui_service.dart';
import '../core/errors/error_reporter.dart';
import '../core/logging/app_logger.dart';
import '../core/network/dio_client.dart';
import '../core/notifications/local_notification_service.dart';
import '../core/notifications/push_notification_service.dart';
import '../core/security/app_security.dart';
import '../core/security/token_manager.dart';
import '../core/storage/database/app_database.dart';
import '../core/storage/preferences.dart';
import 'config/feature_flags.dart';

Future<void> bootstrap() async {
  // Initialize Key-Value preferences
  await Preferences.init();

  // Timezone for local notifications.
  tz.initializeTimeZones();

  SystemUiService.setPreferredOrientations();
  await SystemUiService.setTransparentStatusBar();

  // Firebase — guarded (works without google-services.json in dev).
  try {
    await Firebase.initializeApp();
    // Data-only pushes while terminated/backgrounded — top-level handler.
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
    CrashReporting.enableInDev();
    AppLogger.i('Firebase initialized');
    // Remote Config flags — safe read fallbacks when this fails.
    await FeatureFlags.init();
  } catch (e, st) {
    AppLogger.w('Firebase not configured (dev without google-services.json): $e');
    if (kDebugMode) AppLogger.d(st);
  }

  // Warm Drift DB so the first screen never blocks on schema creation.
  AppDatabase.instance();

  // Local notifications — schedule daily 8am quiz reminder (timezone-aware, 00:00 server day is handled via streak API)
  try {
    final local = LocalNotificationService(FlutterLocalNotificationsPlugin());
    await local.init();
    await local.scheduleDailyQuizReminder();
    AppLogger.i('Local notifications ready — daily 8am scheduled');
  } catch (e) {
    AppLogger.w('Local notifications init failed (likely web): $e');
  }

  final tokens = TokenManager.shared;
  final existing = await tokens.readDeviceName();
  if (existing == null) {
    await TokenManager.resolveDeviceName(tokens);
  }
  await DioClient.init(tokens: tokens);

  // Honor the saved locale on the wire (Accept-Language) per AGENTS.md.
  final savedLocale = Preferences.instance.locale;
  if (savedLocale != null) DioClient.instance.setLocale(savedLocale);

  // Global flutter error handler → Crashlytics.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    CrashReporting.record(details.exception, details.stack ?? StackTrace.current);
  };
  PlatformDispatcher.instance.onError = (e, st) {
    CrashReporting.record(e, st, reason: 'PlatformDispatcher');
    return true;
  };

  // Sentry only in release builds compiled with a DSN — without init,
  // captureException would silently drop events.
  const sentryDsn = String.fromEnvironment('SENTRY_DSN');
  if (kReleaseMode && sentryDsn.isNotEmpty) {
    await SentryFlutter.init((options) {
      options.dsn = sentryDsn;
      options.tracesSampleRate = 0.2;
    });
    ErrorReporter.sentryEnabled = true;
  }

  // Security audit � freeRASP init then best-effort warn (no brick on false positive).
  await AppSecurity.init();
  await AppSecurity.auditOrWarn();

  // License for flutter_markdown etc. — no extra setup.
  await SystemChrome.setEnabledSystemUIMode(SystemUiMode.edgeToEdge);
}
