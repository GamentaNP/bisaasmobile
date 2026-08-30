// ignore_for_file: avoid_dynamic_calls, use_null_aware_elements
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/api_response.dart';
import '../models/practice_dto.dart';

/// Practice data source — verified server routes in C:\laragon\www\bisaas:
/// - GET /quiz/bookmarks (cursor) + POST /quiz/bookmarks/{question} (toggle) + PUT/DELETE variants
/// - GET /quiz/attempts/history (offset) — for practice history
/// - POST /quiz/attempts/start (with mode=practice, question_count, topic_id, etc.)
/// - GET /quiz/questions (filtered search for self-challenge / weak-topic drill)
///
/// Follows Clean Arch: Dio via ApiConfig.baseUrl (no double /api/v1), envelope tolerant,
/// Idempotency-Key per POST (never global), Accept: application/json already in Dio defaults.
class PracticeRemoteDataSource {
  const PracticeRemoteDataSource(this._dio);
  final Dio _dio;
  static const _uuid = Uuid();

  Map<String, String> _idempotencyHeader([String? key]) => {'Idempotency-Key': key ?? _uuid.v4()};

  // ── Bookmarks (cursor paginated) ────────────────────────────────────────────

  Future<({List<BookmarkedQuestionDto> items, Pagination? pagination})> getBookmarks({String? cursor, int perPage = 20}) async {
    final qp = <String, dynamic>{
      'per_page': perPage,
      if (cursor != null && cursor.isNotEmpty) 'cursor': cursor,
    };
    final res = await _dio.get<Map<String, dynamic>>('/quiz/bookmarks', queryParameters: qp);
    final body = res.data;
    if (body == null) return (items: <BookmarkedQuestionDto>[], pagination: null);

    Pagination? pagination;
    // cursor pagination is in meta or top-level pagination
    final pagRaw = body['pagination'] ?? body['meta'];
    if (pagRaw is Map<String, dynamic>) {
      pagination = Pagination.fromJson(pagRaw);
    }
    // Also read from envelope helper
    try {
      final env = ApiResponse.fromJson(body, (json) {
        if (json is List) return json.cast<Map<String, dynamic>>();
        return <Map<String, dynamic>>[];
      });
      pagination = env.pagination ?? pagination;
    } catch (_) {}

    var raw = <Map<String, dynamic>>[];
    final data = body['data'];
    if (data is List) {
      raw = data.cast<Map<String, dynamic>>();
    } else if (data is Map<String, dynamic> && data['items'] is List) {
      raw = (data['items'] as List).cast<Map<String, dynamic>>();
    } else {
      try {
        final env = ApiResponse.fromJson(body, (json) {
          if (json is List) return json.cast<Map<String, dynamic>>();
          if (json is Map<String, dynamic> && json['items'] is List) return (json['items'] as List).cast<Map<String, dynamic>>();
          return <Map<String, dynamic>>[];
        });
        raw = env.data ?? [];
        pagination = env.pagination ?? pagination;
      } catch (_) {}
    }

    final items = raw.map(BookmarkedQuestionDto.fromJson).toList();
    return (items: items, pagination: pagination);
  }

  Future<bool> toggleBookmark(int questionId, {String? idempotencyKey}) async {
    // POST toggle is deprecated but live; use POST with Idempotency-Key for safety
    final res = await _dio.post<Map<String, dynamic>>(
      '/quiz/bookmarks/$questionId',
      data: {},
      options: Options(headers: _idempotencyHeader(idempotencyKey)),
    );
    final body = res.data;
    if (body == null) return false;
    final data = body['data'];
    if (data is Map<String, dynamic> && data['bookmarked'] is bool) {
      return data['bookmarked'] as bool;
    }
    // fallback: success means toggled; if no field, assume true
    return body['success'] == true;
  }

  Future<bool> addBookmark(int questionId, {String? idempotencyKey}) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/quiz/bookmarks/$questionId',
      data: {},
      options: Options(headers: _idempotencyHeader(idempotencyKey)),
    );
    final body = res.data;
    if (body == null) return false;
    if (body['success'] == true) return true;
    final data = body['data'];
    if (data is Map && data['bookmarked'] == true) return true;
    return true;
  }

  Future<bool> removeBookmark(int questionId) async {
    final res = await _dio.delete<Map<String, dynamic>>('/quiz/bookmarks/$questionId');
    return res.data?['success'] == true;
  }

  // ── Attempt history (offset paginated) ─────────────────────────────────────

  Future<({List<PracticeAttemptHistoryDto> items, Pagination? pagination})> getAttemptHistory({int page = 1, int perPage = 20}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/quiz/attempts/history',
      queryParameters: {'page': page, 'per_page': perPage},
    );
    final body = res.data;
    if (body == null) return (items: <PracticeAttemptHistoryDto>[], pagination: null);

    Pagination? pagination;
    final pagRaw = body['pagination'];
    if (pagRaw is Map<String, dynamic>) pagination = Pagination.fromJson(pagRaw);

    var raw = <Map<String, dynamic>>[];
    final data = body['data'];
    if (data is List) {
      raw = data.cast<Map<String, dynamic>>();
    } else if (data is Map<String, dynamic> && data['items'] is List) {
      raw = (data['items'] as List).cast<Map<String, dynamic>>();
    } else {
      try {
        final env = ApiResponse.fromJson(body, (json) {
          if (json is List) return json.cast<Map<String, dynamic>>();
          if (json is Map<String, dynamic> && json['items'] is List) return (json['items'] as List).cast<Map<String, dynamic>>();
          return <Map<String, dynamic>>[];
        });
        raw = env.data ?? [];
        pagination = env.pagination ?? pagination;
      } catch (_) {}
    }

    return (items: raw.map(PracticeAttemptHistoryDto.fromJson).toList(), pagination: pagination);
  }

  // ── Questions for drill (filtered search) ──────────────────────────────────

  Future<List<PracticeQuestionDto>> getQuestions({
    int? topicId,
    int? categoryId,
    int? courseId,
    String? difficulty,
    String? query,
    int page = 1,
    int perPage = 20,
  }) async {
    final qp = <String, dynamic>{
      'page': page,
      'per_page': perPage,
      if (topicId != null) 'topic_id': topicId,
      if (categoryId != null) 'category_id': categoryId,
      if (courseId != null) 'course_id': courseId,
      if (difficulty != null) 'difficulty': difficulty,
      if (query != null && query.isNotEmpty) 'q': query,
    };
    final res = await _dio.get<Map<String, dynamic>>('/quiz/questions', queryParameters: qp);
    final body = res.data;
    if (body == null) return [];
    final data = body['data'];
    var raw = <Map<String, dynamic>>[];
    if (data is List) {
      raw = data.cast<Map<String, dynamic>>();
    } else if (data is Map<String, dynamic> && data['items'] is List) {
      raw = (data['items'] as List).cast<Map<String, dynamic>>();
    } else {
      try {
        final env = ApiResponse.fromJson(body, (json) {
          if (json is List) return json.cast<Map<String, dynamic>>();
          if (json is Map<String, dynamic> && json['items'] is List) return (json['items'] as List).cast<Map<String, dynamic>>();
          return <Map<String, dynamic>>[];
        });
        raw = env.data ?? [];
      } catch (_) {}
    }
    return raw.map(PracticeQuestionDto.fromJson).toList();
  }

  // ── Start practice attempt (server-graded but practice mode, no rank effect) ─

  Future<PracticeStartDto> startPracticeAttempt({
    List<int>? questionIds,
    int? topicId,
    int? categoryId,
    int? courseId,
    int questionCount = 10,
    String? idempotencyKey,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/quiz/attempts/start',
      data: {
        'mode': 'practice',
        if (questionIds != null && questionIds.isNotEmpty) 'question_ids': questionIds,
        if (topicId != null) 'topic_id': topicId,
        if (categoryId != null) 'category_id': categoryId,
        if (courseId != null) 'course_id': courseId,
        if (questionIds == null || questionIds.isEmpty) 'question_count': questionCount,
      },
      options: Options(headers: _idempotencyHeader(idempotencyKey)),
    );
    final body = res.data;
    if (body == null) throw Exception('Start practice attempt empty');
    Map<String, dynamic>? data;
    if (body['data'] is Map<String, dynamic>) {
      data = body['data'] as Map<String, dynamic>;
    } else {
      final env = ApiResponse.fromJson(body, (j) => j as Map<String, dynamic>?);
      data = env.data;
    }
    if (data == null) throw Exception('Start practice data missing');
    return PracticeStartDto.fromJson(data);
  }
}
