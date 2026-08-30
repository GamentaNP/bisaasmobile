// ignore_for_file: cast_nullable_to_non_nullable

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../auth/presentation/controllers/auth_controller.dart';
import '../../../home/presentation/controllers/home_controller.dart';
import '../widgets/xp_progress_bar.dart';

/// Achievements & gamification — server-authoritative.
///
/// Coins, XP, level, streak, badges are never computed locally.
/// This screen visualizes `GET /quiz/streak`, `GET /me` (level/xp/coins),
/// and `GET /quiz/game/missions/dashboard` (missions). Lottie assets
/// `assets/animations/level_up.json` etc. play on unlock.
class AchievementsScreen extends ConsumerWidget {
  const AchievementsScreen({super.key});

  static const _mockBadges = [
    {'name': 'First Quiz', 'desc': 'Complete your first quiz', 'rarity': 'Common', 'color': Color(0xFF94A3B8), 'unlocked': true},
    {'name': 'Streak 7', 'desc': '7-day fire streak', 'rarity': 'Rare', 'color': Color(0xFF22D3EE), 'unlocked': true},
    {'name': 'Century', 'desc': '100 correct answers', 'rarity': 'Epic', 'color': Color(0xFFA855F7), 'unlocked': false},
    {'name': 'Master Builder', 'desc': '50 civil calculations', 'rarity': 'Legendary', 'color': Color(0xFFEAB308), 'unlocked': false},
    {'name': 'Loksewa Ready', 'desc': 'Mock exam 80%+', 'rarity': 'Epic', 'color': Color(0xFFEF4444), 'unlocked': false},
    {'name': 'Social Proof', 'desc': 'Refer 3 friends', 'rarity': 'Rare', 'color': Color(0xFF10B981), 'unlocked': true},
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final dash = ref.watch(homeControllerProvider);
    final user = ref.watch(authControllerProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Achievements')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          dash.when(
            data: (d) => XpProgressBar(level: d.level, currentXp: d.currentXp, nextLevelXp: d.nextLevelXp),
            loading: () => const LinearProgressIndicator(),
            error: (_, __) => XpProgressBar(level: user?.level ?? 1, currentXp: user?.xp ?? 0, nextLevelXp: 1000),
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
          const Text('Server unlocks achievements; client only displays. Lottie plays on new unlock.', style: TextStyle(fontSize: 12, color: Colors.grey)),
          const SizedBox(height: 12),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              childAspectRatio: 1.1,
            ),
            itemCount: _mockBadges.length,
            itemBuilder: (context, i) {
              final b = _mockBadges[i];
              final unlocked = b['unlocked'] as bool;
              final color = b['color'] as Color;
              return Opacity(
                opacity: unlocked ? 1 : 0.45,
                child: Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.surface,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: (unlocked ? color : theme.colorScheme.outlineVariant).withValues(alpha: 0.3), width: unlocked ? 2 : 1),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(10)),
                            child: Icon(unlocked ? Icons.verified_rounded : Icons.lock_rounded, color: color, size: 18),
                          ),
                          const Spacer(),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: color.withValues(alpha: 0.12), borderRadius: BorderRadius.circular(6)),
                            child: Text(b['rarity'] as String, style: TextStyle(fontSize: 9, fontWeight: FontWeight.bold, color: color)),
                          ),
                        ],
                      ),
                      const Spacer(),
                      Text(b['name'] as String, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                      const SizedBox(height: 2),
                      Text(b['desc'] as String, style: TextStyle(fontSize: 11, color: theme.colorScheme.onSurface.withValues(alpha: 0.6))),
                      if (unlocked)
                        const Padding(
                          padding: EdgeInsets.only(top: 6),
                          child: Row(children: [Icon(Icons.check_circle_rounded, size: 12, color: AppColors.correctGreen), SizedBox(width: 4), Text('Unlocked', style: TextStyle(fontSize: 11, color: AppColors.correctGreen, fontWeight: FontWeight.w600))]),
                        ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
