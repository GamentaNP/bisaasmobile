import 'package:flutter/material.dart';

/// BiSaaS design tokens — the mobile mirror of the web app's canonical palette.
///
/// Source of truth: `C:\laragon\www\bisaas\DESIGN.md` and
/// `resources/css/app.css` (`:root` light tokens). Primary is the web's
/// electric indigo/blue, surfaces are white/slate. The old Duolingo-green
/// ramp in `bisaas/docs/mobileapp/duilongo-sample-app-ui` is superseded.
/// The chunky bottom-border extrusion is kept as the mobile interaction idiom.
abstract final class AppColors {
  // ── Brand (web primary — electric indigo/blue) ──────────────────────
  static const brand = Color(0xFF4B62ED);
  static const brandDark = Color(0xFF4338CA);
  static const brandLight = Color(0xFF818CF8);
  static const brandDeep = Color(0xFF312E81);
  static const brandAccent = Color(0xFF0EA5E9);
  static const brandGradientStart = Color(0xFF4B62ED);
  static const brandGradientEnd = Color(0xFF6366F1);
  static const violet = Color(0xFFA855F7);
  static const violetLight = Color(0xFFC4B5FD);

  // Chunky extrusion shadows — the "3D" partner of each fill color.
  static const brandShadow = Color(0xFF3730A3);
  static const blueShadow = Color(0xFF0369A1);
  static const purpleShadow = Color(0xFF7E22CE);
  static const warningShadow = Color(0xFFB45309);
  static const errorShadow = Color(0xFFB91C1C);
  static const goldShadow = Color(0xFFB45309);

  // ── Background & Surface (flat white, layered grays) ───────────────
  static const backgroundDark = Color(0xFF131F24);
  static const backgroundLight = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF1A2B33);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceRaisedDark = Color(0xFF202F36);
  static const cardDark = Color(0xFF202F36);
  static const cardDarkElevated = Color(0xFF2A3B44);
  static const dividerDark = Color(0xFF37464F);
  static const dividerLight = Color(0xFFE2E4E8);
  static const surfaceSecondary = Color(0xFFF3F4F9);
  static const surfaceTertiary = Color(0xFFE2E4E8);

  // ── Typography ────────────────────────────────────────────────────
  static const textPrimaryDark = Color(0xFFF1F7FB);
  static const textSecondaryDark = Color(0xFFB0C2C9);
  static const textTertiaryDark = Color(0xFF7E959F);
  static const textPrimaryLight = Color(0xFF141720);
  static const textSecondaryLight = Color(0xFF656A77);
  static const textTertiaryLight = Color(0xFF9CA3AF);

  // ── Glassmorphic (legacy token names; now subtle flat tints) ──────
  static const glassDark = Color(0x0D4B4B4B);
  static const glassSurface = Color(0x0A4B4B4B);
  static const glassBorder = Color(0xFFE5E5E5);
  static const glassBorderStrong = Color(0xFFAFAFAF);

  // ── Feedback (solid Duolingo fills + soft pastel bgs) ─────────────
  static const correctGreen = Color(0xFF059669);
  static const correctGreenBg = Color(0xFFD1FAE5);
  static const wrongRed = Color(0xFFE7000B);
  static const wrongRedBg = Color(0xFFFEE2E2);
  static const warnAmber = Color(0xFFD97706);
  static const warnAmberBg = Color(0xFFFEF3C7);
  static const selectedBlueBg = Color(0xFFEEF2FF);
  static const selectedGreenBg = Color(0xFFECFDF5);

  // ── Gamification & Economy ────────────────────────────────────────
  static const xpGold = Color(0xFFFFC800);
  static const coinYellow = Color(0xFFFFC800);
  static const streakOrange = Color(0xFFD97706);
  static const lifelineCyan = Color(0xFF0EA5E9);
  static const comboPurple = Color(0xFFA855F7);
  static const comboFire = streakOrange;
  static const rankEmerald = Color(0xFF059669);
  static const rankDiamond = Color(0xFF0EA5E9);
  static const heartRed = Color(0xFFE7000B);

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

  /// Category-card accents for the course grid — cycled by index. One home
  /// for the palette so the calculator domains and the courses stay in the
  /// same color language.
  static const List<Color> coursePalette = [
    Color(0xFFF59E0B),
    Color(0xFF8B5CF6),
    Color(0xFF06B6D4),
    Color(0xFF0EA5E9),
    Color(0xFFEF4444),
    Color(0xFF6366F1),
    Color(0xFF64748B),
    Color(0xFF22D3EE),
    Color(0xFFEAB308),
    Color(0xFFEC4899),
  ];

  /// Calculator discipline → accent. Keyed by the server's domain slug; a
  /// domain missing from the map falls back to [brand] at the call site.
  static const Map<String, Color> calculatorDomainColors = {
    'civil': Color(0xFF0EA5E9),
    'structural': Color(0xFF8B5CF6),
    'electrical': Color(0xFFEAB308),
    'plumbing': Color(0xFF06B6D4),
    'hvac': Color(0xFF10B981),
    'fire': Color(0xFFEF4444),
    'estimation': Color(0xFFF59E0B),
    'medical-gas': Color(0xFFEC4899),
  };

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
