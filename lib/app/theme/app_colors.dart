import 'package:flutter/material.dart';

/// CivilCal premium brand & design tokens — SaaS-grade, dark-first.
/// Palette is built for contrast, hierarchy and brand glow, not flat M3.
abstract final class AppColors {
  // ── Brand (cyan → blue premium ramp) ──────────────────────────────
  static const brand = Color(0xFF2EC5E5);
  static const brandDark = Color(0xFF0EA5C9);
  static const brandLight = Color(0xFF7DE9FA);
  static const brandDeep = Color(0xFF0891B2);
  static const brandAccent = Color(0xFF4D9FFF);
  static const brandGradientStart = Color(0xFF22D3EE);
  static const brandGradientEnd = Color(0xFF3B82F6);
  static const violet = Color(0xFF8B5CF6);
  static const violetLight = Color(0xFFA78BFA);

  // ── Background & Surface (deep navy, layered) ─────────────────────
  static const backgroundDark = Color(0xFF070B12);
  static const backgroundLight = Color(0xFFF4F7FB);
  static const surfaceDark = Color(0xFF0F151F);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const surfaceRaisedDark = Color(0xFF16202D);
  static const cardDark = Color(0xFF1B2735);
  static const cardDarkElevated = Color(0xFF223043);
  static const dividerDark = Color(0xFF2A3648);
  static const dividerLight = Color(0xFFE4EAF2);

  // ── Typography ────────────────────────────────────────────────────
  static const textPrimaryDark = Color(0xFFF2F6FC);
  static const textSecondaryDark = Color(0xFF9FB0C3);
  static const textTertiaryDark = Color(0xFF6B7C90);
  static const textPrimaryLight = Color(0xFF0F1B2E);
  static const textSecondaryLight = Color(0xFF4A5A6E);
  static const textTertiaryLight = Color(0xFF8494A7);

  // ── Glassmorphic ──────────────────────────────────────────────────
  static const glassDark = Color(0x0DFFFFFF);
  static const glassSurface = Color(0x14FFFFFF);
  static const glassBorder = Color(0x1FFFFFFF);
  static const glassBorderStrong = Color(0x33FFFFFF);

  // ── Feedback ──────────────────────────────────────────────────────
  static const correctGreen = Color(0xFF22C55E);
  static const correctGreenBg = Color(0x1A22C55E);
  static const wrongRed = Color(0xFFF87171);
  static const wrongRedBg = Color(0x1AF87171);
  static const warnAmber = Color(0xFFF59E0B);
  static const warnAmberBg = Color(0x1AF59E0B);

  // ── Gamification & Economy ────────────────────────────────────────
  static const xpGold = Color(0xFFF5B93F);
  static const coinYellow = Color(0xFFFACC15);
  static const streakOrange = Color(0xFFFB923C);
  static const lifelineCyan = Color(0xFF22D3EE);
  static const comboPurple = Color(0xFFA78BFA);
  static const comboFire = streakOrange;
  static const rankEmerald = Color(0xFF34D399);
  static const rankDiamond = Color(0xFF60A5FA);

  // ── Gradients ─────────────────────────────────────────────────────
  static const LinearGradient brandGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandGradientStart, brandGradientEnd],
  );
  static const LinearGradient premiumGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [brandGradientStart, brandGradientEnd, violet],
  );
  static const LinearGradient goldGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFDE68A), Color(0xFFF5B93F), Color(0xFFF59E0B)],
  );
  static const LinearGradient streakGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFB923C), Color(0xFFF43F5E)],
  );
  static const LinearGradient coinGradient = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFFDE047), Color(0xFFF59E0B)],
  );

  // Dark background with ambient brand aurora
  static const auroraBackground = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [
      Color(0xFF0A1120),
      backgroundDark,
      backgroundDark,
      Color(0xFF081019),
    ],
    stops: [0.0, 0.35, 0.75, 1.0],
  );
}
