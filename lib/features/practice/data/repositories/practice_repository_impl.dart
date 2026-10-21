import '../../../../shared/domain/paginated.dart';

import '../../domain/entities/practice.dart';
import '../../domain/repositories/practice_repository.dart';
import '../datasources/practice_remote_data_source.dart';

class PracticeRepositoryImpl implements PracticeRepository {
  const PracticeRepositoryImpl(this._remote);
  final PracticeRemoteDataSource _remote;

  @override
  Future<Paginated<BookmarkedQuestion>> getBookmarks({
    String? cursor,
    int perPage = 20,
  }) async {
    final res = await _remote.getBookmarks(cursor: cursor, perPage: perPage);
    return Paginated<BookmarkedQuestion>(
      items: res.items.map((d) => d.toDomain()).toList(),
      pagination: res.pagination,
    );
  }

  @override
  Future<bool> addBookmark(int questionId, {String? idempotencyKey}) =>
      _remote.addBookmark(questionId, idempotencyKey: idempotencyKey);

  @override
  Future<bool> removeBookmark(int questionId) =>
      _remote.removeBookmark(questionId);

  @override
  Future<Paginated<PracticeAttemptHistoryItem>> getAttemptHistory({
    String? cursor,
    int perPage = 20,
  }) async {
    final res = await _remote.getAttemptHistory(cursor: cursor, perPage: perPage);
    return Paginated<PracticeAttemptHistoryItem>(
      items: res.items.map((d) => d.toDomain()).toList(),
      pagination: res.pagination,
    );
  }

  @override
  Future<List<PracticeQuestion>> getQuestions({
    int? courseId,
    int? categoryId,
    String? difficulty,
    String? search,
    int limit = 20,
  }) async {
    final dtos = await _remote.getQuestions(
      courseId: courseId,
      categoryId: categoryId,
      difficulty: difficulty,
      search: search,
      limit: limit,
    );
    return dtos.map((d) => d.toDomain()).toList();
  }

  @override
  Future<PracticeDrill> startDrill({
    required String title,
    int? courseId,
    int? categoryId,
    String? difficulty,
    String? search,
    int count = 10,
    String? idempotencyKey,
  }) async {
    // 1. Load the real questions the drill is going to show.
    final questions = await getQuestions(
      courseId: courseId,
      categoryId: categoryId,
      difficulty: difficulty,
      search: search,
      limit: count,
    );
    if (questions.isEmpty) {
      throw const PracticeDrillException(
        'No questions are available for this drill on the server yet.',
      );
    }

    // 2. Seed a practice attempt with exactly those ids, so the server grades
    //    the questions the user actually saw.
    final start = await _remote.startPracticeAttempt(
      questionIds: questions.map((q) => q.id).toList(),
      idempotencyKey: idempotencyKey,
    );

    return PracticeDrill(
      attemptId: start.attemptId,
      title: title,
      questions: questions,
    );
  }

  @override
  Future<PracticeDrill> startBookmarkDrill({
    required String title,
    required List<BookmarkedQuestion> bookmarks,
    String? idempotencyKey,
  }) async {
    if (bookmarks.isEmpty) {
      throw const PracticeDrillException('There are no bookmarks to drill.');
    }

    // The bookmarks endpoint publishes the question *text* but not its answer
    // options, so a bookmark cannot be rendered as a drill on its own. What
    // the server CAN do is hand out the same questions again — with their
    // options — when asked for the category they belong to.
    //
    // So the drill is built from the **bookmarked question ids**: for each
    // category the bookmarks span, the category's questions are fetched (they
    // carry the options) and the bookmarked ids are picked back out of them.
    // The attempt is then seeded with those exact ids, so the server grades
    // the questions the user actually bookmarked — not a random set from the
    // same category.
    final wanted = <int, BookmarkedQuestion>{
      for (final b in bookmarks) b.question.id: b,
    };

    final byCategory = <int?, List<int>>{};
    for (final id in wanted.keys) {
      final category = wanted[id]!.question.categoryId;
      byCategory.putIfAbsent(category, () => <int>[]).add(id);
    }

    final resolved = <int, PracticeQuestion>{};

    for (final entry in byCategory.entries) {
      final categoryId = entry.key;
      final ids = entry.value;

      final candidates = categoryId == null
          ? // A bookmark with no category cannot be looked up by category, so
            // the question text is used as the server's own search instead.
            await _findByText(wanted, ids)
          : await getQuestions(categoryId: categoryId, limit: 200);

      for (final candidate in candidates) {
        if (ids.contains(candidate.id)) resolved[candidate.id] = candidate;
      }
    }

    if (resolved.isEmpty) {
      throw const PracticeDrillException(
        'The server does not publish the answer options for these bookmarks '
        'yet, so they cannot be drilled. Tap a bookmark to read it instead.',
      );
    }

    // Keep the server's order, not the bookmark list's, so the drill reads
    // like a quiz.
    final questions = resolved.values.toList();
    final start = await _remote.startPracticeAttempt(
      questionIds: questions.map((q) => q.id).toList(),
      idempotencyKey: idempotencyKey,
    );

    final undrillable = wanted.keys.toSet().difference(resolved.keys.toSet());

    return PracticeDrill(
      attemptId: start.attemptId,
      title: title,
      questions: questions,
      undrillableCount: undrillable.length,
    );
  }

  /// Looks up uncategorised bookmarks by their question text.
  ///
  /// `GET /quiz/questions?search=` matches on `question_text`, which is the
  /// one field the bookmarks endpoint does publish.
  Future<List<PracticeQuestion>> _findByText(
    Map<int, BookmarkedQuestion> wanted,
    List<int> ids,
  ) async {
    final found = <PracticeQuestion>[];
    for (final id in ids) {
      final text = wanted[id]!.question.questionText.trim();
      if (text.isEmpty) continue;
      // The search is a prefix match on the server; the first 60 characters
      // are enough to identify the question without over-constraining it.
      final probe = text.length > 60 ? text.substring(0, 60) : text;
      final matches = await getQuestions(search: probe, limit: 5);
      for (final match in matches) {
        if (match.id == id) {
          found.add(match);
          break;
        }
      }
    }
    return found;
  }

  @override
  Future<void> submitAnswer({
    required String attemptId,
    required int questionId,
    required String answer,
    int? timeTakenSeconds,
    String? idempotencyKey,
  }) =>
      _remote.submitAnswer(
        attemptId: attemptId,
        questionId: questionId,
        answer: answer,
        timeTakenSeconds: timeTakenSeconds,
        idempotencyKey: idempotencyKey,
      );

  @override
  Future<PracticeResult> completeAttempt({
    required String attemptId,
    String? idempotencyKey,
  }) async {
    final dto = await _remote.completeAttempt(
      attemptId: attemptId,
      idempotencyKey: idempotencyKey,
    );
    return dto.toDomain();
  }
}
