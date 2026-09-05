import 'package:flutter/material.dart';

/// Duolongo ("Duolingo-style") tactile design tokens — playful, chunky, LIGHT-first.
/// Every primary surface uses the hard bottom-border extrusion (borderBottom 3-6)
/// instead of soft shadows. See bisaas/docs/mobileapp/duilongo-sample-app-ui.
abstract final class AppColors {
  // ── Brand (Duolingo green ramp) ─────────────────────────────────────
  static const brand = Color(0xFF58CC02);
  static const brandDark = Color(0xFF46A302);
  static const brandLight = Color(0xFF89E219);
  static const brandDeep = Color(0xFF3E9A01);
  static const brandAccent = Color(0xFF1CB0F6);
  static const brandGradientStart = Color(0xFF58CC02);
  static const brandGradientEnd = Color(0xFF89E219);
  static const violet = Color(0xFFCE82FF);
  static const violetLight = Color(0xFFE0B8FF);

  // Chunky extrusion shadows — the "3D" partner of each fill color.
  static const brandShadow = Color(0xFF46A302);
  static const blueShadow = Color(0xFF1899D6);
  static const purpleShadow = Color(0xFFA560D0);
  static const warningShadow = Color(0xFFE08600);
  static const errorShadow = Color(0xFFD63A3A);
  static const goldShadow = Color(0xFFDDB000);

  // ── Background & Surface (flat white, layered grays) ───────────────
  static const backgroundDark = Color(0xFF131F24);
  static const backgroundLight = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF1A2B33);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceRaisedDark = Color(0xFF202F36);
  static const cardDark = Color(0xFF202F36);
  static const cardDarkElevated = Color(0xFF2A3B44);
  static const dividerDark = Color(0xFF37464F);
  static const dividerLight = Color(0xFFE5E5E5);
  static const surfaceSecondary = Color(0xFFF7F7F7);
  static const surfaceTertiary = Color(0xFFE5E5E5);

  // ── Typography ────────────────────────────────────────────────────
  static const textPrimaryDark = Color(0xFFF1F7FB);
  static const textSecondaryDark = Color(0xFFB0C2C9);
  static const textTertiaryDark = Color(0xFF7E959F);
  static const textPrimaryLight = Color(0xFF4B4B4B);
  static const textSecondaryLight = Color(0xFF777777);
  static const textTertiaryLight = Color(0xFFAFAFAF);

  // ── Glassmorphic (legacy token names; now subtle flat tints) ──────
  static const glassDark = Color(0x0D4B4B4B);
  static const glassSurface = Color(0x0A4B4B4B);
  static const glassBorder = Color(0xFFE5E5E5);
  static const glassBorderStrong = Color(0xFFAFAFAF);

  // ── Feedback (solid Duolingo fills + soft pastel bgs) ─────────────
  static const correctGreen = Color(0xFF58CC02);
  static const correctGreenBg = Color(0xFFD7FFC1);
  static const wrongRed = Color(0xFFFF4B4B);
  static const wrongRedBg = Color(0xFFFFDADA);
  static const warnAmber = Color(0xFFFF9600);
  static const warnAmberBg = Color(0xFFFFF1D9);
  static const selectedBlueBg = Color(0xFFDDF4FE);
  static const selectedGreenBg = Color(0xFFEFFFE0);

  // ── Gamification & Economy ────────────────────────────────────────
  static const xpGold = Color(0xFFFFC800);
  static const coinYellow = Color(0xFFFFC800);
  static const streakOrange = Color(0xFFFF9600);
  static const lifelineCyan = Color(0xFF1CB0F6);
  static const comboPurple = Color(0xFFCE82FF);
  static const comboFire = streakOrange;
  static const rankEmerald = Color(0xFF58CC02);
  static const rankDiamond = Color(0xFF1CB0F6);
  static const heartRed = Color(0xFFFF4B4B);

  // ── Gradients (kept for hero headers; body UI stays flat) ─────────
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandGradientStart, brandGradientEnd],
  );
  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1CB0F6), Color(0xFFCE82FF)],
  );
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFDE59), Color(0xFFFFC800)],
  );
  static const LinearGradient streakGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFF9600), Color(0xFFFF6A00)],
  );
  static const LinearGradient coinGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFFDE59), Color(0xFFFF9600)],
  );
  // Info-blue hero (results "well done", streak intro)
  static const LinearGradient infoGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF1CB0F6), Color(0xFF4FCBFF)],
  );

  // Dark background (Duolingo night navy)
  static const auroraBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF16242B),
      backgroundDark,
      backgroundDark,
      Color(0xFF101B20),
    ],
    stops: [0.0, 0.35, 0.75, 1.0],
  );
}
