import 'package:dio/dio.dart';

import '../../../../core/network/api_response.dart';

/// Verified server routes (`routes/api/v1/quiz.php:546-558` — Firebase
/// Multiplayer Battles):
/// - GET  /quiz/firebase-token                      → custom token for RTDB auth
/// - POST /quiz/battles                             → create/find open battle
///                                                      ({category_id required,
///                                                       total_questions 5..20})
/// - PUT  /quiz/battles/{id}/participation          → join an open battle
/// - PUT  /quiz/battles/{id}/answer                → {question_id, question_index,
///                                                      selected_option 1..4,
///                                                      time_taken_ms}
/// - PUT  /quiz/battles/{id}/completion             → force-finish (HOST ONLY)
/// - GET  /quiz/battles/{id}/results                → final results
/// - GET  /quiz/battles/history                     → battle history
///
/// **Canonical spellings are used deliberately.** The server registers the
/// §4.3 state transitions as PUT and keeps the POST forms only as
/// `*.transition-alias` pending a freeze. Only create and answer were wired
/// before, so a battle could be started and answered but never joined, ended or
/// read back — the result screen had to invent the outcome.
///
/// RTDB subscription is read-only on /battles/{lobbyId} (see
/// docs/mobileapp/RTDB_BATTLE_SCHEMA.md). Dio baseUrl already ends with /api/v1.
class BattleRemoteDataSource {
  const BattleRemoteDataSource(this._dio);
  final Dio _dio;

  /// `data` out of the envelope, tolerating a raw body.
  Map<String, dynamic> _dataOrEmpty(Map<String, dynamic>? body) {
    if (body == null) return const {};
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    try {
      return ApiResponse.fromJson(body, (j) => j as Map<String, dynamic>?).data ?? const {};
    } catch (_) {
      return const {};
    }
  }

  Future<Map<String, dynamic>> getFirebaseToken() async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/firebase-token');
    final envelope = ApiResponse.fromJson(
      res.data!,
      (json) => json as Map<String, dynamic>?,
    );
    final data = envelope.data ?? res.data!['data'] as Map<String, dynamic>? ?? res.data!;
    return Map<String, dynamic>.from(data as Map);
  }

  /// Create or find an open battle. The server requires a `category_id`
  /// (quiz_categories.id); when [categoryId] is null a default is resolved
  /// from the first course's first category.
  Future<Map<String, dynamic>> findMatch({int? categoryId, int totalQuestions = 10}) async {
    final resolved = categoryId ?? await _defaultCategoryId();
    final res = await _dio.post<Map<String, dynamic>>(
      '/quiz/battles',
      data: {'category_id': resolved, 'total_questions': totalQuestions},
    );
    final envelope = ApiResponse.fromJson(
      res.data!,
      (json) => json as Map<String, dynamic>?,
    );
    final data = envelope.data ?? res.data!['data'] as Map<String, dynamic>? ?? {'id': 'demo', 'status': 'searching'};
    return Map<String, dynamic>.from(data as Map);
  }

  Future<int> _defaultCategoryId() async {
    final coursesRes = await _dio.get<Map<String, dynamic>>('/quiz/courses');
    final courses = _dataList(coursesRes.data);
    if (courses.isEmpty) {
      throw DioException(
        requestOptions: RequestOptions(path: '/quiz/courses'),
        type: DioExceptionType.connectionError,
        error: 'No courses available for battle category',
      );
    }
    final courseId = courses.first['id'];
    final catsRes = await _dio.get<Map<String, dynamic>>('/quiz/courses/$courseId/categories');
    final cats = _dataList(catsRes.data);
    if (cats.isEmpty) {
      throw DioException(
        requestOptions: RequestOptions(path: '/quiz/courses/$courseId/categories'),
        type: DioExceptionType.connectionError,
        error: 'No categories available for battle matchmaking',
      );
    }
    return int.parse(cats.first['id'].toString());
  }

  List<Map<String, dynamic>> _dataList(Map<String, dynamic>? body) {
    if (body == null) return const [];
    final data = body['data'];
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    if (data is Map<String, dynamic>) {
      final items = data['items'] ?? data['data'];
      if (items is List) return items.whereType<Map<String, dynamic>>().toList();
    }
    return const [];
  }

  Future<List<Map<String, dynamic>>> getLeaderboard(String id) async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/leaderboards/$id');
    final body = res.data!;
    if (body['data'] is List) return (body['data'] as List).cast<Map<String, dynamic>>();
    final envelope = ApiResponse.fromJson(body, (json) => (json as List?)?.cast<Map<String, dynamic>>() ?? []);
    return envelope.data ?? [];
  }

  /// Joins an open battle. No request body.
  ///
  /// Returns a fresh `firebase_token` for RTDB auth, so a join by the second
  /// player yields the credentials it needs without a second round-trip.
  /// 404 when the battle is no longer available — a normal outcome, since the
  /// lobby can fill while this request is in flight.
  Future<Map<String, dynamic>> join(String firebaseBattleId) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/quiz/battles/$firebaseBattleId/participation',
    );
    return _dataOrEmpty(res.data);
  }

  /// Ends the battle and syncs results server-side.
  ///
  /// **Host only** — `BattleController::end` returns 403 "Only the battle host
  /// can end the battle" for player 2, so the caller must not offer this to
  /// everyone. 409 when the battle is not `in_progress`.
  Future<Map<String, dynamic>> end(String firebaseBattleId) async {
    final res = await _dio.put<Map<String, dynamic>>(
      '/quiz/battles/$firebaseBattleId/completion',
    );
    return _dataOrEmpty(res.data);
  }

  /// Authoritative outcome. 403 for a user who is not a participant.
  Future<Map<String, dynamic>> getResults(String firebaseBattleId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/quiz/battles/$firebaseBattleId/results',
    );
    return _dataOrEmpty(res.data);
  }

  /// Completed battles for this user, newest first, with a `stats` block.
  Future<Map<String, dynamic>> getHistory() async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/battles/history');
    return _dataOrEmpty(res.data);
  }
}
