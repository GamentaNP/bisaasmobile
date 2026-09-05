library;

import 'package:flutter/material.dart';

/// Shadows — Material 3 elevation via surfaceTint (no hard shadows).
/// CivilCal dark-first: shadows are subtle, elevation is tint,
/// brand elements carry a cyan glow instead of black drop shadows.
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
    BoxShadow(color: Color(0x4D22D3EE), blurRadius: 24, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x3322D3EE), blurRadius: 6, offset: Offset(0, 2)),
  ];

  // Soft violet glow — secondary/achievement surfaces
  static const glowViolet = [
    BoxShadow(color: Color(0x408B5CF6), blurRadius: 24, offset: Offset(0, 8)),
  ];

  // Gold glow — coins, XP, premium badges
  static const glowGold = [
    BoxShadow(color: Color(0x40F5B93F), blurRadius: 20, offset: Offset(0, 6)),
  ];

  // Card elevation (light mode friendly)
  static const cardLight = [
    BoxShadow(
      color: Color(0x140F1B2E),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
    BoxShadow(color: Color(0x0A0F1B2E), blurRadius: 3, offset: Offset(0, 1)),
  ];
}
