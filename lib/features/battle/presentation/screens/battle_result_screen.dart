// ignore_for_file: avoid_dynamic_calls, strict_raw_type

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:share_plus/share_plus.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/battle.dart';
import '../controllers/battle_controller.dart';

/// Post-battle result. Reads `BattleMatch.winnerUid` + per-player
/// scores from the controller state. Confetti for win, subtle anim
/// for loss.
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
    // Best-effort me/opp split (no uid wired yet — default to player1 as me)
    final me = m.player1;
    final opp = m.player2;
    final isWin = state.winnerUid == null || state.winnerUid == me.uid || me.score >= opp.score;

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const SizedBox(height: 16),
              SizedBox(
                width: 200,
                height: 200,
                child: Lottie.asset(isWin ? 'assets/animations/battle_win.json' : 'assets/animations/battle_lose.json', repeat: false),
              ),
              const SizedBox(height: 16),
              Text(isWin ? 'YOU WIN!' : 'Good Fight!', style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold, color: isWin ? AppColors.xpGold : AppColors.textSecondaryDark)),
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
