import 'package:flutter/services.dart';
import 'package:vibration/vibration.dart';

abstract final class HapticService {
  static Future<void> light() => HapticFeedback.lightImpact();
  static Future<void> medium() => HapticFeedback.mediumImpact();
  static Future<void> heavy() => HapticFeedback.heavyImpact();
  static Future<void> success() async {
    final has = await Vibration.hasVibrator();
    if (has) {
      await Vibration.vibrate(pattern: [0, 30, 60, 30]);
    } else {
      await HapticFeedback.heavyImpact();
    }
  }

  static Future<void> error() => HapticFeedback.vibrate();
}
