library;

import 'package:flutter/material.dart';

/// Shadows — Material 3 elevation via surfaceTint (no hard shadows).
/// CivilCal dark-first: shadows are subtle, elevation is tint.
abstract final class AppShadows {
  static const shadowSm = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 4, offset: Offset(0, 1)),
  ];
  static const shadowMd = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 8, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0F000000), blurRadius: 2, offset: Offset(0, 1)),
  ];
  static const shadowLg = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 16, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x0F000000), blurRadius: 4, offset: Offset(0, 2)),
  ];

  // Glass card glow (brand cyan ambient)
  static const glowBrand = [
    BoxShadow(color: Color(0x3322D3EE), blurRadius: 24, offset: Offset(0, 8)),
  ];
}
