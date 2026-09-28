

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../core/network/dio_client.dart';
import '../../data/datasources/battle_remote_data_source.dart';
import '../../domain/battle_outcome.dart';
import '../../domain/entities/battle.dart';
import '../controllers/battle_controller.dart';

/// Fetches the authoritative outcome.
///
/// The screen previously computed it client-side as
/// `winnerUid == null || winnerUid == me.uid || me.score >= opp.score`, which
/// rendered an **unresolved** battle as a victory and a score tie as a victory
/// too. `GET /quiz/battles/{id}/results` decides it server-side, so a pending
/// battle is shown as pending instead of being invented.
final battleOutcomeProvider = FutureProvider.family<BattleOutcome, String>((
  ref,
  battleId,
) async {
  final raw = await BattleRemoteDataSource(DioClient.instance.dio).getResults(battleId);
  return BattleOutcome.fromResults(raw, currentUserId: null);
});

/// Post-battle result. The verdict comes from the server, not from comparing
/// scores on the device. Confetti for a win, subtle anim for a loss, and an
/// honest "result pending" state when the battle has not resolved.
class BattleResultScreen extends ConsumerWidget {
  const BattleResultScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(battleControllerProvider);
    final m = state.match;
    if (m == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Battle Result')),
        body: const Center(child: Text('No match to display')),
      );
    }

    final outcomeAsync = ref.watch(battleOutcomeProvider(m.id));
    final outcome = outcomeAsync.value;

    // Fall back to the RTDB-derived winner ONLY when the server call fails, and
    // treat "unknown" as unknown — never as a win.
    final rtdbSaysWin = state.winnerUid != null && state.winnerUid == m.player1.uid;
    final bool isWin;
    final String headline;
    if (outcome != null) {
      isWin = outcome.isWin;
      headline = switch (outcome.result) {
        'win' => 'YOU WIN!',
        'loss' => 'Good Fight!',
        'draw' => 'DRAW',
        _ => 'Result pending',
      };
    } else if (outcomeAsync.hasError) {
      isWin = rtdbSaysWin;
      headline = rtdbSaysWin ? 'YOU WIN!' : 'Good Fight!';
    } else {
      isWin = false;
      headline = 'Result pending';
    }

    // Best-effort me/opp split (no uid wired yet — default to player1 as me)
    final me = m.player1;
    final opp = m.player2;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              if (!isWin && headline == 'Result pending')
                const SizedBox(
                  height: 120,
                  child: Center(child: CircularProgressIndicator()),
                )
              else
                SizedBox(
                  width: 200,
                  height: 200,
                  child: Lottie.asset(isWin ? 'assets/animations/battle_win.json' : 'assets/animations/battle_lose.json', repeat: false),
                ),
              const SizedBox(height: 16),
              Text(headline, style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isWin ? AppColors.xpGold : AppColors.textSecondaryDark)),
              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _ResultColumn(player: me, isWinner: isWin, isMe: true),
                  const Text('VS', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey)),
                  _ResultColumn(player: opp, isWinner: !isWin, isMe: false),
                ],
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                onPressed: () => context.go('/battle/matchmaking'),
                icon: const Icon(Icons.replay_rounded),
                label: const Text('Rematch'),
                style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
              ),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: () => _share(context, isWin, me, opp),
                icon: const Icon(Icons.share_rounded),
                label: const Text('Share Result'),
                style: OutlinedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              ),
              const SizedBox(height: 8),
              TextButton(
                onPressed: () {
                  ref.read(battleControllerProvider.notifier).reset();
                  context.go('/home');
                },
                child: const Text('Back to Home'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _share(BuildContext context, bool isWin, BattlePlayer me, BattlePlayer opp) async {
    final msg = 'I just ${isWin ? "won" : "fought"} a battle on CivilCal: ${me.score}-${opp.score} vs ${opp.displayName}! Try me: https://bisaas.com';
    try {
      await SharePlus.instance.share(ShareParams(text: msg, subject: 'CivilCal Battle Result'));
    } catch (_) {
      if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Share unavailable')));
    }
  }
}

class _ResultColumn extends StatelessWidget {
  const _ResultColumn({required this.player, required this.isWinner, required this.isMe});
  final BattlePlayer player;
  final bool isWinner;
  final bool isMe;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.center,
          children: [
            CircleAvatar(
              radius: 36,
              backgroundColor: (isWinner ? AppColors.xpGold : AppColors.dividerDark).withValues(alpha: 0.3),
              child: Text(player.displayName.isNotEmpty ? player.displayName[0].toUpperCase() : '?', style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
            ),
            if (isWinner)
              Positioned(
                bottom: 0,
                right: 0,
                child: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(color: AppColors.xpGold, shape: BoxShape.circle),
                  child: const Icon(Icons.emoji_events_rounded, color: Colors.white, size: 14),
                ),
              ),
          ],
        ),
        const SizedBox(height: 6),
        Text(isMe ? 'You' : player.displayName, style: const TextStyle(fontWeight: FontWeight.bold)),
        Text('${player.score} pts', style: TextStyle(color: isWinner ? AppColors.xpGold : null, fontSize: 16, fontWeight: FontWeight.bold)),
      ],
    );
  }
}
