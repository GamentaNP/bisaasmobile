import 'package:bisaasmobile/shared/domain/paginated.dart';

import '../entities/practice.dart';

abstract class PracticeRepository {
  // Bookmarks (cursor paginated)
  Future<Paginated<BookmarkedQuestion>> getBookmarks({String? cursor, int perPage = 20});
  Future<bool> toggleBookmark(int questionId, {String? idempotencyKey});
  Future<bool> addBookmark(int questionId, {String? idempotencyKey});
  Future<bool> removeBookmark(int questionId);

  // History (offset paginated via Paginated wrapper)
  Future<Paginated<PracticeAttemptHistoryItem>> getAttemptHistory({int page = 1, int perPage = 20});

  // Drill questions
  Future<List<PracticeQuestion>> getQuestions({
    int? topicId,
    int? categoryId,
    int? courseId,
    String? difficulty,
    String? query,
    int page = 1,
    int perPage = 20,
  });

  // Start server practice attempt
  Future<String> startPracticeAttempt({
    List<int>? questionIds,
    int? topicId,
    int? categoryId,
    int? courseId,
    int questionCount = 10,
    String? idempotencyKey,
  });
}
