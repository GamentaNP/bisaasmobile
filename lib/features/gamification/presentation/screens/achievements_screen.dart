import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/feature_bridges.dart';
import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/utils/achievement_rarity_color.dart';
import '../widgets/xp_progress_bar.dart';

// Keep the public names available at their old location for existing callers.
export '../../../../shared/utils/achievement_rarity_color.dart'
    show AchievementRarityColor;
export '../../data/providers/achievements_providers.dart'
    show achievementsDataProvider;
export '../../domain/entities/achievements.dart'
    show AchievementEntry, AchievementsData;

/// Achievements screen — server-authoritative.
///
/// Coins, XP, level, streak, badges are never computed locally.
/// Fetches: `GET /economy/achievements` (catalog + progress),
///          `GET /me/achievements/progress`, `GET /me/achievements/recent`.
/// Lottie assets `assets/animations/level_up.json` play on unlock.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final dash = ref.watch(homeControllerProvider);
    final user = ref.watch(authControllerProvider).value;
    final achievementsAsync = ref.watch(achievementsDataProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.profileAchievements)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          dash.when(
            data: (d) => XpProgressBar(level: d.level, currentXp: d.currentXp, nextLevelXp: d.nextLevelXp),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => XpProgressBar(
              level: user?.level ?? 1,
              currentXp: user?.xp ?? 0,
              // No invented threshold: the server did not publish one.
              nextLevelXp: null,
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(child: CoinChip(coins: dash.value?.coinsBalance ?? user?.coins ?? 0)),
              const SizedBox(width: 10),
              StreakFire(days: dash.value?.streakDays ?? 0),
            ],
          ),
          const SizedBox(height: 20),
          Text(l10n.achievementsBadges, style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          achievementsAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text(l10n.achievementsFailed(e),
                  style: const TextStyle(color: AppColors.wrongRed, fontSize: 12)),
            ),
            data: (data) {
              if (data.achievements.isEmpty) {
                return Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.emoji_events_outlined, size: 48, color: Theme.of(context).colorScheme.onSurfaceVariant),
                        SizedBox(height: 8),
                        Text(l10n.achievementsNone,
                            style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant, fontSize: 13)),
                      ],
                    ),
                  ),
                );
              }
              return GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 12,
                  mainAxisSpacing: 12,
                  childAspectRatio: 1,
                ),
                itemCount: data.achievements.length,
                itemBuilder: (context, i) => _AchievementCard(achievement: data.achievements[i]),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _AchievementCard extends StatelessWidget {
  const _AchievementCard({required this.achievement});
  final AchievementEntry achievement;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    final color = achievement.rarityColor;
    final unlocked = achievement.isCompleted;
    final progressFrac = achievement.progressTarget > 0
        ? (achievement.progressCurrent / achievement.progressTarget).clamp(0.0, 1.0)
        : 0.0;

    return Opacity(
      opacity: unlocked ? 1 : 0.55,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: (unlocked ? color : theme.colorScheme.outlineVariant).withValues(alpha: 0.35),
            width: unlocked ? 2 : 1,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(7),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    unlocked ? Icons.verified_rounded : Icons.lock_rounded,
                    color: color,
                    size: 18,
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    achievement.rarity,
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ],
            ),
            const Spacer(),
            Text(
              achievement.name,
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            if (unlocked)
              Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 12, color: AppColors.correctGreen),
                  SizedBox(width: 4),
                  Text(l10n.profileUnlocked, style: TextStyle(fontSize: 10, color: AppColors.correctGreen, fontWeight: FontWeight.w600)),
                ],
              )
            else if (achievement.progressTarget > 1) ...[
              ClipRRect(
                borderRadius: BorderRadius.circular(3),
                child: LinearProgressIndicator(
                  value: progressFrac,
                  minHeight: 4,
                  backgroundColor: color.withValues(alpha: 0.12),
                  color: color,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${achievement.progressCurrent}/${achievement.progressTarget}',
                style: TextStyle(fontSize: 9, color: theme.colorScheme.onSurface.withValues(alpha: 0.5)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
