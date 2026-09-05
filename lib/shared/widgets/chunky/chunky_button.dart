import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_radii.dart';
import '../../../app/theme/app_typography.dart';

/// Chunky variant of a button — the signature Duolongo 3D press.
///
/// Depth is a hard bottom-border extrusion (never a soft shadow): the fill
/// color carries the face, [AppColors] *Shadow tokens carry the side.
/// Pressing collapses the extrusion and sinks the label, spring-back on release.
enum ChunkyVariant { primary, secondary, warning, error, tertiary, muted }

enum ChunkySize { sm, md, lg }

class ChunkyButton extends StatefulWidget {
  const ChunkyButton({
    super.key,
    required this.label,
    this.onPressed,
    this.variant = ChunkyVariant.primary,
    this.size = ChunkySize.lg,
    this.expand = true,
    this.icon,
    this.loading = false,
  });

  final String label;
  final VoidCallback? onPressed;
  final ChunkyVariant variant;
  final ChunkySize size;
  final bool expand;
  final IconData? icon;
  final bool loading;

  @override
  State<ChunkyButton> createState() => _ChunkyButtonState();
}

class _ChunkyButtonState extends State<ChunkyButton> {
  bool _pressed = false;

  ({Color face, Color side, Color text}) _palette(ChunkyVariant v) => switch (v) {
        ChunkyVariant.primary => (
            face: AppColors.brand,
            side: AppColors.brandShadow,
            text: Colors.white,
          ),
        ChunkyVariant.secondary => (
            face: AppColors.brandAccent,
            side: AppColors.blueShadow,
            text: Colors.white,
          ),
        ChunkyVariant.warning => (
            face: AppColors.warnAmber,
            side: AppColors.warningShadow,
            text: Colors.white,
          ),
        ChunkyVariant.error => (
            face: AppColors.wrongRed,
            side: AppColors.errorShadow,
            text: Colors.white,
          ),
        ChunkyVariant.tertiary => (
            face: AppColors.violet,
            side: AppColors.purpleShadow,
            text: Colors.white,
          ),
        ChunkyVariant.muted => (
            face: AppColors.surfaceTertiary,
            side: AppColors.glassBorderStrong,
            text: AppColors.textPrimaryLight,
          ),
      };

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final enabled = widget.onPressed != null && !widget.loading;
    var p = _palette(widget.variant);
    if (isDark) {
      // Night mode: same hues, surfaces lifted from the dark deck.
      p = switch (widget.variant) {
        ChunkyVariant.muted => (
            face: AppColors.cardDark,
            side: AppColors.dividerDark,
            text: AppColors.textPrimaryDark,
          ),
        _ => p,
      };
    }
    if (!enabled) {
      p = (
        face: isDark ? AppColors.cardDark : AppColors.surfaceTertiary,
        side: isDark ? AppColors.dividerDark : AppColors.glassBorderStrong,
        text: isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight,
      );
    }

    final sideWidth = _pressed ? 0.0 : (widget.size == ChunkySize.sm ? 3.0 : 4.0);
    final sink = sideWidth;

    final faceColor = p.face;
    final sideColor = p.side;
    final textColor = p.text;

    final minHeight = switch (widget.size) {
      ChunkySize.sm => 38.0,
      ChunkySize.md => 48.0,
      ChunkySize.lg => 56.0,
    };
    final fontSize = switch (widget.size) {
      ChunkySize.sm => 13.0,
      ChunkySize.md => 15.0,
      ChunkySize.lg => 17.0,
    };
    final padding = switch (widget.size) {
      ChunkySize.sm => const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ChunkySize.md => const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ChunkySize.lg => const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
    };

    final button = AnimatedContainer(
      duration: const Duration(milliseconds: 90),
      curve: Curves.easeOut,
      height: minHeight,
      padding: padding,
      decoration: BoxDecoration(
        color: faceColor,
        borderRadius: AppRadii.mdAll,
        border: Border(bottom: BorderSide(color: sideColor, width: sideWidth)),
      ),
      child: Transform.translate(
        offset: Offset(0, sink),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: widget.expand ? MainAxisSize.max : MainAxisSize.min,
          children: [
            if (widget.loading)
              SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2.6,
                  color: textColor,
                ),
              )
            else ...[
              if (widget.icon != null) ...[
                Icon(widget.icon, size: fontSize + 5, color: textColor),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  widget.label.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.center,
                  style: AppTypography.labelLarge.copyWith(
                    color: textColor,
                    fontSize: fontSize,
                    letterSpacing: 0.5,
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );

    return Semantics(
      button: true,
      enabled: enabled,
      child: GestureDetector(
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
        child: Opacity(opacity: enabled ? 1 : 1, child: button),
      ),
    );
  }
}
