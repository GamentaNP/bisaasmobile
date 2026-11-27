/// Pure Dart models for `POST /quiz/questions/{question}/reports`.
///
/// The server owns moderation: it validates the reason, the 20–4000 character
/// description and the optional correction, de-duplicates repeated reports and
/// returns the stored row. The client sends only those wire fields and shows a
/// success state only when the server actually accepted the write.
library;

/// The frozen `QuestionReportCategory` enum on the server.
///
/// These are wire values, never display copy — the labels come from the ARB.
abstract final class QuestionReportCategory {
  static const String incorrectAnswer = 'incorrect_answer';
  static const String unclearQuestion = 'unclear_question';
  static const String typoGrammar = 'typo_grammar';
  static const String inappropriate = 'inappropriate';
  static const String duplicate = 'duplicate';
  static const String outdated = 'outdated';
  static const String other = 'other';

  static const List<String> values = <String>[
    incorrectAnswer,
    unclearQuestion,
    typoGrammar,
    inappropriate,
    duplicate,
    outdated,
    other,
  ];

  static bool isValid(String value) => values.contains(value);

  /// The minimum the server enforces on `description`.
  static const int minDescriptionLength = 20;

  /// The maximum the server enforces on both free-text fields.
  static const int maxLength = 4000;
}

/// One user intent. Its stable identity is also the retry key's identity:
/// changing the reason or the text is a different logical report.
class QuestionReportSubmission {
  const QuestionReportSubmission({
    required this.questionId,
    required this.category,
    required this.description,
    this.suggestedCorrection,
  });

  final int questionId;
  final String category;
  final String description;
  final String? suggestedCorrection;

  String get intent =>
      '$questionId:$category:$description:${suggestedCorrection ?? ''}';
}

/// The server's conclusion — never inferred from a sent request.
class QuestionReportResult {
  const QuestionReportResult({
    required this.reportId,
    required this.status,
    required this.category,
    required this.duplicate,
    required this.canonicalReportId,
    required this.duplicateCount,
  });

  final int reportId;
  final String status;
  final String category;
  final bool duplicate;
  final int canonicalReportId;
  final int duplicateCount;
}
