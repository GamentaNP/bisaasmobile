import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/network/api_response.dart';
import '../models/quiz_dto.dart';
import '../models/attempt_dto.dart';

class QuizRemoteDataSource {
  const QuizRemoteDataSource(this._dio);
  final Dio _dio;

  static const _uuid = Uuid();

  Future<List<Map<String, dynamic>>> getQuizList({String? subjectSlug}) async {
    final params = <String, dynamic>{};
    if (subjectSlug != null) params['subject_slug'] = subjectSlug;

    final res = await _dio.get<Map<String, dynamic>>(
      '/quiz/quizzes',
      queryParameters: params.isNotEmpty ? params : null,
    );
    final envelope = ApiResponse.fromJson(
      res.data!,
      (json) => (json! as List).cast<Map<String, dynamic>>(),
    );
    return envelope.data ?? [];
  }

  Future<QuizSessionDto> getQuizSession(String quizId) async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/quizzes/$quizId');
    final envelope = ApiResponse.fromJson(
      res.data!,
      (json) => QuizSessionDto.fromJson(json! as Map<String, dynamic>),
    );
    if (envelope.data == null) throw Exception('Quiz session data missing');
    return envelope.data!;
  }

  Future<String> startAttempt({
    required String quizId,
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? _uuid.v4();
    final res = await _dio.post<Map<String, dynamic>>(
      '/quiz/attempts',
      data: {'quiz_id': quizId},
      options: Options(headers: {'Idempotency-Key': key}),
    );
    final envelope = ApiResponse.fromJson(
      res.data!,
      (json) {
        final m = json! as Map<String, dynamic>;
        return (m['attempt_id'] as String?) ?? (m['id'] as String);
      },
    );
    if (envelope.data == null) throw Exception('Attempt ID missing from server response');
    return envelope.data!;
  }

  Future<AttemptResultDto> submitAnswer({
    required String attemptId,
    required String questionId,
    required String selectedOptionId,
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? _uuid.v4();
    final res = await _dio.post<Map<String, dynamic>>(
      '/quiz/attempts/$attemptId/answer',
      data: {
        'question_id': questionId,
        'selected_option_id': selectedOptionId,
      },
      options: Options(headers: {'Idempotency-Key': key}),
    );
    final envelope = ApiResponse.fromJson(
      res.data!,
      (json) => AttemptResultDto.fromJson(json! as Map<String, dynamic>),
    );
    if (envelope.data == null) throw Exception('Answer result missing');
    return envelope.data!;
  }

  Future<QuizResultDto> finishAttempt(String attemptId) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/quiz/attempts/$attemptId/finish',
    );
    final envelope = ApiResponse.fromJson(
      res.data!,
      (json) => QuizResultDto.fromJson(json! as Map<String, dynamic>),
    );
    if (envelope.data == null) throw Exception('Quiz result missing');
    return envelope.data!;
  }
}
