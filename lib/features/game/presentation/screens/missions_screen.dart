import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_typography.dart';
import '../../../../shared/widgets/chunky/chunky_button.dart';
import '../../../../shared/widgets/chunky/chunky_kit.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../data/models/mission_dto.dart';
import '../../game_providers.dart';

/// Missions — `GET /api/v1/quiz/game/missions/dashboard`.
///
/// 49 missions are live on the server (21 daily, 21 weekly, 7 campaign for the
/// QA account). Nothing here is computed locally: progress, completion and
/// claimability all come from the payload, and a reward is only ever shown once
/// the server has confirmed the claim.
class MissionsScreen extends ConsumerStatefulWidget {
  const MissionsScreen({super.key});

  @override
  ConsumerState<MissionsScreen> createState() => _MissionsScreenState();
}

class _MissionsScreenState extends ConsumerState<MissionsScreen> {
  /// Mission ids with a claim in flight.
  final Set<int> _claiming = {};
  bool _bulkClaiming = false;

  Future<void> _claim(MissionDto mission) async {
    setState(() => _claiming.add(mission.id));
    try {
      final result = await ref.read(gameRemoteDataSourceProvider).claimMission(mission.id);
      // Re-read rather than patching local state — the server owns progress.
      ref.invalidate(gameMissionsProvider);
      if (!mounted) return;
      final message = result.claimed
          ? 'Claimed ${result.coins} coins'
          : (result.reason ?? 'Could not claim this mission');
      _toast(context, message, ok: result.claimed);
    } catch (e) {
      if (!mounted) return;
      _toast(context, 'Claim failed: $e', ok: false);
    } finally {
      if (mounted) setState(() => _claiming.remove(mission.id));
    }
  }

  Future<void> _claimAll() async {
    setState(() => _bulkClaiming = true);
    try {
      final result = await ref.read(gameRemoteDataSourceProvider).claimAllMissions();
      ref.invalidate(gameMissionsProvider);
      if (!mounted) return;
      final message = result.claimedCount == 0
          ? 'Nothing was claimable'
          : 'Claimed ${result.claimedCount} mission${result.claimedCount == 1 ? '' : 's'} for ${result.coins} coins';
      _toast(context, message, ok: result.claimedCount > 0);
    } catch (e) {
      if (!mounted) return;
      _toast(context, 'Claim failed: $e', ok: false);
    } finally {
      if (mounted) setState(() => _bulkClaiming = false);
    }
  }

  void _toast(BuildContext context, String message, {required bool ok}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: ok ? AppColors.correctGreen : AppColors.wrongRed,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final missionsAsync = ref.watch(gameMissionsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Missions'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Refresh',
            onPressed: () => ref.invalidate(gameMissionsProvider),
          ),
        ],
      ),
      body: missionsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          title: 'Could not load missions',
          message: '$e',
          onRetry: () => ref.invalidate(gameMissionsProvider),
        ),
        data: (missions) {
          if (missions.isEmpty) {
            return const Center(
              child: EmptyState(
                title: 'No missions yet',
                subtitle: 'The server has not published any missions for you.',
                icon: Icons.flag_outlined,
              ),
            );
          }

          final claimable = missions.where((m) => m.isClaimable).toList();
          final groups = <String, List<MissionDto>>{};
          for (final m in missions) {
            groups.putIfAbsent(m.cadence, () => []).add(m);
          }
          // Claimable first, then by cadence.
          groups['Ready to claim'] = claimable;

          return RefreshIndicator(
            onRefresh: () async => ref.refresh(gameMissionsProvider.future),
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (claimable.isNotEmpty) ...[
                  ChunkyCard(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          '${claimable.length} mission${claimable.length == 1 ? '' : 's'} ready to claim',
                          style: AppTypography.titleMedium.copyWith(fontWeight: FontWeight.w800),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${claimable.length} reward${claimable.length == 1 ? '' : 's'} waiting',
                          style: AppTypography.bodySmall.copyWith(
                            color: AppColors.textSecondaryLight,
                          ),
                        ),
                        const SizedBox(height: 10),
                        ChunkyButton(
                          label: 'Claim all',
                          icon: Icons.redeem_rounded,
                          loading: _bulkClaiming,
                          onPressed: _bulkClaiming ? null : _claimAll,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                ],
                for (final entry in groups.entries.where((e) => e.value.isNotEmpty)) ...[
                  Padding(
                    padding: const EdgeInsets.only(top: 8, bottom: 8),
                    child: Text(
                      entry.key,
                      style: AppTypography.titleSmall.copyWith(fontWeight: FontWeight.w800),
                    ),
                  ),
                  ...entry.value.map(
                    (m) => Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: _MissionCard(
                        mission: m,
                        busy: _claiming.contains(m.id),
                        onClaim: () => _claim(m),
                      ),
                    ),
                  ),
                ],
              ],
            ),
          );
        },
      ),
    );
  }
}

class _MissionCard extends StatelessWidget {
  const _MissionCard({required this.mission, required this.busy, required this.onClaim});

  final MissionDto mission;
  final bool busy;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final claimed = mission.claimed;
    final claimable = mission.isClaimable;
    final accent = claimed
        ? AppColors.textTertiaryLight
        : claimable
            ? AppColors.correctGreen
            : AppColors.brand;

    return ChunkyCard(
      padding: const EdgeInsets.all(14),
      side: accent,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                claimed
                    ? Icons.check_circle_rounded
                    : claimable
                        ? Icons.card_giftcard_rounded
                        : Icons.flag_outlined,
                size: 18,
                color: accent,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  mission.title,
                  style: AppTypography.titleSmall.copyWith(
                    fontWeight: FontWeight.w700,
                    color: claimed ? AppColors.textTertiaryLight : null,
                  ),
                ),
              ),
              if (mission.tier != null && mission.tier!.isNotEmpty)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.violet.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    mission.tier!.toUpperCase(),
                    style: AppTypography.labelSmall.copyWith(color: AppColors.violet),
                  ),
                ),
            ],
          ),
          if (mission.description != null && mission.description!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              mission.description!,
              style: AppTypography.bodySmall.copyWith(color: AppColors.textSecondaryLight),
            ),
          ],
          const SizedBox(height: 10),
          // Progress straight from the server's own numbers.
          ChunkyProgressBar(value: mission.progressFraction, color: accent, height: 8),
          const SizedBox(height: 6),
          Row(
            children: [
              Text(
                '${mission.currentCount} / ${mission.targetCount}',
                style: AppTypography.bodySmall.copyWith(fontWeight: FontWeight.w700),
              ),
              const Spacer(),
              if (mission.rewardCoins > 0) _Reward(coins: mission.rewardCoins),
              if (mission.rewardXp > 0) ...[
                const SizedBox(width: 10),
                _Reward(xp: mission.rewardXp),
              ],
            ],
          ),
          if (claimable) ...[
            const SizedBox(height: 12),
            ChunkyButton(
              label: 'Claim ${mission.rewardCoins} coins',
              icon: Icons.redeem_rounded,
              size: ChunkySize.sm,
              loading: busy,
              onPressed: busy ? null : onClaim,
            ),
          ] else if (claimed) ...[
            const SizedBox(height: 8),
            Text(
              'Claimed',
              style: AppTypography.bodySmall.copyWith(
                color: AppColors.correctGreen,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _Reward extends StatelessWidget {
  const _Reward({this.coins = 0, this.xp = 0});

  final int coins;
  final int xp;

  @override
  Widget build(BuildContext context) {
    final color = xp > 0 ? AppColors.xpGold : AppColors.coinYellow;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(xp > 0 ? Icons.bolt : Icons.monetization_on_rounded, size: 13, color: color),
        const SizedBox(width: 2),
        Text('+$xp', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: color)),
      ],
    );
  }
}
