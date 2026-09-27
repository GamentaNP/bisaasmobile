import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/chunky/chunky_kit.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../data/models/game_models.dart';
import '../../game_providers.dart';

/// World picker â€” `GET /api/v1/quiz/game/worlds`.
///
/// The entry point into the Duolingo spine: each world opens its chapter/level
/// path in `GameWorldMapScreen`. Progress numbers come from the same payload â€”
/// nothing here is derived client-side.
class GameWorldsScreen extends ConsumerWidget {
  const GameWorldsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final worldsAsync = ref.watch(gameWorldsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Worlds')),
      body: worldsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          title: 'Could not load worlds',
          message: '$e',
          onRetry: () => ref.invalidate(gameWorldsProvider),
        ),
        data: (worlds) {
          if (worlds.isEmpty) {
            return const Center(
              child: EmptyState(
                title: 'No worlds yet',
                subtitle: 'The server has not published any game worlds.',
                icon: Icons.public_rounded,
              ),
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.refresh(gameWorldsProvider.future),
            child: ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: worlds.length,
              separatorBuilder: (_, __) => const SizedBox(height: 12),
              itemBuilder: (context, i) => _WorldCard(world: worlds[i]),
            ),
          );
        },
      ),
    );
  }
}

class _WorldCard extends StatelessWidget {
  const _WorldCard({required this.world});

  final GameWorldSummaryDto world;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final locked = !world.isUnlocked;
    final muted = isDark ? AppColors.textTertiaryDark : AppColors.textSecondaryLight;

    return ChunkyCard(
      padding: EdgeInsets.zero,
      onTap: locked ? null : () => context.go('/game/world/${world.slug}'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Banner â€” server image when present, brand gradient otherwise.
          SizedBox(
            height: 108,
            child: Stack(
              fit: StackFit.expand,
              children: [
                if (world.bannerImage != null && world.bannerImage!.isNotEmpty)
                  Image.network(
                    world.bannerImage!,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const _BrandFill(),
                  )
                else
                  const _BrandFill(),
                const DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [Colors.transparent, Color(0x8A000000)],
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                    ),
                  ),
                ),
                Positioned(
                  left: 14,
                  right: 14,
                  bottom: 10,
                  child: Row(
                    children: [
                      if (locked) ...[
                        const Icon(Icons.lock_rounded, size: 16, color: Colors.white70),
                        const SizedBox(width: 6),
                      ],
                      Expanded(
                        child: Text(
                          world.name,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                      ),
                      Text(
                        '${world.completionPercent}%',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 15,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 12, 14, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    const Icon(Icons.star_rounded, size: 16, color: AppColors.xpGold),
                    const SizedBox(width: 4),
                    Text(
                      '${world.totalStarsEarned} / ${world.totalMaxStars}',
                      style: AppTypography.titleSmall.copyWith(color: AppColors.xpGold),
                    ),
                    const Spacer(),
                    if (locked) _GateChip(world: world, muted: muted),
                  ],
                ),
                if (world.totalMaxStars > 0) ...[
                  const SizedBox(height: 8),
                  ChunkyProgressBar(
                    value: world.totalStarsEarned / world.totalMaxStars,
                    color: AppColors.xpGold,
                    height: 10,
                  ),
                ],
                if (locked && world.accessMode == 'plan_required') ...[
                  const SizedBox(height: 8),
                  Text('Requires a subscription plan.', style: AppTypography.bodySmall.copyWith(color: muted)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// Why a world is locked â€” always sourced from the server's access mode.
class _GateChip extends StatelessWidget {
  const _GateChip({required this.world, required this.muted});

  final GameWorldSummaryDto world;
  final Color muted;

  @override
  Widget build(BuildContext context) {
    final (label, color) = switch (world.accessMode) {
      'stars_required' => ('${world.requiredStars} stars', AppColors.xpGold),
      'plan_required' => ('Premium', AppColors.violet),
      'coin_unlock' => ('Locked', AppColors.coinYellow),
      _ => ('Locked', AppColors.textTertiaryDark),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Text(
        label,
        style: AppTypography.labelSmall.copyWith(color: color, fontWeight: FontWeight.w700),
      ),
    );
  }
}

class _BrandFill extends StatelessWidget {
  const _BrandFill();

  @override
  Widget build(BuildContext context) {
    return const DecoratedBox(
      decoration: BoxDecoration(gradient: AppColors.brandGradient),
      child: Center(
        child: Icon(Icons.public_rounded, color: Colors.white24, size: 40),
      ),
    );
  }
}
