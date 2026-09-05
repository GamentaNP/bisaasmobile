import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_motion.dart';
import '../../app/theme/app_radii.dart';
import '../../app/theme/app_typography.dart';

/// Primary CTA — solid Duolongo green face with hard bottom extrusion,
/// pressed-sink feedback, loading state and optional leading icon.
/// API-compatible with the old gradient version (same call sites).
class GradientButton extends StatefulWidget {
  const GradientButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.loading = false,
    this.icon,
    this.expand = true,
    this.gradient,
    this.textStyle,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool loading;
  final IconData? icon;
  final bool expand;
  final Gradient? gradient;
  final TextStyle? textStyle;

  @override
  State<GradientButton> createState() => _GradientButtonState();
}

class _GradientButtonState extends State<GradientButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.onPressed != null && !widget.loading;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // A custom gradient (if supplied) still gets painted on the face; the
    // extrusion side uses the dark brand shadow for depth.
    final useGradient = enabled && widget.gradient != null;
    final faceColor = enabled
        ? (useGradient ? null : AppColors.brand)
        : (isDark ? AppColors.cardDark : AppColors.surfaceTertiary);
    final sideColor = enabled
        ? AppColors.brandShadow
        : (isDark ? AppColors.dividerDark : AppColors.glassBorderStrong);
    final textColor = enabled
        ? Colors.white
        : (isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight);

    final sideWidth = _pressed ? 0.0 : 4.0;

    final button = SizedBox(
      height: 56,
      child: Center(
        widthFactor: widget.expand ? double.infinity : 0,
        child: Row(
          mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (widget.loading)
              SizedBox(
                height: 22,
                width: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.4,
                  color: textColor,
                ),
              )
            else ...[
              if (widget.icon != null) ...[
                Icon(widget.icon, size: 19, color: textColor),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  widget.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: (widget.textStyle ?? AppTypography.labelLarge)
                      .copyWith(color: textColor),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _pressed = true) : null,
      onTapCancel: enabled
          ? () {
              HapticFeedback.lightImpact();
              setState(() => _pressed = false);
            }
          : null,
      onTap: enabled
          ? () {
              HapticFeedback.lightImpact();
              setState(() => _pressed = false);
              widget.onPressed!();
            }
          : null,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: useGradient ? widget.gradient : null,
          color: faceColor,
          borderRadius: AppRadii.mdAll,
          border: Border(
            bottom: BorderSide(color: sideColor, width: sideWidth),
          ),
        ),
        child: AnimatedScale(
          scale: _pressed ? 0.99 : 1.0,
          duration: AppMotion.fast,
          curve: Curves.easeOut,
          child: Padding(
            padding: EdgeInsets.only(bottom: sideWidth),
            child: button,
          ),
        ),
      ),
    );
  }
}
