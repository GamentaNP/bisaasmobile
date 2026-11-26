/// Pure-Dart views of the quiz catalog and review endpoints.
///
/// The wire shapes are parsed by DTOs in `data/models`. The two `fromJson`
/// factories on the catalog rows are kept as a compatibility shim for the
/// intro screen, which builds a fallback row from local data; every network
/// path goes through the DTO + repository instead.
class QuizCourseEntry {
  const QuizCourseEntry({
    required this.id,
    required this.title,
    required this.description,
  });

  final String id;
  final String title;
  final String description;

  factory QuizCourseEntry.fromJson(Map<String, dynamic> j) => QuizCourseEntry(
        id: (j['id'] ?? '').toString(),
        title: (j['name'] ?? j['title'] ?? 'Course').toString(),
        description: (j['description'] ?? '').toString(),
      );
}

class QuizCategoryEntry {
  const QuizCategoryEntry({
    required this.id,
    required this.name,
  });

  final String id;
  final String name;

  factory QuizCategoryEntry.fromJson(Map<String, dynamic> j) =>
      QuizCategoryEntry(
        id: (j['id'] ?? '').toString(),
        name: (j['name'] ?? j['slug'] ?? 'Topic').toString(),
      );
}

/// A lower-bound question count from one cursor page.
///
/// The questions collections publish no `total`, only `has_more`, so [rows]
/// is what one page held and [isLowerBound] says more rows exist beyond it.
class QuestionCount {
  const QuestionCount({required this.rows, required this.isLowerBound});

  final int rows;
  final bool isLowerBound;
}

/// One server-graded answer row from `GET /quiz/attempts/{id}/results`.
class AttemptReviewEntry {
  const AttemptReviewEntry({
    required this.body,
    this.userOptionId,
    this.correctOptionId,
    this.userOptionText,
    this.correctOptionText,
    this.explanation,
    this.explanationSource,
    this.difficulty,
    this.isCorrect,
    this.isSkipped,
  });

  final String body;
  final String? userOptionId;
  final String? correctOptionId;
  final String? userOptionText;
  final String? correctOptionText;
  final String? explanation;

  /// "base" or "translation" when the server publishes provenance; null when
  /// it does not. Never fabricated on-device.
  final String? explanationSource;
  final int? difficulty;
  final bool? isCorrect;
  final bool? isSkipped;
}

class AttemptReview {
  const AttemptReview(this.entries);

  final List<AttemptReviewEntry> entries;
}
