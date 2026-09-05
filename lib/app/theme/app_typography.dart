library;

import 'package:flutter/material.dart';

/// Duolongo typography — chunky, friendly, high-weight (w700–w800 titles,
/// w800 buttons). InstrumentSans stays the bundled offline-safe family;
/// the playful feel is carried by weight, size and tight line-heights.
abstract final class AppTypography {
  static const _base = 'InstrumentSans';

  // Display — heroic numbers (quiz score, level)
  static const displayLarge = TextStyle(
    fontFamily: _base,
    fontSize: 57,
    fontWeight: FontWeight.w800,
    letterSpacing: -0.25,
    height: 1.12,
  );
  static const displayMedium = TextStyle(
    fontFamily: _base,
    fontSize: 45,
    fontWeight: FontWeight.w800,
    height: 1.16,
  );

  // Headline — screen titles
  static const headlineLarge = TextStyle(
    fontFamily: _base,
    fontSize: 32,
    fontWeight: FontWeight.w800,
    height: 1.25,
  );
  static const headlineMedium = TextStyle(
    fontFamily: _base,
    fontSize: 28,
    fontWeight: FontWeight.w800,
    height: 1.28,
  );
  static const headlineSmall = TextStyle(
    fontFamily: _base,
    fontSize: 24,
    fontWeight: FontWeight.w800,
    height: 1.33,
  );

  // Title — cards, list headers
  static const titleLarge = TextStyle(
    fontFamily: _base,
    fontSize: 22,
    fontWeight: FontWeight.w800,
    height: 1.27,
  );
  static const titleMedium = TextStyle(
    fontFamily: _base,
    fontSize: 16,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.15,
    height: 1.5,
  );
  static const titleSmall = TextStyle(
    fontFamily: _base,
    fontSize: 14,
    fontWeight: FontWeight.w700,
    letterSpacing: 0.1,
    height: 1.42,
  );

  // Body — most content
  static const bodyLarge = TextStyle(
    fontFamily: _base,
    fontSize: 16,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.25,
    height: 1.5,
  );
  static const bodyMedium = TextStyle(
    fontFamily: _base,
    fontSize: 14,
    fontWeight: FontWeight.w500,
    letterSpacing: 0.15,
    height: 1.42,
  );
  static const bodySmall = TextStyle(
    fontFamily: _base,
    fontSize: 12,
    fontWeight: FontWeight.w600,
    letterSpacing: 0.3,
    height: 1.33,
  );

  // Label — buttons, chips (chunky caps style applied per-widget)
  static const labelLarge = TextStyle(
    fontFamily: _base,
    fontSize: 15,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
    height: 1.42,
  );
  static const labelMedium = TextStyle(
    fontFamily: _base,
    fontSize: 12,
    fontWeight: FontWeight.w800,
    letterSpacing: 0.5,
    height: 1.33,
  );
  static const labelSmall = TextStyle(
    fontFamily: _base,
    fontSize: 11,
    fontWeight: FontWeight.w800,
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
