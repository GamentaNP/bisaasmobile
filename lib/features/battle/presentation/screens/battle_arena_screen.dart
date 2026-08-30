import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../../domain/entities/battle.dart';
import '../controllers/battle_controller.dart';

/// Battle Arena — real-time 1v1 quiz.
///
/// Server is authoritative (writes scores to RTDB on every answer).
/// Client renders question + listens to RTDB for opponent progress +
/// local timer (synced from RTDB `started_at + per_question_seconds`).
class BattleArenaScreen extends ConsumerWidget {
  const BattleArenaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(battleControllerProvider);
    final ctrl = ref.read(battleControllerProvider.notifier);

    if (state.match == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Battle Arena')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sports_kabaddi_rounded, size: 56, color: AppColors.brand),
                const SizedBox(height: 12),
                const Text('No active match', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () => context.go('/battle/matchmaking'),
                  icon: const Icon(Icons.search_rounded),
                  label: const Text('Find a Match'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    if (state.phase == BattlePhase.finished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        context.go('/battle/result');
      });
    }

    final m = state.match!;
    final q = m.questions[state.currentQuestionIndex];
    final me = m.player1;
    final opp = m.player2;
    final timerPct = m.perQuestionSeconds == 0 ? 0.0 : state.secondsLeftInQuestion / m.perQuestionSeconds;

    return Scaffold(
      appBar: AppBar(
        title: Text('Battle · Q${state.currentQuestionIndex + 1}/${m.questions.length}'),
      ),
      body: Column(
        children: [
          _ScoreHeader(me: me, opponent: opp, timerPct: timerPct.clamp(0.0, 1.0), secondsLeft: state.secondsLeftInQuestion, total: m.perQuestionSeconds),
          if (state.opponentAnsweredThisQ)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.streakOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Row(
                children: [
                  Icon(Icons.bolt_rounded, color: AppColors.streakOrange, size: 14),
                  SizedBox(width: 4),
                  Text('Opponent answered!', style: TextStyle(color: AppColors.streakOrange, fontWeight: FontWeight.bold, fontSize: 12)),
                ],
              ),
            ),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(q.text, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, height: 1.5)),
                  const SizedBox(height: 16),
                  ...q.options.map((o) {
                    final isSelected = state.selectedOptionId == o.id;
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 10),
                      child: InkWell(
                        borderRadius: BorderRadius.circular(12),
                        onTap: state.phase == BattlePhase.inProgress && state.selectedOptionId == null
                            ? () => ctrl.submitAnswer(o.id)
                            : null,
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: isSelected ? AppColors.brand.withValues(alpha: 0.1) : null,
                            border: Border.all(color: isSelected ? AppColors.brand : Theme.of(context).colorScheme.outlineVariant, width: isSelected ? 2 : 1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(o.text, style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal)),
                        ),
                      ),
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ScoreHeader extends StatelessWidget {
  const _ScoreHeader({required this.me, required this.opponent, required this.timerPct, required this.secondsLeft, required this.total});
  final BattlePlayer me;
  final BattlePlayer opponent;
  final double timerPct;
  final int secondsLeft;
  final int total;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: const BoxDecoration(
        color: AppColors.surfaceDark,
        border: Border(bottom: BorderSide(color: AppColors.dividerDark)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(child: _ScoreColumn(player: me, color: AppColors.brand)),
              const SizedBox(width: 8),
              Expanded(child: _ScoreColumn(player: opponent, color: AppColors.comboPurple)),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: timerPct,
              minHeight: 6,
              backgroundColor: AppColors.dividerDark,
              color: timerPct < 0.2 ? AppColors.wrongRed : AppColors.brand,
            ),
          ),
          const SizedBox(height: 4),
          Text('${secondsLeft}s · ${total - secondsLeft}/$total', style: const TextStyle(fontSize: 11, color: AppColors.textTertiaryDark)),
        ],
      ),
    );
  }
}

class _ScoreColumn extends StatelessWidget {
  const _ScoreColumn({required this.player, required this.color});
  final BattlePlayer player;
  final Color color;
  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: 22,
          backgroundColor: color.withValues(alpha: 0.2),
          child: Text(player.displayName.isNotEmpty ? player.displayName[0].toUpperCase() : '?', style: TextStyle(color: color, fontWeight: FontWeight.bold)),
        ),
        const SizedBox(height: 4),
        Text(player.displayName, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        Text('${player.score} pts', style: TextStyle(color: color, fontWeight: FontWeight.bold, fontSize: 13)),
      ],
    );
  }
}
