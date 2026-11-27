/// Pure Dart domain models for the learner-review cluster.
///
/// `GET /quiz/review/due` is a prompt-only queue: the server withholds answer
/// keys and explanations, so nothing here can reveal a correct answer.
/// `GET /quiz/attempts/{attempt}/review` is the verdict sheet of a completed
/// attempt, gated by the server's release policy. Scheduling and grading stay
/// server-authoritative — the interval fields are display-only.
library;

abstract final class ReviewCardType {
  static const String question = 'question';
  static const String word = 'word';

  static bool isValid(String value) => value == question || value == word;
}

class ReviewCard {
  const ReviewCard({
    required this.id,
    required this.type,
    required this.content,
    required this.dueAt,
    this.options = const <ReviewOption>[],
    this.questionId,
    this.wordId,
    this.itemType,
    this.difficulty,
    this.dueReason,
    this.definition,
    this.example,
    this.overdueDays = 0,
    this.intervalDays = 0,
    this.repetitions = 0,
    this.easinessFactor = 0,
  });

  /// Progress-row id — the `{review}` segment of the grade endpoint.
  final String id;
  final String type;
  final String content;
  final DateTime dueAt;
  final List<ReviewOption> options;
  final int? questionId;
  final int? wordId;
  final String? itemType;
  final String? difficulty;
  final String? dueReason;
  final String? definition;
  final String? example;
  final int overdueDays;
  final int intervalDays;
  final int repetitions;
  final double easinessFactor;

  bool get isQuestion => type == ReviewCardType.question;
  bool get isWord => type == ReviewCardType.word;
  bool get isOverdue => overdueDays > 0;
}

class ReviewOption {
  const ReviewOption({required this.label, required this.text});

  final String label;
  final String text;
}

/// Server-computed SM-2 outcome. The client never calculates one.
class ReviewGradeResult {
  const ReviewGradeResult({
    required this.id,
    required this.type,
    required this.quality,
    this.intervalDays = 0,
    this.repetitions = 0,
    this.easinessFactor = 0,
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

abstract final class ReviewQuality {
  static const int again = 1;
  static const int hard = 2;
  static const int good = 4;
  static const int easy = 5;

  static bool isValid(int value) => value >= 0 && value <= 5;
}

/// The release gate mirrored from the results endpoint. A locked high-stakes
/// attempt publishes no verdicts at all — never guess one on-device.
class ReviewPolicy {
  const ReviewPolicy({
    required this.answersVisible,
    required this.locked,
    required this.isHighStakes,
    required this.releaseMode,
    required this.released,
  });

  final bool answersVisible;
  final bool locked;
  final bool isHighStakes;
  final String releaseMode;
  final bool released;
}

class AttemptReviewItem {
  const AttemptReviewItem({
    required this.questionId,
    this.questionText,
    this.givenAnswer,
    this.isCorrect,
    this.isSkipped = false,
    this.verdict,
    this.scoreAwarded,
    this.timeTakenSeconds,
    this.explanation,
  });

  final int questionId;
  final String? questionText;
  final String? givenAnswer;
  final bool? isCorrect;
  final bool isSkipped;
  final String? verdict;
  final double? scoreAwarded;
  final int? timeTakenSeconds;
  final String? explanation;
}

class AttemptReview {
  const AttemptReview({
    required this.attemptId,
    required this.status,
    required this.policy,
    required this.items,
  });

  final int attemptId;
  final String status;
  final ReviewPolicy policy;
  final List<AttemptReviewItem> items;
}
