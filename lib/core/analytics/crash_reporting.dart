library;

import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

/// Crashlytics wrapper — every entry point no-ops safely when Firebase was
/// never initialized (dev builds without google-services.json).
abstract final class CrashReporting {
  static bool get _available => Firebase.apps.isNotEmpty;

  static Future<void> record(Object error, StackTrace st, {String? reason}) {
    if (!_available) return Future<void>.value();
    return FirebaseCrashlytics.instance
        .recordError(error, st, reason: reason, fatal: false);
  }

  static Future<void> log(String msg) {
    if (!_available) return Future<void>.value();
    return FirebaseCrashlytics.instance.log(msg);
  }

  static void enableInDev() {
    if (kDebugMode && _available) {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (e, st) {
        FirebaseCrashlytics.instance.recordError(e, st, fatal: true);
        return true;
      };
    }
  }
}
