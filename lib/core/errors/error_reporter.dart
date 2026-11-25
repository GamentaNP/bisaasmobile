import 'package:sentry_flutter/sentry_flutter.dart';

import '../analytics/crash_reporting.dart';
import '../logging/app_logger.dart';

/// Central reporting funnel — always logs locally; ships to Crashlytics
/// (all flavors) and Sentry (release builds compiled with SENTRY_DSN).
abstract final class ErrorReporter {
  /// Set by bootstrap() when Sentry was actually initialized —
  /// captureException without init is a silent no-op.
  static bool sentryEnabled = false;

  /// Reports a fatal crash through the same funnel as every other error, so
  /// context is attached and Sentry actually receives it.
  static Future<void> reportFatal(
    Object error,
    StackTrace stack, {
    String? reason,
    Map<String, Object?>? context,
  }) async {
    await _send(error, stack, reason, context, fatal: true);
  }

  static Future<void> report(
    Object error,
    StackTrace stack, {
    String? reason,
    Map<String, Object?>? context,
  }) async {
    await _send(error, stack, reason, context, fatal: false);
  }

  static Future<void> _send(
    Object error,
    StackTrace stack,
    String? reason,
    Map<String, Object?>? context, {
    required bool fatal,
  }) async {
    AppLogger.e(reason ?? 'Unhandled error', error, stack);
    if (context != null && context.isNotEmpty) {
      await CrashReporting.setContext(
        context.map((key, value) => MapEntry(key, value ?? 'null')),
      );
    }
    await (fatal
        ? CrashReporting.recordFatal(error, stack, reason: reason)
        : CrashReporting.record(error, stack, reason: reason));
    if (!sentryEnabled) return;
    try {
      await Sentry.captureException(error, stackTrace: stack, withScope: (s) {
        if (reason != null) s.setTag('reason', reason);
        if (context != null) {
          for (final e in context.entries) {
            s.setTag(e.key, '${e.value}');
          }
        }
      });
    } catch (_) {
      // Reporting must never throw from an error path.
    }
  }
}
