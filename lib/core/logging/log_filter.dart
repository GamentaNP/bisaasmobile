import 'package:logger/logger.dart';
import 'package:flutter/foundation.dart';

/// Only verbose in debug; warning+ in release.
class AppLogFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    if (kDebugMode) return true;
    return event.level.index >= Level.warning.index;
  }
}
