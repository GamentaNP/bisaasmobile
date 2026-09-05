import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';

/// Chunky solid card — the Duolongo replacement for the old glass card.
/// API preserved (padding/onTap/glow/color) so every call site converts
/// without edits; `glow` is now a no-op kept for compatibility.
class GlassmorphicCard extends StatelessWidget {
  const GlassmorphicCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.glow = false,
    this.color,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final bool glow;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final border =
        isDark ? AppColors.dividerDark : AppColors.dividerLight;

    return Material(
      color: color ?? (isDark ? AppColors.cardDark : AppColors.surfaceLight),
      borderRadius: AppRadii.card,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadii.card,
          border: Border.all(color: border, width: 2),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: AppRadii.card,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}
