import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/theme/app_colors.dart';
import '../controllers/battle_controller.dart';
import '../widgets/battle_score_board.dart';
import '../../../../l10n/app_localizations.dart';

/// Live battle arena.
///
/// Server is authoritative (writes scores to RTDB on every answer). The clock
/// is derived from the server's `started_at` + `per_question_seconds`, never
/// re-based on the moment the screen opened, so the question index advances.
class BattleArenaScreen extends ConsumerWidget {
  const BattleArenaScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(battleControllerProvider);
    final ctrl = ref.read(battleControllerProvider.notifier);

    if (state.phase == BattlePhase.error) {
      return _ErrorBody(
        title: l10n.battlePhaseMatchFailed,
        message: state.error ?? l10n.errRequestFailed,
        onRetry: ctrl.retry,
      );
    }

    if (state.match == null) {
      return Scaffold(
        appBar: AppBar(title: Text(l10n.battleArena)),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.sports_kabaddi_rounded, size: 56, color: AppColors.brand),
                const SizedBox(height: 12),
                Text(l10n.battleNoActiveMatch, style: const TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                FilledButton.icon(
                  onPressed: () => context.go('/battle/matchmaking'),
                  icon: const Icon(Icons.search_rounded),
                  label: Text(l10n.battleFindMatch),
                ),
                const SizedBox(height: 8),
                OutlinedButton.icon(
                  onPressed: () {
                    ctrl.reset();
                    context.go('/home');
                  },
                  icon: const Icon(Icons.arrow_back_rounded),
                  label: Text(l10n.commonGoBack),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final m = state.match!;
    // Canonical `me.uid` is the identity used by the server's `players` map.
    final myUid = m.meUid.isNotEmpty ? m.meUid : (state.myUid ?? '');

    // A match the server opened without questions is drift, not an empty
    // arena. Retry re-runs matchmaking with the same mode.
    if (m.questions.isEmpty) {
      return _ErrorBody(
        title: l10n.battleNoQuestions,
        message: l10n.battleNoQuestionsFromServer,
        onRetry: ctrl.retry,
      );
    }

    if (state.phase == BattlePhase.finished) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (context.mounted) context.go('/battle/result');
      });
    }

    // Clamp: the question list can shrink under the user and an out-of-range
    // index must never crash a build.
    final index = state.currentQuestionIndex.clamp(0, m.questions.length - 1);
    final q = m.questions[index];
    final timerPct = m.perQuestionSeconds == 0
        ? 0.0
        : state.secondsLeftInQuestion / m.perQuestionSeconds;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.battleQuestionCounter(index + 1, m.questions.length)),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: l10n.commonClose,
          onPressed: () {
            ctrl.reset();
            context.go('/home');
          },
        ),
      ),
      body: Column(
        children: [
          BattleScoreBoard(
            players: m.allPlayers,
            meUid: myUid,
            timerPct: timerPct,
            secondsLeft: state.secondsLeftInQuestion,
            total: m.perQuestionSeconds,
            winnerUid: state.winnerUid,
          ),
          if (state.opponentAnsweredThisQ)
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.streakOrange.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  const Icon(Icons.bolt_rounded, color: AppColors.streakOrange, size: 14),
                  const SizedBox(width: 4),
                  Text(
                    l10n.battleOpponentAnswered,
                    style: const TextStyle(
                      color: AppColors.streakOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
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
                            border: Border.all(
                              color: isSelected
                                  ? AppColors.brand
                                  : Theme.of(context).colorScheme.outlineVariant,
                              width: isSelected ? 2 : 1,
                            ),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            o.text,
                            style: TextStyle(fontWeight: isSelected ? FontWeight.bold : FontWeight.normal),
                          ),
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

/// Shared error surface: localized copy, a real retry and a way out.
class _ErrorBody extends StatelessWidget {
  const _ErrorBody({
    required this.title,
    required this.message,
    required this.onRetry,
  });

  final String title;
  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(title: Text(l10n.battleArena)),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.wrongRed),
              const SizedBox(height: 12),
              Text(title, textAlign: TextAlign.center, style: const TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: onRetry,
                icon: const Icon(Icons.replay_rounded),
                label: Text(l10n.retry),
              ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () => context.go('/home'),
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(l10n.commonGoBack),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
