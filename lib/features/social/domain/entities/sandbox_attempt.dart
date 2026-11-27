/// Pure Dart view of the authenticated `GET /social/sandbox/attempts/{attempt}`
/// result read (§9.5).
///
/// The server never emits `correct_answer`, the share token, the session hash,
/// `guest_session_id` or attribution dimensions. This entity mirrors that: it
/// holds only the verdict fields the learner is allowed to see. There is no
/// local grading — `isCorrect` is the server's verdict.
library;

class SandboxAttemptResults {
  const SandboxAttemptResults({
    required this.summary,
    required this.items,
  });

  final SandboxScoreSummary summary;
  final List<SandboxAttemptItem> items;
}

class SandboxScoreSummary {
  const SandboxScoreSummary({
    required this.score,
    required this.correct,
    required this.wrong,
    required this.skipped,
    required this.total,
  });

  final double score;
  final int correct;
  final int wrong;
  final int skipped;
  final int total;
}

class SandboxAttemptItem {
  const SandboxAttemptItem({
    required this.questionId,
    required this.questionText,
    required this.isSkipped,
    this.type,
    this.options = const <Object?>[],
    this.givenAnswer,
    this.isCorrect,
    this.explanation,
  });

  final int questionId;
  final String questionText;
  final bool isSkipped;
  final String? type;
  final List<Object?> options;
  final Object? givenAnswer;
  final bool? isCorrect;
  final String? explanation;
}
