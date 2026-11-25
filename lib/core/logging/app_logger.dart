library;

import 'package:flutter/foundation.dart' show kReleaseMode;
import 'package:logger/logger.dart';

/// Structured logger — verbose in dev, warnings and errors only in release.
/// Use `AppLogger.d/i/w/e` everywhere (never `print`).
abstract final class AppLogger {
  static final Logger _log = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 100,
      colors: !kReleaseMode,
      printEmojis: false,
    ),
    level: kReleaseMode ? Level.warning : Level.debug,
  );

  static void d(dynamic msg, [dynamic err, StackTrace? st]) => _log.d(msg, error: err, stackTrace: st);
  static void i(dynamic msg, [dynamic err, StackTrace? st]) => _log.i(msg, error: err, stackTrace: st);
  static void w(dynamic msg, [dynamic err, StackTrace? st]) => _log.w(msg, error: err, stackTrace: st);
  static void e(dynamic msg, [dynamic err, StackTrace? st]) => _log.e(msg, error: err, stackTrace: st);
}
