import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/error_view.dart';
import '../controllers/reward_center_controller.dart';

/// Reward center from `GET /reward-center`.
///
/// Everything on this screen is a server status. Claiming and spinning stay on
/// their existing mutation screens — this read-only view never credits coins.
class RewardCenterScreen extends ConsumerWidget {
  const RewardCenterScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(rewardCenterProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.rewardCenterTitle)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: ErrorHandler.handle(e).message,
          onRetry: () => ref.invalidate(rewardCenterProvider),
        ),
        data: (snapshot) {
          final checkIn = snapshot.checkIn;
          final spin = snapshot.spin;
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              Card(
                child: ListTile(
                  leading: const Icon(Icons.account_balance_wallet_outlined),
                  title: Text(l10n.commonWallet),
                  trailing: Text(l10n.libraryCoinsLabel(snapshot.balance)),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.calendar_today_outlined),
                  title: Text(l10n.rewardsDailyCheckIn),
                  subtitle: Text(l10n.rewardsDayStreak(checkIn.streakDay)),
                  trailing: Text(
                    checkIn.claimedToday
                        ? l10n.rewardsClaimedToday
                        : l10n.rewardsCheckInFor(checkIn.todayReward),
                  ),
                ),
              ),
              Card(
                child: ListTile(
                  leading: const Icon(Icons.autorenew_rounded),
                  title: Text(l10n.rewardsSpinWheel),
                  subtitle: Text(
                    spin.canSpin
                        ? l10n.rewardsSpin
                        : spin.nextSpinAt == null
                            ? l10n.rewardsComeBackLater
                            : l10n.rewardsNextSpin(spin.nextSpinAt!),
                  ),
                  trailing: Text('${spin.prizes.length} ${l10n.rewardCenterPrizes}'),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                l10n.profileAchievements,
                style: Theme.of(context).textTheme.titleSmall,
              ),
              if (snapshot.recentAchievements.isEmpty)
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    l10n.achievementsNone,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                )
              else
                for (final achievement in snapshot.recentAchievements)
                  ListTile(
                    dense: true,
                    leading: const Icon(Icons.emoji_events_outlined),
                    title: Text(achievement.name),
                    trailing: Text(l10n.commonPoints(achievement.rewardCoins)),
                  ),
            ],
          );
        },
      ),
    );
  }
}
