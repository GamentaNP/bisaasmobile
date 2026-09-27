// ignore_for_file: cast_nullable_to_non_nullable

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../widgets/xp_progress_bar.dart';

/// Fetches achievement catalog from `GET /api/v1/economy/achievements`.
/// Each item contains unlocked/in_progress/locked status from the server.
final achievementsDataProvider = FutureProvider<AchievementsData>((ref) async {
  final dio = DioClient.instance.dio;
  // Load catalog + per-user progress in parallel
  final results = await Future.wait([
    dio.get<Map<String, dynamic>>('/economy/achievements'),
    dio.get<Map<String, dynamic>>('/me/achievements/progress'),
    dio.get<Map<String, dynamic>>('/me/achievements/recent'),
  ]);

  final catalogBody = results[0].data?['data'];
  final progressBody = results[1].data?['data'];
  final recentBody = results[2].data?['data'];

  return AchievementsData.fromRaw(catalogBody, progressBody, recentBody);
});

class AchievementEntry {
  const AchievementEntry({
    required this.id,
    required this.key,
    required this.name,
    required this.rarity,
    required this.isCompleted,
    required this.progressCurrent,
    required this.progressTarget,
    this.completedAt,
  });

  final int id;
  final String key;
  final String name;
  final String rarity;
  final bool isCompleted;
  final int progressCurrent;
  final int progressTarget;
  final String? completedAt;

  Color get rarityColor {
    switch (rarity) {
      case 'legendary':
        return const Color(0xFFEAB308);
      case 'epic':
        return const Color(0xFFA855F7);
      case 'rare':
        return const Color(0xFF22D3EE);
      case 'uncommon':
        return const Color(0xFF10B981);
      default:
        return const Color(0xFF94A3B8);
    }
  }
}

class AchievementsData {
  const AchievementsData({required this.achievements, required this.recentCount});
  final List<AchievementEntry> achievements;
  final int recentCount;

  factory AchievementsData.fromRaw(
    dynamic catalogBody,
    dynamic progressBody,
    dynamic recentBody,
  ) {
    // Build a map of progress by achievement_id
    final progressMap = <int, Map<String, dynamic>>{};
    if (progressBody is List) {
      for (final p in progressBody.cast<Map<String, dynamic>>()) {
        final id = p['achievement_id'] as int?;
        if (id != null) progressMap[id] = p;
      }
    }

    // Merge catalog with user progress
    final achievements = <AchievementEntry>[];

    // catalog shape: {unlocked: [], in_progress: [], locked: []}
    if (catalogBody is Map<String, dynamic>) {
      for (final bucket in ['unlocked', 'in_progress', 'locked']) {
        final list = catalogBody[bucket];
        if (list is List) {
          for (final item in list.cast<Map<String, dynamic>>()) {
            final id = (item['id'] ?? item['achievement_id'] ?? 0) as int;
            final progress = progressMap[id];
            achievements.add(AchievementEntry(
              id: id,
              key: (item['key'] ?? '').toString(),
              name: (item['name'] ?? 'Achievement').toString(),
              rarity: (item['rarity'] ?? 'common').toString(),
              isCompleted: bucket == 'unlocked' || (progress?['is_completed'] as bool? ?? false),
              progressCurrent: (progress?['progress_current'] as int?) ?? 0,
              progressTarget: (progress?['progress_target'] as int?) ?? 1,
              completedAt: (item['completed_at'] ?? progress?['completed_at']) as String?,
            ));
          }
        }
      }
    } else if (progressBody is List) {
      // Fallback: just show progress list
      for (final p in progressBody.cast<Map<String, dynamic>>()) {
        final id = (p['achievement_id'] ?? 0) as int;
        achievements.add(AchievementEntry(
          id: id,
          key: (p['key'] ?? '').toString(),
          name: (p['name'] ?? 'Achievement').toString(),
          rarity: 'common',
          isCompleted: p['is_completed'] as bool? ?? false,
          progressCurrent: (p['progress_current'] as int?) ?? 0,
          progressTarget: (p['progress_target'] as int?) ?? 1,
          completedAt: p['completed_at'] as String?,
        ));
      }
    }

    final recentCount = (recentBody is List) ? recentBody.length : 0;
    return AchievementsData(achievements: achievements, recentCount: recentCount);
  }
}

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
    final theme = Theme.of(context);
    final dash = ref.watch(homeControllerProvider);
    final user = ref.watch(authControllerProvider).value;
    final achievementsAsync = ref.watch(achievementsDataProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
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
          Text('Badges', style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          achievementsAsync.when(
            loading: () => const Center(child: Padding(padding: EdgeInsets.all(32), child: CircularProgressIndicator())),
            error: (e, _) => Padding(
              padding: const EdgeInsets.all(16),
              child: Text('Could not load achievements: $e',
                  style: const TextStyle(color: AppColors.wrongRed, fontSize: 12)),
            ),
            data: (data) {
              if (data.achievements.isEmpty) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 32),
                  child: Center(
                    child: Column(
                      children: [
                        Icon(Icons.emoji_events_outlined, size: 48, color: Colors.grey),
                        SizedBox(height: 8),
                        Text('No achievements yet — start quizzing!',
                            style: TextStyle(color: Colors.grey, fontSize: 13)),
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
              const Row(
                children: [
                  Icon(Icons.check_circle_rounded, size: 12, color: AppColors.correctGreen),
                  SizedBox(width: 4),
                  Text('Unlocked', style: TextStyle(fontSize: 10, color: AppColors.correctGreen, fontWeight: FontWeight.w600)),
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
