import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/api_response.dart';
import '../../../../core/network/dio_client.dart';
import '../../domain/entities/content_quiz.dart';

final contentQuizRemoteDataSourceProvider = Provider<ContentQuizRemoteDataSource>(
  (ref) => ContentQuizRemoteDataSource(DioClient.instance.dio),
);

/// Tests-from-content, verified against `routes/api/v1/content-quizzes.php`:
/// - POST /books/content-quizzes                                  **Idempotency-Key**
/// - GET  /books/content-quizzes/{id}
/// - GET  /books/{slug}/chapters/{chapter}/recommended-test
///
/// The create call is the only one that needs a key, and `scope` determines
/// which id is required, enforced server-side with `required_if`.
class ContentQuizRemoteDataSource {
  const ContentQuizRemoteDataSource(this._dio);
  final Dio _dio;

  static const _uuid = Uuid();

  Map<String, dynamic>? _data(Map<String, dynamic>? body) {
    if (body == null) return null;
    final envelope = ApiResponse.fromJson(body, (json) => json);
    final data = envelope.data;
    if (data is Map<String, dynamic>) return data;
    if (body['data'] is Map<String, dynamic>) return body['data'] as Map<String, dynamic>;
    return null;
  }


  ContentQuiz? _parse(Map<String, dynamic> json) {
    final id = json['id'];
    if (id is! int) return null;
    return ContentQuiz(
      id: id,
      scope: ContentQuizScope.byName(json['scope'] as String?),
      questionCount: (json['question_count'] is num)
          ? (json['question_count'] as num).toInt()
          : 0,
      generationStatus: GenerationStatus.byName(json['generation_status'] as String?),
      trigger: json['trigger'] as String?,
      bookId: json['book_id'] is int ? json['book_id'] as int : null,
      chapterId:
          json['book_chapter_id'] is int ? json['book_chapter_id'] as int : null,
      topicId: json['book_topic_id'] is int ? json['book_topic_id'] as int : null,
      questionIds: [
        for (final q in (json['question_ids'] as List? ?? const []))
          if (q is int) q,
      ],
    );
  }

  /// Asks the server to generate a test for a scope.
  ///
  /// The response is a **pending** quiz, not questions: generation happens
  /// server-side, so the client must not imply the test is ready to take. It is
  /// also not created if the scope is malformed, because the server validates it
  /// with `required_if`.
  Future<ContentQuiz?> create({
    required ContentQuizScope scope,
    int? topicId,
    int? chapterId,
    int? bookId,
    List<int>? syllabusNodeIds,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/books/content-quizzes',
      data: {
        'scope': scope.wireValue,
        if (scope == ContentQuizScope.topic) 'book_topic_id': topicId,
        if (scope == ContentQuizScope.chapter) 'book_chapter_id': chapterId,
        if (scope == ContentQuizScope.book) 'book_id': bookId,
        if (syllabusNodeIds != null && syllabusNodeIds.isNotEmpty)
          'syllabus_node_ids': syllabusNodeIds,
      },
      options: Options(headers: {'Idempotency-Key': _uuid.v4()}),
    );
    final data = _data(res.data);
    return data == null ? null : _parse(data);
  }

  Future<ContentQuiz?> get(int id) async {
    final res = await _dio.get<Map<String, dynamic>>('/books/content-quizzes/$id');
    final data = _data(res.data);
    return data == null ? null : _parse(data);
  }

  /// The recommended test for a chapter, if one exists. Null is a normal answer
  /// — not every chapter has one.
  Future<ContentQuiz?> getRecommended(String slug, int chapterId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/books/$slug/chapters/$chapterId/recommended-test',
    );
    final data = _data(res.data);
    if (data == null) return null;
    return _parse(data);
  }
}
