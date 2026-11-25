/// PSC blueprint and exam-lifecycle read models.
///
/// These entities are thin handles over the server's own payload: the values
/// the screen needs are exposed as typed getters, and the `raw` field keeps
/// the whole payload available so nothing the server publishes is lost. No
/// exam state is computed here - starting and submitting are server decisions.
library;

class PscBlueprint {
  const PscBlueprint(this.raw);

  final Map<String, dynamic> raw;

  /// Numeric ids arrive as strings on some builds; a string is the common
  /// denominator for the route segment and for display.
  String get id => (raw['id'] ?? '').toString();

  String get title => (raw['title'] ?? raw['name'] ?? 'Blueprint') as String;

  String get questionCount =>
      (raw['question_count'] ?? raw['questions_count'] ?? '') as String;
}

class PscExam {
  const PscExam(this.raw);

  final Map<String, dynamic> raw;

  String get id => (raw['id'] ?? '').toString();
}

class PscSubmission {
  const PscSubmission(this.raw);

  final Map<String, dynamic> raw;
}
