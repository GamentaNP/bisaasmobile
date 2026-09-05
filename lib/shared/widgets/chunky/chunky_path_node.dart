import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

/// Zig-zag learning-path node — chunky 3D circle (borderBottom extrusion),
/// alternating lateral offsets to form the winding trail from the sample.
enum PathNodeStatus { completed, current, locked }

class ChunkyPathNode extends StatelessWidget {
  const ChunkyPathNode({
    super.key,
    required this.status,
    this.index,
    this.color,
    this.shadowColor,
    this.onTap,
  });

  final PathNodeStatus status;
  final int? index;
  final Color? color;
  final Color? shadowColor;
  final VoidCallback? onTap;

  /// Lateral offset in px for node [i] — same winding math as the sample:
  /// ((i % 4) - 1.5) * 40.
  static double zigZagOffset(int i) => ((i % 4) - 1.5) * 40;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = status == PathNodeStatus.current ? 92.0 : 80.0;
    final Color face;
    final Color side;
    final IconData iconData;
    final Color iconColor;

    switch (status) {
      case PathNodeStatus.completed:
        face = color ?? AppColors.brand;
        side = shadowColor ?? AppColors.brandShadow;
        iconData = Icons.check;
        iconColor = Colors.white;
      case PathNodeStatus.current:
        face = color ?? AppColors.brand;
        side = shadowColor ?? AppColors.brandShadow;
        iconData = Icons.play_arrow;
        iconColor = Colors.white;
      case PathNodeStatus.locked:
        face = isDark ? AppColors.cardDark : AppColors.surfaceTertiary;
        side = isDark ? AppColors.dividerDark : AppColors.glassBorderStrong;
        iconData = Icons.lock;
        iconColor = isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;
    }

    final node = Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: face,
        shape: BoxShape.circle,
        border: Border(
          bottom: BorderSide(
            color: side,
            width: status == PathNodeStatus.locked ? 4 : 6,
          ),
        ),
      ),
      child: Icon(iconData, size: size * 0.42, color: iconColor),
    );

    return Semantics(
      button: status != PathNodeStatus.locked,
      label: status == PathNodeStatus.locked
          ? 'Locked level'
          : 'Level ${index ?? ''}',
      child: GestureDetector(
        onTap: status == PathNodeStatus.locked
            ? null
            : () {
                HapticFeedback.mediumImpact();
                onTap?.call();
              },
        child: Transform.translate(
          offset: Offset(zigZagOffset(index ?? 0), 0),
          child: Opacity(
            opacity: status == PathNodeStatus.locked ? 0.8 : 1,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (status == PathNodeStatus.current) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
                      borderRadius: BorderRadius.circular(999),
                      border: Border(
                        bottom: BorderSide(color: side, width: 3),
                        top: BorderSide(color: AppColors.brand, width: 2),
                        left: BorderSide(color: AppColors.brand, width: 2),
                        right: BorderSide(color: AppColors.brand, width: 2),
                      ),
                    ),
                    child: Text(
                      'START',
                      style: AppTypography.labelSmall.copyWith(
                        color: AppColors.brand,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                ],
                node,
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The trophy marker at the end of the path.
class PathTrophyEnd extends StatelessWidget {
  const PathTrophyEnd({super.key, this.label = 'Master League'});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Transform.rotate(
          angle: math.pi / 12,
          child: const Icon(Icons.emoji_events,
              size: 44, color: AppColors.xpGold),
        ),
        const SizedBox(height: 6),
        Text(
          label,
          style: AppTypography.titleMedium.copyWith(
            color: Theme.of(context).brightness == Brightness.dark
                ? AppColors.textPrimaryDark
                : AppColors.textPrimaryLight,
          ),
        ),
      ],
    );
  }
}
