library;

import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';

abstract final class CrashReporting {
  static Future<void> record(Object error, StackTrace st, {String? reason}) =>
      FirebaseCrashlytics.instance.recordError(error, st, reason: reason, fatal: false);

  static Future<void> log(String msg) => FirebaseCrashlytics.instance.log(msg);

  static void enableInDev() {
    if (kDebugMode) {
      FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
      PlatformDispatcher.instance.onError = (e, st) {
        FirebaseCrashlytics.instance.recordError(e, st, fatal: true);
        return true;
      };
    }
  }
}
