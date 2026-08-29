import 'package:flutter/foundation.dart';
import 'package:sentry_flutter/sentry_flutter.dart';

import '../analytics/crash_reporting.dart';
import '../logging/app_logger.dart';

abstract final class ErrorReporter {
  static Future<void> report(
    Object error,
    StackTrace stack, {
    String? reason,
    Map<String, Object?>? context,
  }) async {
    AppLogger.e(reason ?? 'Unhandled error', error, stack);
    if (kReleaseMode) {
      await Sentry.captureException(error, stackTrace: stack, withScope: (s) {
        if (reason != null) s.setTag('reason', reason);
        if (context != null) {
          for (final e in context.entries) {
            s.setTag(e.key, '${e.value}');
          }
        }
      });
    } else {
      await CrashReporting.record(error, stack, reason: reason);
    }
  }
}
