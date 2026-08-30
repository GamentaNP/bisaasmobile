import 'package:sentry_flutter/sentry_flutter.dart';

import '../analytics/crash_reporting.dart';
import '../logging/app_logger.dart';

/// Central reporting funnel — always logs locally; ships to Crashlytics
/// (all flavors) and Sentry (release builds compiled with SENTRY_DSN).
abstract final class ErrorReporter {
  /// Set by bootstrap() when Sentry was actually initialized —
  /// captureException without init is a silent no-op.
  static bool sentryEnabled = false;

  static Future<void> report(
    Object error,
    StackTrace stack, {
    String? reason,
    Map<String, Object?>? context,
  }) async {
    AppLogger.e(reason ?? 'Unhandled error', error, stack);
    await CrashReporting.record(error, stack, reason: reason);
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
