library;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radii.dart';
import 'app_typography.dart';

/// CivilCal premium theme — SaaS-grade dark-first Material 3.
/// Every component is themed here so screens stay consistent without
/// per-screen styling; brand gradients + glass tokens do the heavy lifting.
abstract final class AppTheme {
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData get light => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme.fromSeed(
      seedColor: AppColors.brand,
      brightness: brightness,
      primary: AppColors.brand,
      secondary: AppColors.violet,
      surface: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      error: isDark ? AppColors.wrongRed : const Color(0xFFDC2626),
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      // ── AppBar: glass tint, no hard elevation ───────────────────────────
      appBarTheme: AppBarTheme(
        backgroundColor: isDark
            ? AppColors.backgroundDark.withValues(alpha: 0.85)
            : AppColors.backgroundLight.withValues(alpha: 0.85),
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
        iconTheme: IconThemeData(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      // ── Text ────────────────────────────────────────────────────────────
      textTheme: _textTheme(brightness),
      // ── Cards: glass + border, no flat M3 elevation ─────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark
            ? AppColors.glassSurface
            : Colors.white.withValues(alpha: 0.9),
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.card,
          side: BorderSide(
            color: isDark
                ? AppColors.glassBorder
                : AppColors.dividerLight,
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      // ── Buttons ─────────────────────────────────────────────────────────
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          disabledBackgroundColor: scheme.surfaceContainerHighest,
          disabledForegroundColor: scheme.onSurfaceVariant,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.mdAll),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: isDark
              ? AppColors.surfaceRaisedDark
              : Colors.white,
          foregroundColor:
              isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.mdAll,
            side: BorderSide(
              color: isDark ? AppColors.glassBorder : AppColors.dividerLight,
            ),
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brand,
          side: const BorderSide(color: AppColors.brandDark, width: 1.2),
          minimumSize: const Size(64, 48),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.mdAll),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brand,
          textStyle: AppTypography.labelLarge,
        ),
      ),
      // ── Inputs: filled glass with brand focus ring ──────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark
            ? AppColors.glassSurface
            : AppColors.backgroundLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
        prefixIconColor:
            isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        suffixIconColor: AppColors.brand,
        border: OutlineInputBorder(
          borderRadius: AppRadii.mdAll,
          borderSide: BorderSide(
            color: isDark ? AppColors.glassBorder : AppColors.dividerLight,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.mdAll,
          borderSide: BorderSide(
            color: isDark ? AppColors.glassBorder : AppColors.dividerLight,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.mdAll,
          borderSide: const BorderSide(color: AppColors.brand, width: 1.6),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadii.mdAll,
          borderSide: BorderSide(color: AppColors.wrongRed),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadii.mdAll,
          borderSide: BorderSide(color: AppColors.wrongRed, width: 1.6),
        ),
      ),
      // ── Chips: pill glass ───────────────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor: isDark ? AppColors.glassSurface : Colors.white,
        side: BorderSide(
          color: isDark ? AppColors.glassBorder : AppColors.dividerLight,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.pillAll),
        labelStyle: AppTypography.labelMedium.copyWith(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
        secondaryLabelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.brand,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      ),
      // ── Navigation bar: glass pill indicator ────────────────────────────
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor:
            isDark ? AppColors.surfaceDark.withValues(alpha: 0.96) : Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: AppColors.brand.withValues(alpha: 0.18),
        indicatorShape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        iconTheme: WidgetStateProperty.resolveWith(
          (states) => IconThemeData(
            color: states.contains(WidgetState.selected)
                ? AppColors.brand
                : isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
          ),
        ),
        labelTextStyle: WidgetStateProperty.resolveWith(
          (states) => AppTypography.labelSmall.copyWith(
            color: states.contains(WidgetState.selected)
                ? AppColors.brand
                : isDark
                    ? AppColors.textTertiaryDark
                    : AppColors.textTertiaryLight,
            fontWeight:
                states.contains(WidgetState.selected) ? FontWeight.w700 : FontWeight.w500,
          ),
        ),
      ),
      // ── Bottom sheets: rounded glass ────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: isDark
            ? AppColors.surfaceRaisedDark
            : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(
          borderRadius: AppRadii.sheet,
        ),
        showDragHandle: true,
        dragHandleColor:
            isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
      ),
      // ── Dialogs ─────────────────────────────────────────────────────────
      dialogTheme: DialogThemeData(
        backgroundColor: isDark ? AppColors.surfaceRaisedDark : Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.xlAll),
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
      ),
      // ── Snackbars: elevated glass ───────────────────────────────────────
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.surfaceRaisedDark : const Color(0xFF1B2735),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: isDark ? AppColors.textPrimaryDark : Colors.white,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.mdAll),
        elevation: 0,
      ),
      // ── Progress: brand color, no spin-artifacts ────────────────────────
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.brand,
        linearTrackColor: isDark
            ? AppColors.glassSurface
            : AppColors.dividerLight,
        circularTrackColor: Colors.transparent,
      ),
      // ── Switches / sliders: brand ───────────────────────────────────────
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? Colors.white
              : isDark
                  ? AppColors.textTertiaryDark
                  : Colors.white,
        ),
        trackColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.brand
              : isDark
                  ? AppColors.surfaceRaisedDark
                  : AppColors.dividerLight,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.brand,
        inactiveTrackColor:
            isDark ? AppColors.glassBorder : AppColors.dividerLight,
        thumbColor: AppColors.brand,
        overlayColor: AppColors.brand.withValues(alpha: 0.12),
        trackHeight: 4,
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        thickness: 1,
        space: 1,
      ),
      listTileTheme: ListTileThemeData(
        iconColor:
            isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        textColor: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        titleTextStyle: AppTypography.titleSmall,
        subtitleTextStyle: AppTypography.bodySmall.copyWith(
          color: isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.mdAll),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.brand,
        unselectedLabelColor:
            isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
        indicatorColor: AppColors.brand,
        labelStyle: AppTypography.labelLarge,
        unselectedLabelStyle: AppTypography.labelLarge,
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.brand,
        foregroundColor: Colors.white,
        elevation: 0,
        highlightElevation: 0,
        shape: RoundedRectangleBorder(borderRadius: AppRadii.mdAll),
      ),
      // ── Default shadows: soft tinted, never hard black ──────────────────
      shadowColor: isDark
          ? Colors.black.withValues(alpha: 0.5)
          : Colors.black.withValues(alpha: 0.12),
      splashFactory: InkRipple.splashFactory,
    );
  }

  static TextTheme _textTheme(Brightness brightness) {
    final primary =
        brightness == Brightness.dark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondary =
        brightness == Brightness.dark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final tertiary =
        brightness == Brightness.dark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;

    TextStyle apply(TextStyle base) => base;

    return TextTheme(
      displayLarge: apply(AppTypography.displayLarge).copyWith(color: primary),
      displayMedium: apply(AppTypography.displayMedium).copyWith(color: primary),
      headlineLarge: apply(AppTypography.headlineLarge).copyWith(color: primary),
      headlineMedium: apply(AppTypography.headlineMedium).copyWith(color: primary),
      headlineSmall: apply(AppTypography.headlineSmall).copyWith(color: primary),
      titleLarge: apply(AppTypography.titleLarge).copyWith(color: primary),
      titleMedium: apply(AppTypography.titleMedium).copyWith(color: primary),
      titleSmall: apply(AppTypography.titleSmall).copyWith(color: primary),
      bodyLarge: apply(AppTypography.bodyLarge).copyWith(color: secondary),
      bodyMedium: apply(AppTypography.bodyMedium).copyWith(color: secondary),
      bodySmall: apply(AppTypography.bodySmall).copyWith(color: tertiary),
      labelLarge: apply(AppTypography.labelLarge).copyWith(color: primary),
      labelMedium: apply(AppTypography.labelMedium).copyWith(color: secondary),
      labelSmall: apply(AppTypography.labelSmall).copyWith(color: tertiary),
    );
  }
}
