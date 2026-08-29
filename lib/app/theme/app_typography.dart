library;

import 'package:flutter/material.dart';

/// CivilCal typography — Material 3 scale + InstrumentSans.
/// Dark-first, engineering precision for formulas (monospace where needed).
abstract final class AppTypography {
  static const _base = 'InstrumentSans';

  // Display — heroic numbers (quiz score, level)
  static const displayLarge = TextStyle(
    fontFamily: _base,
    fontSize: 57,
    fontWeight: FontWeight.w700,
    letterSpacing: -0.25,
    height: 1.12,
  );
  static const displayMedium = TextStyle(
    fontFamily: _base,
    fontSize: 45,
    fontWeight: FontWeight.w600,
    height: 1.16,
  );

  // Headline — screen titles
  static const headlineLarge = TextStyle(
    fontFamily: _base,
    fontSize: 32,
    fontWeight: FontWeight.w600,
    height: 1.25,
  );
  static const headlineMedium = TextStyle(
    fontFamily: _base,
    fontSize: 28,
    fontWeight: FontWeight.w600,
    height: 1.28,
  );
  static const headlineSmall = TextStyle(
    fontFamily: _base,
    fontSize: 24,
    fontWeight: FontWeight.w600,
    height: 1.33,
  );

  // Title — cards, list headers
  static const titleLarge = TextStyle(
    fontFamily: _base,
    fontSize: 22,
    fontWeight: FontWeight.w600,
    height: 1.27,
  );
  static const titleMedium = TextStyle(
    fontFamily: _base,
    fontSize: 16,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.15,
    height: 1.5,
  );
  static const titleSmall = TextStyle(
    fontFamily: _base,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.42,
  );

  // Body — most content
  static const bodyLarge = TextStyle(
    fontFamily: _base,
    fontSize: 16,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.5,
    height: 1.5,
  );
  static const bodyMedium = TextStyle(
    fontFamily: _base,
    fontSize: 14,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.25,
    height: 1.42,
  );
  static const bodySmall = TextStyle(
    fontFamily: _base,
    fontSize: 12,
    fontWeight: FontWeight.w400,
    letterSpacing: 0.4,
    height: 1.33,
  );

  // Label — buttons, chips
  static const labelLarge = TextStyle(
    fontFamily: _base,
    fontSize: 14,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.1,
    height: 1.42,
  );
  static const labelMedium = TextStyle(
    fontFamily: _base,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.33,
  );
  static const labelSmall = TextStyle(
    fontFamily: _base,
    fontSize: 11,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.5,
    height: 1.45,
  );

  // Engineering — formulas (monospace)
  static const mono = TextStyle(
    fontFamily: 'RobotoMono',
    fontSize: 14,
    fontWeight: FontWeight.w500,
    height: 1.5,
  );
}
