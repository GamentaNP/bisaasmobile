library;

import 'package:flutter/material.dart';

import 'app_colors.dart';
import 'app_radii.dart';
import 'app_typography.dart';

/// Duolongo theme — tactile, playful, LIGHT-first Material 3.
/// No glassmorphism, no soft drop shadows: depth comes from solid fills
/// with hard bottom-border extrusions (Chunky* widgets).
abstract final class AppTheme {
  static ThemeData get dark => _build(Brightness.dark);

  static ThemeData get light => _build(Brightness.light);

  static ThemeData _build(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final scheme = ColorScheme(
      brightness: brightness,
      primary: AppColors.brand,
      onPrimary: Colors.white,
      secondary: AppColors.brandAccent,
      onSecondary: Colors.white,
      tertiary: AppColors.violet,
      onTertiary: Colors.white,
      error: AppColors.wrongRed,
      onError: Colors.white,
      surface: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
      onSurface:
          isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
      surfaceContainerHighest:
          isDark ? AppColors.cardDark : AppColors.surfaceSecondary,
    );

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: scheme,
      scaffoldBackgroundColor:
          isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
      // ── AppBar: flat, 2px bottom rule like the sample header ───────────
      appBarTheme: AppBarTheme(
        backgroundColor:
            isDark ? AppColors.backgroundDark : AppColors.backgroundLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: true,
        shape: Border(
          bottom: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            width: 2,
          ),
        ),
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
        iconTheme: IconThemeData(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
      ),
      textTheme: _textTheme(brightness),
      // ── Cards: flat chunky with hard border ────────────────────────────
      cardTheme: CardThemeData(
        elevation: 0,
        color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.card,
          side: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            width: 2,
          ),
        ),
        margin: EdgeInsets.zero,
      ),
      // ── Filled buttons: solid green face (chunky extrusion via widget) ─
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: AppColors.brand,
          foregroundColor: Colors.white,
          disabledBackgroundColor:
              isDark ? AppColors.cardDark : AppColors.surfaceTertiary,
          disabledForegroundColor:
              isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.mdAll),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor:
              isDark ? AppColors.cardDark : AppColors.surfaceLight,
          foregroundColor:
              isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(
            borderRadius: AppRadii.mdAll,
            side: BorderSide(
              color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
              width: 2,
            ),
          ),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: AppColors.brand,
          side: const BorderSide(color: AppColors.brand, width: 2),
          minimumSize: const Size(64, 52),
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          shape: RoundedRectangleBorder(borderRadius: AppRadii.mdAll),
          textStyle: AppTypography.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: AppColors.brandAccent,
          textStyle: AppTypography.labelLarge.copyWith(fontSize: 14),
        ),
      ),
      // ── Inputs: white fill, 2px border, green focus ────────────────────
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: isDark ? AppColors.surfaceRaisedDark : AppColors.surfaceLight,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        hintStyle: AppTypography.bodyMedium.copyWith(
          color: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
        ),
        labelStyle: AppTypography.bodyMedium.copyWith(
          fontWeight: FontWeight.w700,
          color:
              isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
        prefixIconColor:
            isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        suffixIconColor: AppColors.brand,
        border: OutlineInputBorder(
          borderRadius: AppRadii.mdAll,
          borderSide: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            width: 2,
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: AppRadii.mdAll,
          borderSide: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            width: 2,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: AppRadii.mdAll,
          borderSide: const BorderSide(color: AppColors.brand, width: 2.4),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: AppRadii.mdAll,
          borderSide: const BorderSide(color: AppColors.wrongRed, width: 2),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: AppRadii.mdAll,
          borderSide: const BorderSide(color: AppColors.wrongRed, width: 2.4),
        ),
      ),
      // ── Chips: pill, hard border ───────────────────────────────────────
      chipTheme: ChipThemeData(
        backgroundColor:
            isDark ? AppColors.cardDark : AppColors.surfaceSecondary,
        side: BorderSide(
          color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          width: 2,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.pillAll),
        labelStyle: AppTypography.labelMedium.copyWith(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
        secondaryLabelStyle: AppTypography.labelMedium.copyWith(
          color: AppColors.brand,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      ),
      // ── Navigation bar: white slab, green active ───────────────────────
      navigationBarTheme: NavigationBarThemeData(
        height: 68,
        backgroundColor:
            isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        indicatorColor: Colors.transparent,
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
            fontSize: 11,
            fontWeight:
                states.contains(WidgetState.selected) ? FontWeight.w800 : FontWeight.w600,
          ),
        ),
      ),
      // ── Bottom sheets ──────────────────────────────────────────────────
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor:
            isDark ? AppColors.surfaceRaisedDark : AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        shape: const RoundedRectangleBorder(borderRadius: AppRadii.sheet),
        showDragHandle: true,
        dragHandleColor:
            isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor:
            isDark ? AppColors.surfaceRaisedDark : AppColors.surfaceLight,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.xlAll,
          side: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            width: 2,
          ),
        ),
        titleTextStyle: AppTypography.titleLarge.copyWith(
          color: isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        ),
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color:
              isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: isDark ? AppColors.surfaceRaisedDark : AppColors.textPrimaryLight,
        contentTextStyle: AppTypography.bodyMedium.copyWith(
          color: Colors.white,
          fontWeight: FontWeight.w700,
        ),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.mdAll),
        elevation: 0,
      ),
      progressIndicatorTheme: ProgressIndicatorThemeData(
        color: AppColors.brand,
        linearTrackColor: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        circularTrackColor: Colors.transparent,
      ),
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
                  ? AppColors.dividerDark
                  : AppColors.dividerLight,
        ),
        trackOutlineColor: WidgetStateProperty.resolveWith(
          (states) => states.contains(WidgetState.selected)
              ? AppColors.brandShadow
              : isDark
                  ? AppColors.dividerDark
                  : AppColors.glassBorderStrong,
        ),
      ),
      sliderTheme: SliderThemeData(
        activeTrackColor: AppColors.brand,
        inactiveTrackColor: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        thumbColor: AppColors.brand,
        overlayColor: AppColors.brand.withValues(alpha: 0.12),
        trackHeight: 6,
      ),
      dividerTheme: DividerThemeData(
        color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
        thickness: 2,
        space: 2,
      ),
      listTileTheme: ListTileThemeData(
        iconColor:
            isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        textColor:
            isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight,
        titleTextStyle: AppTypography.titleSmall,
        subtitleTextStyle: AppTypography.bodySmall.copyWith(
          color:
              isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight,
        ),
        shape: RoundedRectangleBorder(
          borderRadius: AppRadii.mdAll,
          side: BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
          ),
        ),
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: AppColors.brand,
        unselectedLabelColor:
            isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
        indicatorColor: AppColors.brand,
        dividerColor: isDark ? AppColors.dividerDark : AppColors.dividerLight,
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
      shadowColor: Colors.transparent,
      splashFactory: InkRipple.splashFactory,
    );
  }

  static TextTheme _textTheme(Brightness brightness) {
    final isDark = brightness == Brightness.dark;
    final primary = isDark ? AppColors.textPrimaryDark : AppColors.textPrimaryLight;
    final secondary =
        isDark ? AppColors.textSecondaryDark : AppColors.textSecondaryLight;
    final tertiary =
        isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;

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
