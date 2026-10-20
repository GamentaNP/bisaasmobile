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
      throw StateError(
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
