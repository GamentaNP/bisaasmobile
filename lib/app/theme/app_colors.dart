import 'package:flutter/material.dart';

/// CivilCal brand & design tokens — see `FLUTTER_APP_MASTER_PLAN_2026.md:5.2` + `mobileapp-design-reserch-flutter.md`.
abstract final class AppColors {
  // Brand
  static const brand = Color(0xFF22D3EE);
  static const brandDark = Color(0xFF0EA5C9);
  static const brandLight = Color(0xFF67E8F9);

  // Background & Surface
  static const backgroundDark = Color(0xFF0B0F17);
  static const backgroundLight = Color(0xFFF0F4F8);
  static const surfaceDark = Color(0xFF131920);
  static const surfaceLight = Color(0xFFFFFFFF);
  static const cardDark = Color(0xFF1E293B);
  static const dividerDark = Color(0xFF334155);

  // Typography / Content
  static const textPrimaryDark = Color(0xFFF8FAFC);
  static const textSecondaryDark = Color(0xFF94A3B8);
  static const textTertiaryDark = Color(0xFF64748B);

  // Glassmorphic styling
  static const glassDark = Color(0x0DFFFFFF);
  static const glassSurface = Color(0x14FFFFFF);
  static const glassBorder = Color(0x1AFFFFFF);

  // Gamification & Quiz feedback
  static const correctGreen = Color(0xFF10B981);
  static const correctGreenBg = Color(0x1A10B981);
  static const wrongRed = Color(0xFFEF4444);
  static const wrongRedBg = Color(0x1AEF4444);
  static const xpGold = Color(0xFFEAB308);
  static const coinYellow = Color(0xFFFACC15);
  static const streakOrange = Color(0xFFF97316);
  static const lifelineCyan = Color(0xFF06B6D4);
  static const comboPurple = Color(0xFFA855F7);
  // Alias used by quiz combo display
  static const comboFire = streakOrange;
}
