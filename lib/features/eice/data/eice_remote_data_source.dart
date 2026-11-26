

import 'package:dio/dio.dart';

import '../../../core/network/api_failure.dart';

/// Study-planner / sprint surfaces:
///   * `GET  /quiz/coach`                             (exam resolved server-side)
///   * `GET  /quiz/study-planner/{examId}`            (full mode-aware plan)
///   * `GET  /quiz/study-planner/{examId}/triage`     (numeric exam id)
///   * `GET  /quiz/topics/{topicId}/pattern`
///   * `GET  /quiz/courses/{courseId}/patterns`
///   * `GET  /quiz/sprint`
///   * `GET  /quiz/reports/weekly`
///   * `GET  /quiz/reports/weekly/history`            (bare list, max 50 rows)
///   * `PUT  /quiz/sprint/{question}/grade`
///
/// Every path segment that the server declares `whereNumber` is an `int` here
/// so a slug can never produce a route-level 404 again.
///
/// Every method used to be `catch (_) { return null / [] / false; }`, so a
/// dead endpoint rendered as "no study plan" / "no sprint" / "grade failed" —
/// the user could never tell a network or server fault from an empty account.
/// Failures now propagate; a genuinely empty payload still returns empty.
class EiceRemoteDataSource {
  const EiceRemoteDataSource(this._dio);
  final Dio _dio;

  /// Pull `data` out of the envelope.
  ///
  /// Returns null **only** when the server published no payload at all
  /// (`data: null`) — a real "you have no plan". A body the client cannot
  /// parse is a contract drift and throws, so it can never be rendered as
  /// "no study plan".
  Map<String, dynamic>? _dataOf(
    Map<String, dynamic>? body,
    String endpoint,
  ) {
    if (body == null) {
      throw ContractViolation('Empty response body', endpoint: endpoint);
    }
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    if (data == null && body.containsKey('data')) return null;
    throw ContractViolation(
      'Payload not understood: expected `data` to be an object',
      endpoint: endpoint,
    );
  }

  /// No exam segment.
  ///
  /// The route is `->whereNumber('exam')`, so it only matches a numeric
  /// `QuizTargetExam` id. The client used to send the literal `'psc-civil'`,
  /// which never matched and therefore 404'd at the routing layer on every
  /// single call — verified against the running backend:
  ///   study-planner/psc-civil/coach -> 404   (no such route)
  ///   study-planner/1/coach         -> 401   (route resolves)
  /// `GET /quiz/coach` takes no exam at all and `QuizStudyPlannerApiController`
  /// resolves the user's own active target exam (highest priority first),
  /// which is both correct and removes the client from that decision.
  Future<Map<String, dynamic>?> getCoach() async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/coach');
    return _dataOf(res.data, '/quiz/coach');
  }

  /// Full mode-aware plan for one target exam (`routes/api/v1/quiz.php:506`).
  /// The server owns the plan shape; the client only unwraps the envelope.
  Future<Map<String, dynamic>?> getStudyPlan(int examId) async {
    final endpoint = '/quiz/study-planner/$examId';
    final res = await _dio.get<Map<String, dynamic>>(endpoint);
    return _dataOf(res.data, endpoint);
  }

  /// Numeric exam id, taken from `exam_id` in the coach payload. Unlike coach
  /// this endpoint has no exam-less variant, so the id has to come from
  /// somewhere real.
  Future<Map<String, dynamic>?> getTriage(int examId) async {
    final endpoint = '/quiz/study-planner/$examId/triage';
    final res = await _dio.get<Map<String, dynamic>>(endpoint);
    return _dataOf(res.data, endpoint);
  }

  /// Past-paper frequency + AI prediction for one topic (`whereNumber('topic')`).
  Future<Map<String, dynamic>?> getTopicPattern(int topicId) async {
    final endpoint = '/quiz/topics/$topicId/pattern';
    final res = await _dio.get<Map<String, dynamic>>(endpoint);
    return _dataOf(res.data, endpoint);
  }

  /// Heatmap for a whole course (`whereNumber('course')`), highest score first.
  Future<Map<String, dynamic>?> getCoursePatterns(int courseId) async {
    final endpoint = '/quiz/courses/$courseId/patterns';
    final res = await _dio.get<Map<String, dynamic>>(endpoint);
    return _dataOf(res.data, endpoint);
  }

  Future<List<Map<String, dynamic>>> getSprint() async {
    const endpoint = '/quiz/sprint';
    final res = await _dio.get<Map<String, dynamic>>(endpoint);
    final body = res.data;
    if (body == null) {
      throw const ContractViolation('Empty response body', endpoint: endpoint);
    }
    final data = body['data'];
    if (data is List) return _rowsOf(data, endpoint);
    if (data is Map<String, dynamic>) {
      final items = data['items'];
      if (items is List) return _rowsOf(items, endpoint);
      // A published but empty sprint is a normal answer; a structurally
      // different object is contract drift, not "no cards due".
      if (data.isEmpty) return const [];
    }
    throw const ContractViolation(
      'Sprint payload not understood: expected `data` to be an array or '
      'an object with `items`',
      endpoint: endpoint,
    );
  }

  /// Past weekly reports, newest week first. `data` is a **bare list** (the
  /// controller calls `ApiResponse::success(data: $reports)`), not `{items: …}`
  /// and not an empty object.
  Future<List<Map<String, dynamic>>> getWeeklyHistory() async {
    const endpoint = '/quiz/reports/weekly/history';
    final res = await _dio.get<Map<String, dynamic>>(endpoint);
    final body = res.data;
    if (body == null) {
      throw const ContractViolation('Empty response body', endpoint: endpoint);
    }
    final data = body['data'];
    if (data is List) return _rowsOf(data, endpoint);
    throw const ContractViolation(
      'Expected `data` to be an array of weekly reports',
      endpoint: endpoint,
    );
  }

  /// Every row must be an object. Silently dropping malformed rows would
  /// render an outage as "fewer reports than there really are".
  List<Map<String, dynamic>> _rowsOf(List<Object?> rows, String endpoint) {
    final result = <Map<String, dynamic>>[];
    for (final row in rows) {
      if (row is! Map<String, dynamic>) {
        throw ContractViolation(
          'Expected each row to be an object, got ${row.runtimeType}',
          endpoint: endpoint,
        );
      }
      result.add(row);
    }
    return result;
  }

  Future<Map<String, dynamic>?> getWeekly() async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/reports/weekly');
    return _dataOf(res.data, '/quiz/reports/weekly');
  }

  /// Returns true only when the server accepted the grade. A 4xx/5xx throws, so
  /// the caller can show why it failed instead of a bare "failed".
  Future<bool> gradeSprint(String questionId, int grade) async {
    // PUT is canonical (`sprint.grade`); POST is `sprint.grade.transition-alias`
    // (routes/api/v1/quiz.php:474-477).
    await _dio.put<Map<String, dynamic>>(
      '/quiz/sprint/$questionId/grade',
      data: {'grade': grade},
    );
    return true;
  }
}
