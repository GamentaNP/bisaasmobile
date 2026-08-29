library;

import 'package:flutter/material.dart';

/// Motion — 60fps on Redmi Note 12 is the bar. All durations <300ms except page transitions.
abstract final class AppMotion {
  static const Duration fast = Duration(milliseconds: 120);
  static const Duration base = Duration(milliseconds: 200);
  static const Duration medium = Duration(milliseconds: 300);
  static const Duration slow = Duration(milliseconds: 400);

  static const Curve easeOut = Curves.easeOutCubic;
  static const Curve easeInOut = Curves.easeInOutCubic;
  static const Curve spring = Curves.easeOutBack;
  static const Curve emphasized = Curves.easeInOutCubicEmphasized;

  // Quiz-specific (answer reveal, streak fire)
  static const Duration quizReveal = Duration(milliseconds: 220);
  static const Duration streakPulse = Duration(milliseconds: 600);
}
