import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_radii.dart';
import '../../app/theme/app_shadows.dart';

/// Glassmorphic card with adaptive tint, hairline border and optional tap
/// feedback. `glow` adds the signature brand halo for featured content.
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
    final base = color ??
        (isDark ? AppColors.glassSurface : Colors.white.withValues(alpha: 0.92));

    return Material(
      color: base,
      borderRadius: AppRadii.card,
      elevation: 0,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: AppRadii.card,
          border: Border.all(
            color: isDark ? AppColors.glassBorder : AppColors.dividerLight,
          ),
          boxShadow: glow
              ? AppShadows.glowBrand
              : isDark
                  ? AppShadows.shadowSm
                  : AppShadows.cardLight,
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
