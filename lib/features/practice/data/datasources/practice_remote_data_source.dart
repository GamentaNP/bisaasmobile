// ignore_for_file: use_null_aware_elements
import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/envelope.dart';
import '../../../../core/network/pagination.dart';
import '../models/practice_dto.dart';

/// Practice data source — verified server routes in C:\laragon\www\bisaas:
/// - GET  /quiz/bookmarks (cursor) + PUT /quiz/bookmarks/{question} (add)
///   + DELETE /quiz/bookmarks/{question} (remove)
/// - GET  /quiz/attempts/history (cursor — §4.1 migration)
/// - GET  /quiz/questions (cursor, filtered)
/// - POST /quiz/attempts (mode=practice, question_ids)
/// - POST /quiz/attempts/{attempt}/answers
/// - PUT  /quiz/attempts/{attempt}/completion
///
/// **The drill is a real server attempt.** The client loads the questions it
/// is going to show from `GET /quiz/questions`, then seeds a practice attempt
/// with exactly those ids (`question_ids`). The server therefore grades the
/// same questions the user saw, and the score comes back from
/// `PUT /quiz/attempts/{attempt}/completion`. Nothing is graded on-device and
/// no question is invented.
///
/// **Failures are never empty lists.** A transport error, a 5xx or a drifted
/// body throws so the UI can show an error and a retry. Only a genuinely empty
/// collection is an empty collection.
///
/// Follows Clean Arch: Dio via ApiConfig.baseUrl (no double /api/v1), envelope
/// tolerant, Idempotency-Key per POST (never global), Accept: application/json
/// already in Dio defaults.
class PracticeRemoteDataSource {
  const PracticeRemoteDataSource(this._dio);
  final Dio _dio;

  // ── Bookmarks (cursor paginated) ────────────────────────────────────────────

  Future<Page<BookmarkedQuestionDto>> getBookmarks({
    String? cursor,
    int perPage = 20,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/quiz/bookmarks',
      queryParameters: cursorQuery(cursor: cursor, perPage: perPage),
    );
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty bookmarks response',
        endpoint: '/quiz/bookmarks',
      );
    }
    return parsePage<BookmarkedQuestionDto>(
      body,
      BookmarkedQuestionDto.fromJson,
      endpoint: '/quiz/bookmarks',
    );
  }

  /// Adds a bookmark.
  ///
  /// `PUT /quiz/bookmarks/{question}` is the canonical add. The `POST` spelling
  /// is the transition alias and **converges to `bookmarked: true`** — it is
  /// not a toggle, which is why removing a bookmark used to be impossible from
  /// the client.
  Future<bool> addBookmark(int questionId, {String? idempotencyKey}) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/quiz/bookmarks/$questionId',
      data: {},
      options: Options(headers: idempotencyHeader(idempotencyKey)),
    );
    final body = res.data;
    if (body == null) return false;
    if (body['success'] == true) return true;
    final data = body['data'];
    if (data is Map<String, dynamic> && data['bookmarked'] == true) return true;
    return false;
  }

  /// Removes a bookmark. Idempotent: removing a bookmark that is not there is
  /// a success, not an error.
  Future<bool> removeBookmark(int questionId) async {
    final res = await _dio.delete<Map<String, dynamic>>(
      '/quiz/bookmarks/$questionId',
    );
    final body = res.data;
    if (body == null) return false;
    if (body['success'] == true) return true;
    final data = body['data'];
    if (data is Map<String, dynamic> && data['bookmarked'] == false) return true;
    return false;
  }

  /// Adds or removes a bookmark depending on [bookmarked].
  Future<bool> setBookmark(
    int questionId, {
    required bool bookmarked,
    String? idempotencyKey,
  }) {
    return bookmarked
        ? addBookmark(questionId, idempotencyKey: idempotencyKey)
        : removeBookmark(questionId);
  }

  // ── Attempt history (cursor paginated) ─────────────────────────────────────

  /// `GET /quiz/attempts/history` is one of the four collections that moved to
  /// the cursor shape (`MOBILE_API_INTEGRATION_GUIDE.md` §4.1). Sending
  /// `?page=2` to it returns page one forever, so this never sends `page`.
  Future<Page<PracticeAttemptHistoryDto>> getAttemptHistory({
    String? cursor,
    int perPage = 20,
  }) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/quiz/attempts/history',
      queryParameters: cursorQuery(cursor: cursor, perPage: perPage),
    );
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty attempt history response',
        endpoint: '/quiz/attempts/history',
      );
    }
    return parsePage<PracticeAttemptHistoryDto>(
      body,
      PracticeAttemptHistoryDto.fromJson,
      endpoint: '/quiz/attempts/history',
    );
  }

  // ── Questions for a drill ───────────────────────────────────────────────────

  /// Loads real server questions for a drill.
  ///
  /// Only the filters the server actually honours are sent
  /// (`QuizQuestionApiController::$allowedFilters`): `course_id`,
  /// `category_id`, `difficulty` and `search`. A `topic_id` filter is *not*
  /// supported by this endpoint — it was silently ignored — so a topic drill is
  /// expressed as a text `search` over the topic name, which the server does
  /// honour.
  ///
  /// The endpoint is cursor-paginated; the walk stops at [limit] questions.
  Future<List<PracticeQuestionDto>> getQuestions({
    int? courseId,
    int? categoryId,
    String? difficulty,
    String? search,
    int limit = 20,
    int perPage = 50,
  }) async {
    final collected = <Map<String, dynamic>>[];
    String? cursor;

    while (collected.length < limit) {
      final res = await _dio.get<Map<String, dynamic>>(
        '/quiz/questions',
        queryParameters: cursorQuery(
          cursor: cursor,
          perPage: perPage,
          extra: {
            if (courseId != null) 'course_id': courseId,
            if (categoryId != null) 'category_id': categoryId,
            if (difficulty != null && difficulty.isNotEmpty) 'difficulty': difficulty,
            if (search != null && search.isNotEmpty) 'search': search,
          },
        ),
      );
      final body = res.data;
      if (body == null) {
        throw const ContractViolation(
          'Empty questions response',
          endpoint: '/quiz/questions',
        );
      }

      final page = parsePage<Map<String, dynamic>>(
        body,
        (row) => row,
        endpoint: '/quiz/questions',
      );
      collected.addAll(page.items);
      if (!page.hasMore || page.items.isEmpty) break;

      final next = page.nextCursor;
      if (next == null || next.isEmpty) break;
      cursor = next;
    }

    if (collected.length > limit) {
      return collected
          .sublist(0, limit)
          .map(PracticeQuestionDto.fromJson)
          .toList();
    }
    return collected.map(PracticeQuestionDto.fromJson).toList();
  }

  // ── The drill attempt ───────────────────────────────────────────────────────

  /// Starts the practice attempt that backs a drill.
  ///
  /// `question_ids` is the only seeding mode used here: the server grades
  /// exactly the ids sent, so the questions the user sees are the questions
  /// that get graded. `question_ids` is mutually exclusive with
  /// `topic_id` / `course_id` / `category_id` (`StartAttemptRequest`), so only
  /// one of them is ever sent.
  Future<PracticeStartDto> startPracticeAttempt({
    required List<int> questionIds,
    String? idempotencyKey,
  }) async {
    if (questionIds.isEmpty) {
      throw const ContractViolation(
        'A practice attempt needs at least one question id',
        endpoint: '/quiz/attempts',
      );
    }

    final res = await _dio.post<Map<String, dynamic>>(
      // Canonical resource form; `/quiz/attempts/start` is the transition
      // alias (routes/api/v1/quiz.php:178-181).
      '/quiz/attempts',
      data: <String, dynamic>{
        'mode': 'practice',
        'question_ids': questionIds,
      },
      options: Options(headers: idempotencyHeader(idempotencyKey)),
    );
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty start-attempt response',
        endpoint: '/quiz/attempts',
      );
    }
    final data = requireDataMap(body, endpoint: '/quiz/attempts');
    return PracticeStartDto.fromJson(data);
  }

  /// Submits one answer to the drill attempt.
  ///
  /// `time_taken_seconds` is the integrity engine's timing evidence, so it is
  /// measured per question and sent on every answer
  /// (`MOBILE_API_INTEGRATION_GUIDE.md` §7).
  Future<void> submitAnswer({
    required String attemptId,
    required int questionId,
    required String answer,
    int? timeTakenSeconds,
    String? idempotencyKey,
  }) async {
    await _dio.post<Map<String, dynamic>>(
      '/quiz/attempts/$attemptId/answers',
      data: <String, dynamic>{
        'question_id': questionId,
        'answer': answer,
        if (timeTakenSeconds != null) 'time_taken_seconds': timeTakenSeconds,
      },
      options: Options(headers: idempotencyHeader(idempotencyKey)),
    );
  }

  /// Completes the drill and returns the server's own verdict.
  ///
  /// Idempotency-Key is mandatory on completion — the server answers
  /// `422 IDEMPOTENCY_KEY_REQUIRED` without it.
  Future<PracticeResultDto> completeAttempt({
    required String attemptId,
    String? idempotencyKey,
  }) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/quiz/attempts/$attemptId/completion',
      options: Options(headers: idempotencyHeader(idempotencyKey)),
    );
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty completion response',
        endpoint: '/quiz/attempts/{attempt}/completion',
      );
    }
    final data = requireDataMap(
      body,
      endpoint: '/quiz/attempts/{attempt}/completion',
    );
    return PracticeResultDto.fromJson(data);
  }
}
