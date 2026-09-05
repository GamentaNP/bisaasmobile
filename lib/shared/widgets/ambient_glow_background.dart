import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Flat surface background — the Duolongo replacement for the old ambient
/// glow canvas (sample: "no glassmorphism, no blur"). API preserved so the
/// quiz screen keeps compiling; it now paints a plain surface color with a
/// barely-there brand tint, which also respects reduce-motion by painting
/// nothing extra at all.
class AmbientGlowBackground extends StatelessWidget {
  const AmbientGlowBackground({
    required this.child,
    this.baseColor,
    this.showNoise = true,
    super.key,
  });

  final Widget child;
  final Color? baseColor;

  /// Kept for API compatibility; noise speckle is disabled in the flat style.
  // ignore: avoid_positional_boolean_parameters
  final bool showNoise;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return ColoredBox(
      color: baseColor ??
          (isDark ? AppColors.backgroundDark : AppColors.surfaceLight),
      child: child,
    );
  }
}
