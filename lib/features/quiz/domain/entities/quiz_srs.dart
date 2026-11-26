/// Domain model for the unified QUIZ spaced-repetition queue.
///
/// `GET /api/v1/quiz/reviews/due` merges MCQ question-progress and word-bank
/// progress rows. This is deliberately **not** the Learning-domain atom queue
/// (`/learning/reviews/*`): the two use different ids and different engines,
/// so their entities are kept separate too.
///
/// Scheduling is server-authoritative. A card carries the server's interval,
/// repetitions and easiness factor for display only — the client never
/// recomputes a due date or a grade.
library;

/// Wire values the server validates for `type`.
abstract final class QuizSrsCardType {
  static const String question = 'question';
  static const String word = 'word';

  static bool isValid(String value) =>
      value == question || value == word;
}

/// A prompt-only card. Answer keys and explanations are withheld by the
/// server, so nothing here can be used to reveal a correct answer.
class QuizSrsCard {
  const QuizSrsCard({
    required this.id,
    required this.type,
    required this.content,
    required this.dueAt,
    this.questionId,
    this.wordId,
    this.options = const <QuizSrsOption>[],
    this.itemType,
    this.difficulty,
    this.definition,
    this.example,
    this.dueReason,
    this.overdueDays = 0,
    this.intervalDays = 0,
    this.repetitions = 0,
    this.easinessFactor = 0,
  });

  /// Progress-row id — the `{review}` path parameter on the grade endpoint.
  final String id;
  final String type;
  final String content;
  final DateTime dueAt;
  final int? questionId;
  final int? wordId;
  final List<QuizSrsOption> options;
  final String? itemType;
  final String? difficulty;
  final String? definition;
  final String? example;
  final String? dueReason;
  final int overdueDays;
  final int intervalDays;
  final int repetitions;
  final double easinessFactor;

  bool get isQuestion => type == QuizSrsCardType.question;
  bool get isWord => type == QuizSrsCardType.word;
  bool get isOverdue => overdueDays > 0;
}

/// A visible option on an MCQ card. [label] is the server's option key (the
/// grader matches it); neither field carries correctness.
class QuizSrsOption {
  const QuizSrsOption({required this.label, required this.text});

  final String label;
  final String text;
}

/// Server-computed SM-2 result of a grade.
class QuizSrsGradeResult {
  const QuizSrsGradeResult({
    required this.id,
    required this.type,
    required this.quality,
    required this.intervalDays,
    required this.repetitions,
    required this.easinessFactor,
    this.dueAt,
  });

  final String id;
  final String type;
  final int quality;
  final int intervalDays;
  final int repetitions;
  final double easinessFactor;
  final DateTime? dueAt;
}

/// Quality values sent to `PUT /quiz/reviews/{review}/grade`.
///
/// The server accepts 0–5; 0 (complete blackout) is not offered in the UI.
/// These are the client's labels for the same numeric scale, not a local
/// scheduling decision — the engine on the server owns the interval.
abstract final class QuizSrsQuality {
  static const int again = 1;
  static const int hard = 2;
  static const int good = 4;
  static const int easy = 5;

  static bool isValid(int value) => value >= 0 && value <= 5;
}
