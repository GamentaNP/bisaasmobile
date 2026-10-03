import 'bot_decision_kernel.dart';
import 'offline_bot_models.dart';

/// One question an offline match will ask.
///
/// The correct option key is deliberately absent. The kernel decides a bot's
/// correctness from the bot's accuracy against a 1..100 roll — it never reads
/// the question's answer key — so a device can simulate a convincing match
/// while holding no key at all.
///
/// That is not a convenience, it is the boundary. A client that had the key
/// could grade the learner locally, and a local grade is a claim the server
/// cannot audit. Offline play therefore simulates opponents and nothing else:
/// no score, no XP, no coins, no leaderboard position. Those come only from the
/// online, server-graded pipeline.
class OfflineMatchQuestion {
  const OfflineMatchQuestion({required this.id, required this.position});

  final int id;

  /// Position in the match. Part of the seed, so two questions swapped in the
  /// order produce a different match — the bot behaviour is bound to the round,
  /// not just to the question.
  final int position;
}

/// Runs a whole offline match locally and produces the receipt.
///
/// Pure: no I/O, no clock, no randomness. The same roster and questions always
/// produce byte-identical decisions, which is what lets the server replay them
/// later and tell an honest device from a forged one.
abstract final class OfflineMatchSimulator {
  /// Simulate [roster] across [questions] and return the receipt.
  ///
  /// [misconceptionTargets] maps question id → misconception code → option key,
  /// so a bot that targets a misconception picks that specific distractor. It is
  /// supplied by the caller because consensus over the pack is the server's
  /// call, not the device's: two devices must not disagree about which
  /// distractor is the misconception.
  static OfflineMatchReceipt simulate({
    required OfflineBotRoster roster,
    required List<OfflineMatchQuestion> questions,
    Map<int, Map<String, String>> misconceptionTargets = const {},
  }) {
    final decisions = <OfflineBotDecision>[];

    for (final question in questions) {
      final targets = misconceptionTargets[question.id] ?? const {};

      for (final opponent in roster.opponents) {
        final decision = BotDecisionKernel.decide(
          BotDecisionRequest(
            seed: roster.seed,
            botKey: opponent.botKey,
            questionIndex: question.position,
            questionId: question.id,
            accuracyPercent: opponent.accuracyRate,
            minAnswerMs: opponent.minAnswerMs,
            maxAnswerMs: opponent.maxAnswerMs,
            preferredWrongAnswerKey: opponent.misconceptionCode == null
                ? null
                : targets[opponent.misconceptionCode],
          ),
        );

        decisions.add(
          OfflineBotDecision.fromDecision(
            botKey: opponent.botKey,
            questionIndex: question.position,
            questionId: question.id,
            decision: decision,
          ),
        );
      }
    }

    return OfflineMatchReceipt(
      manifestId: roster.manifestId,
      seed: roster.seed,
      // Echoed from the roster, not from this build: the receipt is replayed
      // under the version that produced it, and a client that substituted its
      // own would be claiming a verdict for rules the server never ran.
      kernelVersion: roster.kernelVersion,
      decisions: List.unmodifiable(decisions),
    );
  }
}
