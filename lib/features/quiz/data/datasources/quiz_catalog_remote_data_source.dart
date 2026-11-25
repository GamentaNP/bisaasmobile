import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/envelope.dart';
import '../../../../core/network/pagination.dart';
import '../../domain/entities/quiz_catalog.dart';
import '../models/quiz_catalog_dto.dart';

/// Catalog, category and review reads for the browse/review screens.
///
/// These are the same verified routes the old screens called directly:
///  * `GET /quiz/courses`                          (public catalog)
///  * `GET /quiz/courses/{id}/categories`
///  * `GET /quiz/courses/{id}/questions`           (cursor, no `total`)
///  * `GET /quiz/attempts/{id}/results`
///
/// Every collection goes through [parsePage] / [extractRows]. The questions
/// route is cursor-paginated: [cursorQuery] builds its parameters and no
/// `page` is ever sent. [getQuestionPage] accepts the opaque `next_cursor` so
/// a caller that needs every row can walk the collection.
class QuizCatalogRemoteDataSource {
  const QuizCatalogRemoteDataSource(this._dio);

  final Dio _dio;

  static const _coursesEndpoint = '/quiz/courses';

  Future<List<QuizCourseEntry>> getCourses() async {
    final res = await _dio.get<Map<String, dynamic>>(_coursesEndpoint);
    final body = res.data;
    if (body == null) {
      throw const ContractViolation('Empty course catalog response',
          endpoint: _coursesEndpoint);
    }
    final page = parsePage<QuizCourseDto>(
      body,
      QuizCourseDto.fromJson,
      rowKeys: const ['items', 'courses'],
      endpoint: _coursesEndpoint,
    );
    return page.items.map((dto) => dto.toDomain()).toList();
  }

  Future<List<QuizCategoryEntry>> getCategories(String courseId) async {
    final endpoint = '/quiz/courses/$courseId/categories';
    final res = await _dio.get<Map<String, dynamic>>(endpoint);
    final body = res.data;
    if (body == null) {
      throw ContractViolation('Empty category response', endpoint: endpoint);
    }
    final page = parsePage<QuizCategoryDto>(
      body,
      QuizCategoryDto.fromJson,
      rowKeys: const ['items', 'categories'],
      endpoint: endpoint,
    );
    return page.items.map((dto) => dto.toDomain()).toList();
  }

  /// One cursor page of a course's questions.
  ///
  /// [categoryId] narrows the pool to one topic; [cursor] is the opaque token
  /// published by the previous page and is round-tripped verbatim.
  Future<Page<QuestionRowDto>> getQuestionPage({
    required String courseId,
    String? categoryId,
    String? cursor,
    int perPage = 100,
  }) async {
    final endpoint = '/quiz/courses/$courseId/questions';
    final extra = <String, dynamic>{
      if (categoryId != null && categoryId.isNotEmpty)
        'category_id': int.tryParse(categoryId) ?? categoryId,
    };
    final res = await _dio.get<Map<String, dynamic>>(
      endpoint,
      queryParameters: cursorQuery(
        cursor: cursor,
        perPage: perPage,
        extra: extra,
      ),
    );
    final body = res.data;
    if (body == null) {
      throw ContractViolation('Empty question response', endpoint: endpoint);
    }
    return parsePage<QuestionRowDto>(
      body,
      QuestionRowDto.fromJson,
      endpoint: endpoint,
    );
  }

  Future<AttemptReview> getAttemptReview(String attemptId) async {
    final endpoint = '/quiz/attempts/$attemptId/results';
    final res = await _dio.get<Map<String, dynamic>>(endpoint);
    final body = res.data;
    if (body == null) {
      throw ContractViolation('Empty review response', endpoint: endpoint);
    }
    // Validate the envelope first, then let extractRows resolve the frozen
    // row key of this endpoint (`data.answers` today).
    requireDataMap(body, endpoint: endpoint);
    final rows = extractRows(
      body,
      keys: const ['answers', 'entries', 'items', 'questions'],
      endpoint: endpoint,
    );
    return AttemptReviewDto.fromJson(rows).toDomain();
  }
}
