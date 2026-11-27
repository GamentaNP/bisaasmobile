import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/errors/error_handler.dart';
import '../../../../l10n/app_localizations.dart';
import '../../../../shared/widgets/empty_state.dart';
import '../../../../shared/widgets/error_view.dart';
import '../../domain/entities/impact_leaders.dart';
import '../controllers/impact_leaders_controller.dart';

/// Opt-in Community Impact leaderboard from `GET /social/impact-leaders`.
///
/// Ranks, scores and qualified-referral counts are server-computed; the screen
/// only renders them with already-translated labels.
class ImpactLeadersScreen extends ConsumerWidget {
  const ImpactLeadersScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(impactLeadersProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.impactLeadersTitle)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => ErrorView(
          message: ErrorHandler.handle(e).message,
          onRetry: () => ref.invalidate(impactLeadersProvider),
        ),
        data: (snapshot) => ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (snapshot.viewerRank != null)
              Card(
                child: ListTile(
                  leading: const Icon(Icons.person_outlined),
                  title: Text(l10n.leaderboardRankIn(
                    snapshot.viewerRank!,
                    l10n.commonLeaderboard,
                  )),
                ),
              ),
            if (snapshot.leaders.isEmpty)
              EmptyState(
                title: l10n.leaderboardNoEntries,
                subtitle: l10n.leaderboardCompeteToAppear,
                icon: Icons.emoji_events_outlined,
              )
            else
              for (var i = 0; i < snapshot.leaders.length; i++)
                _LeaderTile(
                  rank: i + 1,
                  leader: snapshot.leaders[i],
                ),
          ],
        ),
      ),
    );
  }
}

class _LeaderTile extends StatelessWidget {
  const _LeaderTile({required this.rank, required this.leader});

  final int rank;
  final ImpactLeader leader;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return ListTile(
      leading: CircleAvatar(child: Text('$rank')),
      title: Text(leader.name),
      subtitle: Text('${leader.qualifiedReferrals} ${l10n.impactLeaderQualifiedReferrals}'),
      trailing: Text(l10n.leaderboardScore(leader.score)),
    );
  }
}
