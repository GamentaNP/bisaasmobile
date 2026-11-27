import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../l10n/app_localizations.dart';
import '../../domain/entities/battle.dart';

/// The server's `alpha`/`bravo` team keys are protocol values, not copy.
String? battleTeamLabel(String? team, AppLocalizations l10n) {
  if (team == null || team.isEmpty) return null;
  return switch (team.toLowerCase()) {
    'alpha' => l10n.battleTeamAlpha,
    'bravo' => l10n.battleTeamBravo,
    _ => l10n.battleTeamLabel(team),
  };
}

/// Live score strip for any number of players.
///
/// The old arena hard-coded `player1`/`player2`, so a 2v2 or 3v3 battle could
/// only ever show two of the six participants. Players are grouped by the
/// team the server published; a 1v1 payload (no `team`) renders flat.
class BattleScoreBoard extends StatelessWidget {
  const BattleScoreBoard({
    super.key,
    required this.players,
    required this.meUid,
    required this.timerPct,
    required this.secondsLeft,
    required this.total,
    this.winnerUid,
  });

  final List<BattlePlayer> players;
  final String meUid;
  final double timerPct;
  final int secondsLeft;
  final int total;
  final String? winnerUid;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final hasTeams = players.any((p) => p.team != null && p.team!.isNotEmpty);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(bottom: BorderSide(color: AppColors.dividerDark)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (hasTeams)
            ..._teamGroups().entries.map(
              (entry) => Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (entry.key != null)
                      Text(
                        battleTeamLabel(entry.key!, l10n) ?? '',
                        style: const TextStyle(
                          fontSize: 11,
                          color: AppColors.textTertiaryDark,
                        ),
                      ),
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        for (final p in entry.value)
                          _PlayerChip(
                            player: p,
                            meUid: meUid,
                            isWinner: winnerUid != null && winnerUid == p.uid,
                          ),
                      ],
                    ),
                  ],
                ),
              ),
            )
          else
            Wrap(
              spacing: 8,
              runSpacing: 6,
              children: [
                for (final p in players)
                  _PlayerChip(
                    player: p,
                    meUid: meUid,
                    isWinner: winnerUid != null && winnerUid == p.uid,
                  ),
              ],
            ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: timerPct.clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: AppColors.dividerDark,
              color: timerPct < 0.2 ? AppColors.wrongRed : AppColors.brand,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            l10n.battleTimer(secondsLeft, total - secondsLeft, total),
            style: const TextStyle(fontSize: 11, color: AppColors.textTertiaryDark),
          ),
        ],
      ),
    );
  }

  Map<String?, List<BattlePlayer>> _teamGroups() {
    final groups = <String?, List<BattlePlayer>>{};
    for (final p in players) {
      final key = (p.team == null || p.team!.isEmpty) ? null : p.team;
      groups.putIfAbsent(key, () => <BattlePlayer>[]).add(p);
    }
    return groups;
  }
}

class _PlayerChip extends StatelessWidget {
  const _PlayerChip({
    required this.player,
    required this.meUid,
    required this.isWinner,
  });
  final BattlePlayer player;
  final String meUid;
  final bool isWinner;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final isMe = player.uid == meUid;
    final color = isWinner
        ? AppColors.xpGold
        : (isMe ? AppColors.brand : AppColors.comboPurple);
    final name = player.displayName.isNotEmpty
        ? player.displayName
        : (isMe ? l10n.battleYou : l10n.battleOpponent);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.35)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircleAvatar(
            radius: 12,
            backgroundColor: color.withValues(alpha: 0.2),
            child: Text(
              name[0].toUpperCase(),
              style: TextStyle(color: color, fontSize: 11, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 6),
          ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 96),
            child: Text(
              name,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            l10n.commonPoints(player.score),
            style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 11),
          ),
        ],
      ),
    );
  }
}
