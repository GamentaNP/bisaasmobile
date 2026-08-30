import 'package:meta/meta.dart';

@immutable
class PracticeQuestion {
  const PracticeQuestion({
    required this.id,
    required this.questionText,
    this.type,
    this.difficulty,
    this.points,
    this.categoryId,
  });

  final int id;
  final String questionText;
  final String? type;
  final int? difficulty;
  final int? points;
  final int? categoryId;
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
