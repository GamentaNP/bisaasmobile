import 'package:meta/meta.dart';

@immutable
class PracticeOption {
  const PracticeOption({required this.key, required this.text});

  /// The server's option key — "A", "B", … (uppercase, verified live).
  final String key;
  final String text;
}

@immutable
class PracticeQuestion {
  const PracticeQuestion({
    required this.id,
    required this.questionText,
    this.type,
    this.difficulty,
    this.points,
    this.categoryId,
    this.courseId,
    this.options = const [],
  });

  final int id;
  final String questionText;
  final String? type;

  /// "easy" | "medium" | "hard" | "expert" — the server's own label.
  final String? difficulty;
  final int? points;
  final int? categoryId;
  final int? courseId;

  /// The real choices from the server. Empty means the server sent none —
  /// which is a reason to say so, never a licence to render A/B/C/D.
  final List<PracticeOption> options;

  bool get hasOptions => options.isNotEmpty;
}

@immutable
class BookmarkedQuestion {
  const BookmarkedQuestion({
    required this.question,
    this.bookmarkedAt,
  });

  final PracticeQuestion question;
  final DateTime? bookmarkedAt;
}

@immutable
class PracticeAttemptHistoryItem {
  const PracticeAttemptHistoryItem({
    required this.id,
    required this.mode,
    required this.status,
    this.score,
    this.correctCount,
    this.wrongCount,
    this.skippedCount,
    this.questionCount,
    this.completedAt,
    this.createdAt,
  });

  final int id;
  final String mode;
  final String status;
  final int? score;
  final int? correctCount;
  final int? wrongCount;
  final int? skippedCount;
  final int? questionCount;
  final DateTime? completedAt;
  final DateTime? createdAt;

  bool get isCompleted => status == 'completed';
}

@immutable
class PracticeSessionConfig {
  const PracticeSessionConfig({
    required this.title,
    required this.questions,
    this.isTimed = false,
    this.timeLimitSeconds,
  });

  final String title;
  final List<PracticeQuestion> questions;
  final bool isTimed;
  final int? timeLimitSeconds;
}

/// A drill that is bound to a live server attempt.
///
/// Every drill the app runs is a real `QuizAttempt` in `mode: 'practice'`,
/// seeded with the exact question ids the client shows. The server grades it
/// and the client only renders what the server returns.
@immutable
class PracticeDrill {
  const PracticeDrill({
    required this.attemptId,
    required this.title,
    required this.questions,
  });

  /// The server attempt id. Every answer is submitted against it.
  final String attemptId;
  final String title;
  final List<PracticeQuestion> questions;

  int get length => questions.length;
}

/// The server's own verdict on a completed drill.
///
/// Never computed on-device: the client has no answer key, so it has no basis
/// for a score.
@immutable
class PracticeResult {
  const PracticeResult({
    required this.attemptId,
    this.score,
    this.correctCount = 0,
    this.wrongCount = 0,
    this.skippedCount = 0,
    this.completedAt,
  });

  final String attemptId;
  final int? score;
  final int correctCount;
  final int wrongCount;
  final int skippedCount;
  final DateTime? completedAt;

  int get answered => correctCount + wrongCount;
  int get total => correctCount + wrongCount + skippedCount;
}
