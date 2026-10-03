import 'deterministic_draw.dart';

/// One bot's answer to one question, offline.
///
/// Deliberately a plain final class: the project has removed the whole
/// freezed/json_serializable/riverpod_generator chain, so there is no codegen
/// here and no annotations. Equatable-by-hand would be a lie anyway — these
/// instances are compared by value in the golden-vector test via `expect`.
final class BotDecisionRequest {
  const BotDecisionRequest({
    required this.seed,
    required this.botKey,
    required this.questionIndex,
    required this.questionId,
    required this.accuracyPercent,
    required this.minAnswerMs,
    required this.maxAnswerMs,
    this.preferredWrongAnswerKey,
  });

  /// Match seed; the server joins its parts with `|`.
  final String seed;
  final String botKey;
  final int questionIndex;
  final int questionId;

  /// Chance of answering correctly, 0-100 inclusive.
  final int accuracyPercent;

  /// Answer window. Both bounds are floored at
  /// [BotDecisionKernel.minimumAnswerWindowMs].
  final int minAnswerMs;
  final int maxAnswerMs;

  /// Option key the bot picks when it gets the question wrong.
  final String? preferredWrongAnswerKey;

  @override
  String toString() {
    return 'BotDecisionRequest(seed: $seed, botKey: $botKey, '
        'questionIndex: $questionIndex, questionId: $questionId, '
        'accuracyPercent: $accuracyPercent, windowMs: $minAnswerMs..$maxAnswerMs)';
  }
}

/// The kernel's verdict for a single question.
final class BotDecision {
  const BotDecision({
    required this.answeredCorrectly,
    required this.durationMs,
    required this.chosenAnswerKey,
  });

  final bool answeredCorrectly;

  /// Deliberately fictional. A phone with no connection has no honest way to
  /// know how long a human took; this is what the server replays, nothing more.
  /// It must never be shown as "the user's response time".
  final int durationMs;

  /// The option the bot picked, or `null` when it answered correctly.
  final String? chosenAnswerKey;

  @override
  String toString() {
    return 'BotDecision(answeredCorrectly: $answeredCorrectly, '
        'durationMs: $durationMs, chosenAnswerKey: $chosenAnswerKey)';
  }
}

/// Port of the server's offline bot decision kernel (`bot-decision/v2`).
///
/// ```text
/// decide(request):
///     drawSeed     = seed|botKey|questionIndex|questionId
///     correctness  = draw(drawSeed, "correctness", 1, 100) <= accuracyPercent
///     minMs        = max(minAnswerMs, 750)
///     maxMs        = max(maxAnswerMs, 750)
///     durationMs   = draw(drawSeed, "duration", minMs, maxMs)
///     chosenKey    = correctness ? null : preferredWrongAnswerKey
/// ```
///
/// Pure Dart on purpose: no Flutter, no Dio, no Riverpod. `domain/` is the
/// Flutter-free layer, and this must stay replayable by a server-side test that
/// never imports Flutter. There is also no randomness anywhere in here — every
/// value is a hash of the request, so a replayed match reproduces exactly.
abstract final class BotDecisionKernel {
  /// The version of this kernel, matching the server's `kernel_version`.
  static const String version = 'bot-decision/v2';

  /// Label for the correctness roll.
  static const String correctnessLabel = 'correctness';

  /// Label for the answer-duration draw.
  static const String durationLabel = 'duration';

  /// The answer window is floored at 750ms on **both** bounds before drawing.
  ///
  /// Reproduced verbatim from the server, including the fact that no committed
  /// golden vector actually exercises it: every vector's window is already at or
  /// above 750ms, so clamping is currently indistinguishable from not clamping.
  /// It is kept because it is part of the contract and the first sub-750 window
  /// to appear would otherwise desynchronise Dart from PHP. See the parity test
  /// for the case that pins the intent explicitly.
  static const int minimumAnswerWindowMs = 750;

  /// Rolls the correctness of a single answer.
  ///
  /// The range is 1..100 rather than 0..99, so `accuracyPercent: 0` is an
  /// unconditional miss and `accuracyPercent: 100` is an unconditional hit. That
  /// off-by-one is easy to "fix" into a bug: shifting to 0..99 would hand every
  /// 0%-accuracy bot a 1% chance of being right and skew every match it plays.
  static bool isCorrect(BotDecisionRequest request) {
    final roll = _roll(request, correctnessLabel, min: 1, max: 100);
    return roll <= request.accuracyPercent;
  }

  /// Draws the bot's answer duration in milliseconds.
  static int drawDurationMs(BotDecisionRequest request) {
    final min = _flooredWindow(request.minAnswerMs);
    final max = _flooredWindow(request.maxAnswerMs);
    return _roll(request, durationLabel, min: min, max: max);
  }

  /// Runs the full kernel for one question.
  static BotDecision decide(BotDecisionRequest request) {
    final correct = isCorrect(request);
    return BotDecision(
      answeredCorrectly: correct,
      durationMs: drawDurationMs(request),
      // A correct answer has no chosen *wrong* key; the server omits it rather
      // than echoing the preferred distractor back, and so does this.
      chosenAnswerKey:
          correct ? null : request.preferredWrongAnswerKey,
    );
  }

  static int _flooredWindow(int value) {
    return value < minimumAnswerWindowMs ? minimumAnswerWindowMs : value;
  }

  static int _roll(
    BotDecisionRequest request,
    String label, {
    required int min,
    required int max,
  }) {
    final drawSeed = DeterministicDraw.seedFor(
      seed: request.seed,
      botKey: request.botKey,
      questionIndex: request.questionIndex,
      questionId: request.questionId,
    );
    return DeterministicDraw.draw(drawSeed, label, min: min, max: max);
  }
}
