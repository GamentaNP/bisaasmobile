import 'package:flutter/material.dart';

import '../../../app/theme/app_colors.dart';
import '../../../app/theme/app_typography.dart';

/// Top-bar stat pill — Hearts / Streak / XP, exactly like the sample's
/// StatsBar: icon + bold value inside a bordered pill with a chunky bottom.
class ChunkyStatPill extends StatelessWidget {
  const ChunkyStatPill({
    super.key,
    required this.icon,
    required this.value,
    required this.color,
    required this.shadow,
  });

  final IconData icon;
  final String value;
  final Color color;
  final Color shadow;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: isDark ? AppColors.cardDark : AppColors.surfaceLight,
        borderRadius: BorderRadius.circular(999),
        border: Border.fromBorderSide(
          BorderSide(
            color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
            width: 2,
          ),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 20, color: color),
          const SizedBox(width: 6),
          Text(
            value,
            style: AppTypography.labelLarge.copyWith(color: color, fontSize: 15),
          ),
        ],
      ),
    );
  }
}

/// Horizontal row of the three signature gamification stats.
class ChunkyStatsBar extends StatelessWidget {
  const ChunkyStatsBar({
    super.key,
    this.hearts,
    this.streak,
    this.xp,
    this.coins,
  });

  final int? hearts;
  final int? streak;
  final int? xp;
  final int? coins;

  @override
  Widget build(BuildContext context) {
    final pills = <Widget>[
      if (hearts != null)
        ChunkyStatPill(
          icon: Icons.favorite,
          value: '${hearts!}',
          color: AppColors.heartRed,
          shadow: AppColors.errorShadow,
        ),
      if (streak != null)
        ChunkyStatPill(
          icon: Icons.local_fire_department,
          value: '${streak!}',
          color: AppColors.streakOrange,
          shadow: AppColors.warningShadow,
        ),
      if (coins != null)
        ChunkyStatPill(
          icon: Icons.monetization_on,
          value: '${coins!}',
          color: AppColors.coinYellow,
          shadow: AppColors.goldShadow,
        ),
      if (xp != null)
        ChunkyStatPill(
          icon: Icons.bolt,
          value: '${xp!}',
          color: AppColors.xpGold,
          shadow: AppColors.goldShadow,
        ),
    ];
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: pills,
    );
  }
}

/// Bordered card with chunky bottom extrusion — replaces glass cards on
/// light surfaces. [face] paints the body; [side] paints the extrusion.
class ChunkyCard extends StatelessWidget {
  const ChunkyCard({
    super.key,
    required this.child,
    this.face,
    this.side,
    this.sideWidth = 3,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.borderRadius,
  });

  final Widget child;
  final Color? face;
  final Color? side;
  final double sideWidth;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final BorderRadius? borderRadius;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Material(
      color: face ??
          (isDark ? AppColors.cardDark : AppColors.surfaceLight),
      borderRadius: borderRadius ?? BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: borderRadius ?? BorderRadius.circular(16),
        child: Ink(
          decoration: BoxDecoration(
            borderRadius: borderRadius ?? BorderRadius.circular(16),
            border: Border(
              bottom: BorderSide(
                color: side ??
                    (isDark ? AppColors.dividerDark : AppColors.dividerLight),
                width: sideWidth,
              ),
              top: BorderSide(
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                width: 1,
              ),
              left: BorderSide(
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                width: 1,
              ),
              right: BorderSide(
                color: isDark ? AppColors.dividerDark : AppColors.dividerLight,
                width: 1,
              ),
            ),
          ),
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Thick rounded progress bar (quiz header / level progress).
class ChunkyProgressBar extends StatelessWidget {
  const ChunkyProgressBar({
    super.key,
    required this.value,
    this.color,
    this.height = 14,
  });

  final double value; // 0..1
  final Color? color;
  final double height;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final track =
        isDark ? AppColors.dividerDark : AppColors.dividerLight;
    return ClipRRect(
      borderRadius: BorderRadius.circular(999),
      child: SizedBox(
        height: height,
        child: Stack(
          children: [
            Container(color: track),
            FractionallySizedBox(
              widthFactor: value.clamp(0.0, 1.0),
              child: Container(color: color ?? AppColors.brand),
            ),
          ],
        ),
      ),
    );
  }
}
