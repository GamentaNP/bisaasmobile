/// The three arcade modes this client can actually start.
///
/// Only these three exist as API start routes (`routes/api/v1/quiz.php`):
/// `POST /quiz/survival/start`, `/quiz/lightning/start`, `/quiz/true-false/start`.
/// The server's `QuizAttemptMode` enum carries five more arcade values
/// (`guess_the_word`, `word_scramble`, `math_mania`, `audio_questions`,
/// `fun_and_learn`), but they have no mobile start endpoint — their hubs are
/// web routes. Offering them here would be a button that 404s, so they are
/// deliberately absent rather than half-wired.
///
/// The numbers below are the server's own rules (`ArcadeModeService::rulesFor`).
/// They are duplicated in two places on purpose: the client uses them to pace
/// the UI, and the server enforces them regardless. If the server changes a
/// limit, the client's copy only affects presentation — it can never change
/// the score.
library;

enum ArcadeMode {
  /// An endless run: questions keep coming until the first wrong answer.
  /// The server completes the attempt itself when that happens, so the run
  /// ends when a re-fetch says so — not when the client decides.
  survival(
    wire: 'survival',
    startPath: '/quiz/survival/start',
    questionLimit: 50,
    minimumQuestions: 5,
    secondsPerQuestion: null,
    endsOnWrongAnswer: true,
  ),

  /// Ten questions, five seconds each. No penalty for a miss beyond the mark.
  lightning(
    wire: 'lightning',
    startPath: '/quiz/lightning/start',
    questionLimit: 10,
    minimumQuestions: 10,
    secondsPerQuestion: 5,
    endsOnWrongAnswer: false,
  ),

  /// Thirty rapid True/False prompts, five seconds each.
  trueFalse(
    wire: 'true_false',
    startPath: '/quiz/true-false/start',
    questionLimit: 30,
    minimumQuestions: 20,
    secondsPerQuestion: 5,
    endsOnWrongAnswer: false,
  );

  const ArcadeMode({
    required this.wire,
    required this.startPath,
    required this.questionLimit,
    required this.minimumQuestions,
    required this.secondsPerQuestion,
    required this.endsOnWrongAnswer,
  });

  /// The `mode` value the server reports (`true_false`, not `true-false`).
  final String wire;

  /// The hyphenated route segment, which does not follow the enum value.
  final String startPath;

  /// How many questions a round asks at most.
  final int questionLimit;

  /// The inventory a category needs before the mode is playable.
  final int minimumQuestions;

  /// Per-question countdown, or null for an untimed mode.
  final int? secondsPerQuestion;

  /// Whether the server ends the attempt on the first wrong answer.
  final bool endsOnWrongAnswer;

  bool get isTimed => secondsPerQuestion != null;

  static ArcadeMode? fromWire(String? value) {
    for (final mode in ArcadeMode.values) {
      if (mode.wire == value) return mode;
    }
    return null;
  }
}
