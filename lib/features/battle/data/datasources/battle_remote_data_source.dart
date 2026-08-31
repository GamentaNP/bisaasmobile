import 'package:dio/dio.dart';

import '../../../../core/network/api_response.dart';

/// Verified server routes (`routes/api/v1/quiz.php` â€” Firebase Multiplayer Battles):
/// - GET  /quiz/firebase-token                â†’ custom token for RTDB auth
/// - POST /quiz/battles                       â†’ create/find open battle ({category_id required, total_questions 5..20})
/// - POST /quiz/battles/{id}/join             â†’ join an open battle
/// - POST /quiz/battles/{id}/answer           â†’ {question_id, question_index, selected_option 1..4, time_taken_ms}
/// - POST /quiz/battles/{id}/end              â†’ force-finish
/// - GET  /quiz/battles/{id}/results          â†’ final results
/// - GET  /quiz/battles/history               â†’ battle history
/// RTDB subscription is read-only on /battles/{lobbyId} (see docs/mobileapp/RTDB_BATTLE_SCHEMA.md).
/// Dio baseUrl already ends with /api/v1.
class BattleRemoteDataSource {
  const BattleRemoteDataSource(this._dio);
  final Dio _dio;

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
}
