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

/// Bordered card with a chunky bottom extrusion — the signature Duolingo look.
///
/// [side] paints the extrusion, [face] the card body.
///
/// **Implementation note (fixed 2026-09-27):** the extrusion used to be a
/// `BoxDecoration` with `border: Border(bottom: wide, top/left/right: thin)`
/// plus a `borderRadius`. Flutter rejects that combination outright —
/// "A borderRadius can only be given on borders with uniform colors" — so the
/// decoration silently failed to paint and the Duolingo 3D effect was invisible
/// on every `ChunkyCard` in the app. The extrusion is now a real second layer
/// behind the card, which is what the design intends and what actually renders.
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
    final radius = borderRadius ?? BorderRadius.circular(16);
    final faceColor = face ?? (isDark ? AppColors.cardDark : AppColors.surfaceLight);
    final sideColor = side ?? (isDark ? AppColors.dividerDark : AppColors.dividerLight);

    // The extrusion: the same rounded shape, sitting `sideWidth` lower, painted
    // first so the card face covers everything but the bottom lip.
    return Container(
      decoration: BoxDecoration(
        color: sideColor,
        borderRadius: radius,
      ),
      padding: EdgeInsets.only(bottom: sideWidth),
      child: Material(
        color: faceColor,
        borderRadius: radius,
        child: InkWell(
          borderRadius: radius,
          onTap: onTap,
          child: Ink(
            decoration: BoxDecoration(
              borderRadius: radius,
              // Uniform outline only — a per-side width cannot coexist with a
              // borderRadius, and the lip is the layered box behind instead.
              border: Border.all(color: sideColor.withValues(alpha: 0.35), width: 1),
            ),
            child: Padding(padding: padding, child: child),
          ),
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
