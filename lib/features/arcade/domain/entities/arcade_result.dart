import 'package:meta/meta.dart';

/// The server's verdict on a finished run.
///
/// Every number here is read from the completion or results endpoint. The
/// client never derives a score, and `correct + wrong + skipped` can be less
/// than the questions issued — unanswered questions are the server's
/// `skipped_count`, not a client guess.
@immutable
class ArcadeResult {
  const ArcadeResult({
    required this.attemptId,
    required this.mode,
    required this.status,
    required this.score,
    required this.correctCount,
    required this.wrongCount,
    required this.skippedCount,
    this.completedAt,
  });

  final int attemptId;
  final String mode;
  final String status;
  final int score;
  final int correctCount;
  final int wrongCount;
  final int skippedCount;
  final DateTime? completedAt;

  int get answeredCount => correctCount + wrongCount;
  int get totalCount => correctCount + wrongCount + skippedCount;

  /// Share of the questions answered correctly, for the bar on the result
  /// screen. Zero questions is 0, never NaN.
  double get accuracy => totalCount == 0 ? 0 : correctCount / totalCount;
}
