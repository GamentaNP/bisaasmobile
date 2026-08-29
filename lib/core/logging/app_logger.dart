library;

import 'package:logger/logger.dart';

/// Structured logger — debug only in prod, verbose in dev.
/// Use `AppLogger.I`, `W`, `E` everywhere (never `print`).
abstract final class AppLogger {
  static final Logger _log = Logger(
    printer: PrettyPrinter(
      methodCount: 0,
      errorMethodCount: 5,
      lineLength: 100,
      colors: true,
      printEmojis: false,
    ),
    level: Level.debug,
  );

  static void d(dynamic msg, [dynamic err, StackTrace? st]) => _log.d(msg, error: err, stackTrace: st);
  static void i(dynamic msg, [dynamic err, StackTrace? st]) => _log.i(msg, error: err, stackTrace: st);
  static void w(dynamic msg, [dynamic err, StackTrace? st]) => _log.w(msg, error: err, stackTrace: st);
  static void e(dynamic msg, [dynamic err, StackTrace? st]) => _log.e(msg, error: err, stackTrace: st);
}
