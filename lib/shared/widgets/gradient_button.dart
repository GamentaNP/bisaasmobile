import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_motion.dart';
import '../../app/theme/app_radii.dart';
import '../../app/theme/app_shadows.dart';
import '../../app/theme/app_typography.dart';

/// Primary CTA — brand gradient with a soft glow, pressed-scale feedback,
/// loading state and optional leading icon. The app's signature button.
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
    final gradient = widget.gradient ?? AppColors.brandGradient;

    final button = FilledButton(
      onPressed: enabled
          ? () {
              setState(() => _pressed = true);
              widget.onPressed!();
              Future<void>.delayed(AppMotion.base, () {
                if (mounted) setState(() => _pressed = false);
              });
            }
          : null,
      style: FilledButton.styleFrom(
        backgroundColor: Colors.transparent,
        shadowColor: Colors.transparent,
        minimumSize: Size(widget.expand ? double.infinity : 0, 52),
        shape: RoundedRectangleBorder(borderRadius: AppRadii.mdAll),
      ),
      child: widget.loading
          ? const SizedBox(
              height: 22,
              width: 22,
              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
            )
          : Row(
              mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (widget.icon != null) ...[
                  Icon(widget.icon, size: 19, color: Colors.white),
                  const SizedBox(width: 8),
                ],
                Text(
                  widget.label,
                  style: (widget.textStyle ?? AppTypography.labelLarge)
                      .copyWith(color: Colors.white),
                ),
              ],
            ),
    );

    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: enabled ? gradient : null,
        color: enabled ? null : AppColors.surfaceRaisedDark.withValues(alpha: 0.4),
        borderRadius: AppRadii.mdAll,
        boxShadow: enabled && !widget.loading ? AppShadows.glowBrand : const [],
      ),
      child: AnimatedScale(
        scale: _pressed ? 0.97 : 1.0,
        duration: AppMotion.fast,
        curve: Curves.easeOut,
        child: button,
      ),
    );
  }
}
