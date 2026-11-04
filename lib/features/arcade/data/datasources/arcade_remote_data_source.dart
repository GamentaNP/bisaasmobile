/// The arcade wire: start, resume, answer, finish — all server-scored.
///
/// Every call here maps to a route that exists in
/// `C:\laragon\www\bisaas\routes\api\v1\quiz.php`:
///
/// | Call | Route | Idempotency |
/// |---|---|---|
/// | start | `POST /quiz/{survival\|lightning\|true-false}/start` | required |
/// | questions | `GET /quiz/attempts/{attempt}` | — |
/// | answer | `POST /quiz/attempts/{attempt}/answers` | required |
/// | finish | `PUT /quiz/attempts/{attempt}/completion` | required |
/// | results | `GET /quiz/attempts/{attempt}/results` | — |
/// | quit | `PUT /quiz/attempts/{attempt}/abandonment` | required |
/// | courses | `GET /quiz/courses` | — |
/// | categories | `GET /quiz/courses/{course}/categories` | — |
///
/// Two facts shape this file:
///
///  * **A start returns only an id.** The questions come from the attempt
///    itself, so `fetchAttempt` is not optional — it is how every mode gets
///    its questions, and it is the field that proves the client can resume.
///  * **Grading is withheld until the attempt is complete.** The answer
///    endpoint answers `{success, message}` with no verdict, by design
///    (`QuizQuestionResource` exposure policy), so the client never learns
///    "right/wrong" mid-run. Survival learns the run ended by re-reading the
///    attempt's status — the server is the one that ends it.
library;

import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/envelope.dart';
import '../../domain/entities/arcade_category.dart';
import '../../domain/entities/arcade_mode.dart';
import '../../domain/entities/arcade_question.dart';
import '../../domain/entities/arcade_result.dart';

class ArcadeRemoteDataSource {
  const ArcadeRemoteDataSource(this._dio);

  final Dio _dio;

  /// Starts a run. `idempotencyKey` must be stable across retries of the same
  /// intent: the server dedupes on key + request hash, so a double-tap with
  /// the same key resumes the attempt instead of creating a second one.
  Future<int> start({
    required ArcadeMode mode,
    required String idempotencyKey,
    int? categoryId,
  }) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>(
        mode.startPath,
        data: <String, dynamic>{
          'category_id': ?categoryId,
        },
        options: Options(headers: idempotencyHeader(idempotencyKey)),
      );
      final data = requireDataMap(res.data, endpoint: mode.startPath);
      final id = data['attempt_id'];
      if (id is int) return id;
      final parsed = int.tryParse('$id');
      if (parsed == null) {
        throw ContractViolation(
          'Start response carried no attempt_id',
          endpoint: mode.startPath,
        );
      }
      return parsed;
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  /// Loads the attempt with its questions in the server's order.
  ///
  /// A row whose question is null (its question was deleted after the attempt
  /// was seeded) is dropped rather than rendered as an empty card; if that
  /// leaves nothing, the run cannot continue and says so.
  Future<({String status, List<ArcadeQuestion> questions})> fetchAttempt(
    int attemptId,
  ) async {
    const path = '/quiz/attempts';
    try {
      final res =
          await _dio.get<Map<String, dynamic>>('$path/$attemptId');
      final data = requireDataMap(res.data, endpoint: '$path/$attemptId');
      final raw = data['questions'];
      if (raw is! List) {
        throw ContractViolation(
          'Attempt response carried no questions list',
          endpoint: '$path/$attemptId',
        );
      }
      final questions = <ArcadeQuestion>[];
      for (final row in raw) {
        if (row is! Map<String, dynamic>) continue;
        final question = row['question'];
        if (question is! Map<String, dynamic>) continue;
        final parsed = _question(question);
        if (parsed != null) questions.add(parsed);
      }
      return (
        status: '${data['status'] ?? 'in_progress'}',
        questions: questions,
      );
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  /// Submits one answer. No verdict comes back — see the file header.
  Future<void> submitAnswer({
    required int attemptId,
    required int questionId,
    required String answer,
    required String idempotencyKey,
    required int timeTakenSeconds,
  }) async {
    final path = '/quiz/attempts/$attemptId/answers';
    try {
      await _dio.post<Map<String, dynamic>>(
        path,
        data: <String, dynamic>{
          'question_id': questionId,
          'answer': answer,
          'time_taken_seconds': timeTakenSeconds,
        },
        options: Options(headers: idempotencyHeader(idempotencyKey)),
      );
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  /// Completes the attempt and returns the server's tally.
  Future<ArcadeResult> complete({
    required int attemptId,
    required String idempotencyKey,
  }) async {
    final path = '/quiz/attempts/$attemptId/completion';
    try {
      final res = await _dio.put<Map<String, dynamic>>(
        path,
        options: Options(headers: idempotencyHeader(idempotencyKey)),
      );
      return _result(requireDataMap(res.data, endpoint: path));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  /// The full result of an attempt that is already complete server-side —
  /// the Survival path, where the server ends the run itself.
  Future<ArcadeResult> results(int attemptId) async {
    final path = '/quiz/attempts/$attemptId/results';
    try {
      final res = await _dio.get<Map<String, dynamic>>(path);
      return _result(requireDataMap(res.data, endpoint: path));
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  /// Abandons an in-progress attempt. Awards nothing, by contract.
  Future<void> abandon({
    required int attemptId,
    required String idempotencyKey,
  }) async {
    final path = '/quiz/attempts/$attemptId/abandonment';
    try {
      await _dio.put<Map<String, dynamic>>(
        path,
        options: Options(headers: idempotencyHeader(idempotencyKey)),
      );
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<List<ArcadeCourse>> courses() async {
    const path = '/quiz/courses';
    try {
      final res = await _dio.get<Map<String, dynamic>>(path);
      final body = res.data;
      if (body == null) {
        throw const ContractViolation(
          'Empty response body',
          endpoint: path,
        );
      }
      // This route predates the envelope's list convention: `data` is either
      // the list itself or `{items: [...]}`. Both are accepted; a third shape
      // is drift.
      final data = body['data'];
      final raw = data is List
          ? data
          : data is Map<String, dynamic>
              ? data['items']
              : null;
      if (raw is! List) {
        throw const ContractViolation(
          'Course list had an unexpected shape',
          endpoint: path,
        );
      }
      final courses = <ArcadeCourse>[];
      for (final row in raw) {
        if (row is! Map<String, dynamic>) continue;
        final id = _asInt(row['id']);
        final name = '${row['name'] ?? row['title'] ?? ''}'.trim();
        if (id == null || name.isEmpty) continue;
        courses.add(ArcadeCourse(id: id, name: name));
      }
      return courses;
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  Future<List<ArcadeCategory>> categories({
    required ArcadeCourse course,
  }) async {
    final path = '/quiz/courses/${course.id}/categories';
    try {
      final res = await _dio.get<Map<String, dynamic>>(path);
      final rows = requireDataList(res.data, endpoint: path);
      final categories = <ArcadeCategory>[];
      for (final row in rows) {
        final id = _asInt(row['id']);
        final name = '${row['name'] ?? ''}'.trim();
        if (id == null || name.isEmpty) continue;
        categories.add(
          ArcadeCategory(
            id: id,
            name: name,
            courseId: course.id,
            courseName: course.name,
          ),
        );
      }
      return categories;
    } on DioException catch (e) {
      throw toApiException(e);
    }
  }

  /// Maps one `QuizQuestionResource` to the run's question.
  static ArcadeQuestion? _question(Map<String, dynamic> json) {
    final id = _asInt(json['id']);
    if (id == null) return null;
    final body = '${json['question_text'] ?? json['body'] ?? ''}'.trim();
    if (body.isEmpty) return null;

    final rawOptions = json['options'];
    final options = <ArcadeOption>[];
    if (rawOptions is List) {
      for (var i = 0; i < rawOptions.length; i++) {
        final option = rawOptions[i];
        if (option is String) {
          options.add(
            ArcadeOption(id: option, text: option, position: i),
          );
          continue;
        }
        if (option is! Map<String, dynamic>) continue;
        // `key` is what the grader matches; it is also what the study flow
        // submits. The fallbacks cover older payloads that used id/value.
        final key =
            '${option['key'] ?? option['id'] ?? option['value'] ?? i}';
        final text =
            '${option['text'] ?? option['label'] ?? option['value'] ?? ''}'
                .trim();
        options.add(
          ArcadeOption(
            id: key,
            text: text.isEmpty ? key : text,
            position: _asInt(option['position']) ?? i,
          ),
        );
      }
      options.sort((a, b) => a.position.compareTo(b.position));
    }

    final metadata = json['metadata'];
    final image = json['image_url'] ??
        (metadata is Map<String, dynamic> ? metadata['image_url'] : null);

    return ArcadeQuestion(
      id: id,
      body: body,
      options: options,
      type: '${json['type'] ?? 'mcq'}',
      imageUrl: image is String && image.isNotEmpty ? image : null,
    );
  }

  static ArcadeResult _result(Map<String, dynamic> data) => ArcadeResult(
        attemptId: _asInt(data['attempt_id']) ?? 0,
        mode: '${data['mode'] ?? ''}',
        status: '${data['status'] ?? 'completed'}',
        score: _asInt(data['score']) ?? 0,
        correctCount: _asInt(data['correct_count']) ?? 0,
        wrongCount: _asInt(data['wrong_count']) ?? 0,
        skippedCount: _asInt(data['skipped_count']) ?? 0,
        completedAt: DateTime.tryParse('${data['completed_at'] ?? ''}'),
      );

  static int? _asInt(Object? value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse('$value');
  }
}
