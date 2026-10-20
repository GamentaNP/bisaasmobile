import '../domain/entities/practice.dart';

/// The payload handed to `/practice/session`.
///
/// [attemptId] is the live server attempt when there is one. An empty string
/// means "review only" — there is no attempt, so nothing is submitted and no
/// score is claimed.
class PracticeSessionArgs {
  const PracticeSessionArgs({
    required this.title,
    required this.questions,
    this.attemptId = '',
    this.isTimed = false,
    this.timeLimitSeconds,
  });

  /// Builds the args from a live drill.
  factory PracticeSessionArgs.fromDrill(PracticeDrill drill) => PracticeSessionArgs(
        title: drill.title,
        questions: drill.questions,
        attemptId: drill.attemptId,
      );

  final String title;
  final List<PracticeQuestion> questions;

  /// The server attempt this drill is graded against. Empty for review-only.
  final String attemptId;
  final bool isTimed;
  final int? timeLimitSeconds;
}
