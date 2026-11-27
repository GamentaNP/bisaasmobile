/// Pure Dart models for the cursor-paged `GET /quiz/word-bank` catalog.
///
/// `mastery` is copied verbatim from the server. The client never derives it
/// from `items[]` — the server computes it from per-user progress.
library;

class WordBankCourse {
  const WordBankCourse({required this.id, required this.name, this.slug});

  final int id;
  final String name;
  final String? slug;
}

class WordBankEntry {
  const WordBankEntry({
    required this.id,
    required this.term,
    required this.definition,
    this.example,
    this.difficulty = 'medium',
    this.tags = const <String>[],
    this.courseName,
    this.topicName,
    this.mastery,
  });

  final int id;
  final String term;
  final String definition;
  final String? example;
  final String difficulty;
  final List<String> tags;
  final String? courseName;
  final String? topicName;

  /// Server-computed mastery, or null when the server does not publish it.
  final num? mastery;
}

class WordBankCatalogPage {
  const WordBankCatalogPage({
    required this.items,
    required this.filters,
    required this.allTags,
    required this.allCourses,
    required this.allDifficulties,
    this.nextCursor,
    this.hasMore = false,
  });

  final List<WordBankEntry> items;
  final Map<String, dynamic> filters;
  final List<String> allTags;
  final List<WordBankCourse> allCourses;
  final List<String> allDifficulties;
  final String? nextCursor;
  final bool hasMore;
}
