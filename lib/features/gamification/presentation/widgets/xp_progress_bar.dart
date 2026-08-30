import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// XP progress bar — server-authoritative, never computes level locally.
///
/// Level/XP comes from `GET /me` or `DashboardDto`; this widget only visualizes.
class XpProgressBar extends StatelessWidget {
  const XpProgressBar({
    required this.level,
    required this.currentXp,
    required this.nextLevelXp,
    super.key,
  });

  final int level;
  final int currentXp;
  final int nextLevelXp;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final total = nextLevelXp > 0 ? nextLevelXp : 1;
    final progress = (currentXp / total).clamp(0.0, 1.0);
    final remaining = (nextLevelXp - currentXp).clamp(0, nextLevelXp);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.outlineVariant.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: AppColors.xpGold.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('LVL $level', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: AppColors.xpGold)),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  '$currentXp / $nextLevelXp XP',
                  style: theme.textTheme.labelSmall?.copyWith(color: theme.colorScheme.onSurface.withValues(alpha: 0.6)),
                ),
              ),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.bolt_rounded, size: 14, color: AppColors.xpGold),
                  const SizedBox(width: 4),
                  Text('$remaining to next', style: const TextStyle(fontSize: 11, color: AppColors.xpGold, fontWeight: FontWeight.w600)),
                ],
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              color: AppColors.xpGold,
              minHeight: 8,
            ),
          ),
        ],
      ),
    );
  }
}

/// Minimal coin chip — server wallet only.
class CoinChip extends StatelessWidget {
  const CoinChip({required this.coins, super.key});
  final int coins;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: AppColors.coinYellow.withValues(alpha: 0.15),
        border: Border.all(color: AppColors.coinYellow.withValues(alpha: 0.4)),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.monetization_on_rounded, size: 18, color: AppColors.coinYellow),
        const SizedBox(width: 6),
        Text('$coins', style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.coinYellow, fontSize: 13)),
      ]),
    );
  }
}

/// Streak fire indicator — from `GET /quiz/streak`.
class StreakFire extends StatelessWidget {
  const StreakFire({required this.days, this.compact = false, super.key});
  final int days;
  final bool compact;

  @override
  Widget build(BuildContext context) {
    if (days <= 0) return const SizedBox.shrink();
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 12, vertical: compact ? 4 : 6),
      decoration: BoxDecoration(
        color: AppColors.streakOrange.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.streakOrange.withValues(alpha: 0.3)),
      ),
      child: Row(mainAxisSize: MainAxisSize.min, children: [
        const Icon(Icons.local_fire_department_rounded, size: 16, color: AppColors.streakOrange),
        const SizedBox(width: 4),
        Text('$days day streak', style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.streakOrange, fontSize: compact ? 11 : 13)),
      ]),
    );
  }
}
