import '../../../../core/network/pagination.dart';
import '../../../../shared/domain/paginated.dart';

import '../entities/practice.dart';

abstract class PracticeRepository {
  // Bookmarks (cursor paginated)
  Future<Paginated<BookmarkedQuestion>> getBookmarks({
    String? cursor,
    int perPage = 20,
  });

  /// Adds a bookmark. `PUT /quiz/bookmarks/{question}` — the canonical form.
  Future<bool> addBookmark(int questionId, {String? idempotencyKey});

  /// Removes a bookmark. `DELETE /quiz/bookmarks/{question}`.
  ///
  /// Separate from [addBookmark] on purpose: the `POST` alias converges to
  /// `bookmarked: true` rather than toggling, so one method cannot serve both
  /// directions.
  Future<bool> removeBookmark(int questionId);

  // History (cursor paginated — §4.1 migration)
  Future<Paginated<PracticeAttemptHistoryItem>> getAttemptHistory({
    String? cursor,
    int perPage = 20,
  });

  /// Real server questions for a drill.
  ///
  /// The server honours `course_id`, `category_id`, `difficulty` and `search`
  /// on `GET /quiz/questions`; there is no `topic_id` filter, so a topic drill
  /// is a text `search` over the topic name.
  Future<List<PracticeQuestion>> getQuestions({
    int? courseId,
    int? categoryId,
    String? difficulty,
    String? search,
    int limit = 20,
  });

  /// Starts the practice attempt that backs a drill, seeded with exactly the
  /// questions the client is going to show.
  Future<PracticeDrill> startDrill({
    required String title,
    int? courseId,
    int? categoryId,
    String? difficulty,
    String? search,
    int count,
    String? idempotencyKey,
  });

  /// Starts a drill over the user's **own bookmarks**.
  ///
  /// The bookmarks endpoint publishes the question text but not the answer
  /// options, so the implementation asks the server for the same questions
  /// again (by their category, or by their text when the bookmark has no
  /// category) and seeds the attempt with the bookmarked ids. The server
  /// therefore grades the questions the user actually bookmarked.
  Future<PracticeDrill> startBookmarkDrill({
    required String title,
    required List<BookmarkedQuestion> bookmarks,
    String? idempotencyKey,
  });


  /// Submits one answer to the drill attempt.
  Future<void> submitAnswer({
    required String attemptId,
    required int questionId,
    required String answer,
    int? timeTakenSeconds,
    String? idempotencyKey,
  });

  /// Completes the drill and returns the server's verdict.
  Future<PracticeResult> completeAttempt({
    required String attemptId,
    String? idempotencyKey,
  });
}

/// Re-exported so callers do not need to import the network layer for the
/// page type.
typedef PracticePage<T> = Page<T>;
