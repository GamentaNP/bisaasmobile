/// One question hit from `GET /quiz/questions?search=...`.
///
/// The server owns the row shape. The getters below are the fields the search
/// screen already read from the raw map; keeping them here means presentation
/// no longer reaches into wire JSON, without changing what any row means.
library;

class SearchHit {
  const SearchHit(this.raw);

  final Map<String, dynamic> raw;

  String get title => (raw['body'] ?? raw['title'] ?? '').toString();

  String get subjectSlug => (raw['subject_slug'] ?? '').toString();

  /// Either slug can open a result; an empty one means the row is not routable.
  String get targetSlug =>
      (raw['quiz_slug'] ?? raw['course_slug'] ?? '').toString();

  bool get canOpen => targetSlug.isNotEmpty;
}
