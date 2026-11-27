import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/providers.dart';
import '../../data/datasources/battle_remote_data_source.dart';
import '../../domain/battle_outcome.dart';
import '../controllers/battle_controller.dart';
import '../widgets/battle_score_board.dart';
import '../../../../l10n/app_localizations.dart';

/// Fetches the authoritative outcome.
///
/// The screen previously computed it client-side as
/// `winnerUid == null || winnerUid == me.uid || me.score >= opp.score`, which
/// rendered an **unresolved** battle as a victory and a score tie as a victory
/// too. `GET /quiz/battles/{id}/results` decides it server-side, so a pending
/// battle is shown as pending instead of being invented.
///
/// The real current user id travels with the key: passing `null` made every
/// result render as a loss.
typedef BattleOutcomeKey = ({String battleId, int? currentUserId, String? currentUid});

final battleOutcomeProvider =
    FutureProvider.family<BattleOutcome, BattleOutcomeKey>((ref, key) async {
  final raw = await BattleRemoteDataSource(ref.watch(dioProvider))
      .getResults(key.battleId);
  return BattleOutcome.fromResults(
    raw,
    currentUserId: key.currentUserId,
    currentUid: key.currentUid,
  );
});

/// Post-battle result. The verdict comes from the server, not from comparing
/// scores on the device. Confetti for a win, subtle anim for a loss, and an
/// honest "result pending" state when the battle has not resolved.
class BattleResultScreen extends ConsumerWidget {
  const BattleResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(battleControllerProvider);
    final m = state.match;
    if (m == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.battleResultTitle)),
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(l10n.battleNoMatchToDisplay),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(l10n.commonGoBack),
              ),
            ],
          ),
        ),
      );
    }

    // `me.uid` from the server is authoritative for identity; the Firebase
    // SDK's local uid is only a fallback for a payload that omitted it.
    final myUid = m.meUid.isNotEmpty ? m.meUid : (state.myUid ?? '');
    final key = (
      battleId: m.rtdbId,
      currentUserId: m.currentUserId,
      currentUid: myUid.isEmpty ? null : myUid,
    );
    final outcomeAsync = ref.watch(battleOutcomeProvider(key));
    final outcome = outcomeAsync.value;

    // Fall back to the RTDB-derived winner ONLY when the server call fails,
    // and treat "unknown" as unknown — never as a win.
    final rtdbWin = state.winnerUid != null &&
        state.winnerUid!.isNotEmpty &&
        state.winnerUid == myUid;
    final bool isWin;
    final bool isPending;
    final String headline;
    if (outcome != null) {
      isWin = outcome.isWin;
      headline = switch (outcome.result) {
        'win' => l10n.battleResultWin,
        'loss' => l10n.battleResultLoss,
        'draw' => l10n.battleResultDraw,
        _ => l10n.battleResultPending,
      };
      isPending = outcome.isPending;
    } else if (outcomeAsync.hasError) {
      isWin = rtdbWin;
      // An unreadable result AND an unknown RTDB winner is pending, not a
      // loss invented from the absence of a winner.
      isPending = state.winnerUid == null || state.winnerUid!.isEmpty;
      headline = isPending
          ? l10n.battleResultPending
          : (rtdbWin ? l10n.battleResultWin : l10n.battleResultLoss);
    } else {
      isWin = false;
      isPending = true;
      headline = l10n.battleResultPending;
    }

    final winnerUid = outcome?.winnerUid ?? state.winnerUid;
    final scorePlayers = outcome != null && outcome.players.isNotEmpty
        ? outcome.players
            .map(
              (p) => _ScoreLine(
                uid: p.uid,
                name: p.name,
                team: p.team,
                score: p.score,
                isMe: p.isMe,
                isWinner: p.isWinner,
              ),
            )
            .toList()
        : m.allPlayers
            .map(
              (p) => _ScoreLine(
                uid: p.uid,
                name: p.displayName,
                team: p.team,
                score: p.score,
                isMe: p.uid == myUid,
                isWinner: winnerUid != null && winnerUid == p.uid,
              ),
            )
            .toList();
    final me = scorePlayers.where((p) => p.isMe).firstOrNull;
    final myScore = me?.score ?? 0;
    final rivalScore = scorePlayers
        .where((p) => !p.isMe)
        .fold<int>(0, (max, p) => p.score > max ? p.score : max);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              if (isPending)
                const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Lottie.asset(
                    isWin
                        ? 'assets/animations/battle_win.json'
                        : 'assets/animations/battle_lose.json',
                    repeat: false,
                  ),
                ),
              const SizedBox(height: 16),
              Text(
                headline,
                style: TextStyle(
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                  color: isWin ? AppColors.xpGold : AppColors.textSecondaryDark,
                ),
              ),
              if (outcomeAsync.hasError && outcome == null) ...[
                const SizedBox(height: 8),
                Text(
                  battleErrorMessage(outcomeAsync.error!),
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: AppColors.wrongRed, fontSize: 12),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () => ref.invalidate(battleOutcomeProvider(key)),
                  icon: const Icon(Icons.replay_rounded),
                  label: Text(l10n.retry),
                ),
              ],
              const SizedBox(height: 24),
              // Every participant is listed — 2v2/3v3 rosters used to be
              // truncated to two hard-coded columns.
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 12,
                runSpacing: 12,
                children: [
                  for (final p in scorePlayers) _ResultColumn(player: p),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/battle/matchmaking'),
                icon: const Icon(Icons.replay_rounded),
                label: Text(l10n.battleRematch),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _share(context, scorePlayers, myScore, rivalScore),
                icon: const Icon(Icons.share_rounded),
                label: Text(l10n.commonShareResult),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  ref.read(battleControllerProvider.notifier).reset();
                  context.go('/home');
                },
                child: Text(l10n.quizResultBackToHome),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _share(
    BuildContext context,
    List<_ScoreLine> players,
    int myScore,
    int rivalScore,
  ) async {
    final l10n = AppLocalizations.of(context)!;
    // The invitation copy itself is translated; the figures are the server's
    // result and the display name is whatever the server published.
    final rival = players.where((p) => !p.isMe).firstOrNull;
    final rivalName = rival != null && rival.name.isNotEmpty
        ? rival.name
        : l10n.battleOpponent;
    final msg = '${l10n.socialShareMomentFallback} '
        '$myScore-$rivalScore ${l10n.battleVs} $rivalName';
    try {
      await SharePlus.instance.share(
        ShareParams(text: msg, subject: l10n.battleResultTitle),
      );
    } catch (_) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(l10n.battleShareUnavailable)),
        );
      }
    }
  }
}

@immutable
class _ScoreLine {
  const _ScoreLine({
    required this.uid,
    required this.name,
    required this.team,
    required this.score,
    required this.isMe,
    required this.isWinner,
  });
  final String uid;
  final String name;
  final String? team;
  final int score;
  final bool isMe;
  final bool isWinner;
}

class _ResultColumn extends StatelessWidget {
  const _ResultColumn({required this.player});
  final _ScoreLine player;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final displayName = player.name.isNotEmpty
        ? player.name
        : (player.isMe ? l10n.battleYou : l10n.battleOpponent);
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          Stack(
            alignment: Alignment.center,
            children: [
              CircleAvatar(
                radius: 32,
                backgroundColor:
                    (player.isWinner ? AppColors.xpGold : AppColors.dividerDark)
                        .withValues(alpha: 0.3),
                child: Text(
                  displayName[0].toUpperCase(),
                  style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
              ),
              if (player.isWinner)
                const Positioned(
                  bottom: 0,
                  right: 0,
                  child: DecoratedBox(
                    decoration: BoxDecoration(color: AppColors.xpGold, shape: BoxShape.circle),
                    child: Padding(
                      padding: EdgeInsets.all(4),
                      child: Icon(Icons.emoji_events_rounded, color: Colors.white, size: 14),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 6),
          if (player.team != null && player.team!.isNotEmpty)
            Text(
              battleTeamLabel(player.team!, l10n) ?? '',
              style: const TextStyle(fontSize: 10, color: AppColors.textTertiaryDark),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          Text(
            player.isMe ? l10n.battleYou : displayName,
            style: const TextStyle(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          Text(
            l10n.commonPoints(player.score),
            style: TextStyle(
              color: player.isWinner ? AppColors.xpGold : null,
              fontSize: 16,
              fontWeight: FontWeight.bold,
            ),
          ),
        ],
      ),
    );
  }
}
