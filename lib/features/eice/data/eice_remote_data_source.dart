

import 'package:dio/dio.dart';

import '../../../core/network/api_response.dart';

/// Study-planner / sprint surfaces:
///   * `GET  /quiz/coach`                             (exam resolved server-side)
///   * `GET  /quiz/study-planner/{examId}/triage`     (numeric exam id)
///   * `GET  /quiz/sprint`
///   * `GET  /quiz/reports/weekly`
///   * `POST /quiz/sprint/{question}/grade`
///
/// Every method used to be `catch (_) { return null / [] / false; }`, so a
/// dead endpoint rendered as "no study plan" / "no sprint" / "grade failed" —
/// the user could never tell a network or server fault from an empty account.
/// Failures now propagate; a genuinely empty payload still returns empty.
class EiceRemoteDataSource {
  const EiceRemoteDataSource(this._dio);
  final Dio _dio;

  /// Pull `data` out of the envelope, tolerating a raw body.
  Map<String, dynamic>? _dataOf(Map<String, dynamic>? body) {
    if (body == null) return null;
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    try {
      return ApiResponse.fromJson(body, (j) => j as Map<String, dynamic>?).data;
    } catch (_) {
      return null;
    }
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
    return _dataOf(res.data);
  }

  /// Numeric exam id, taken from `exam_id` in the coach payload. Unlike coach
  /// this endpoint has no exam-less variant, so the id has to come from
  /// somewhere real.
  Future<Map<String, dynamic>?> getTriage(int examId) async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/study-planner/$examId/triage');
    return _dataOf(res.data);
  }

  Future<List<Map<String, dynamic>>> getSprint() async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/sprint');
    final body = res.data;
    if (body == null) return const [];
    final data = body['data'];
    if (data is List) return data.cast<Map<String, dynamic>>();
    if (data is Map<String, dynamic>) {
      final items = data['items'];
      if (items is List) return items.cast<Map<String, dynamic>>();
      return const [];
    }
    final env = ApiResponse.fromJson(body, (j) => (j as List?)?.cast<Map<String, dynamic>>() ?? []);
    return env.data ?? const [];
  }

  Future<Map<String, dynamic>?> getWeekly() async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/reports/weekly');
    return _dataOf(res.data);
  }

  /// Returns true only when the server accepted the grade. A 4xx/5xx throws, so
  /// the caller can show why it failed instead of a bare "failed".
  Future<bool> gradeSprint(String questionId, int grade) async {
    await _dio.post<Map<String, dynamic>>(
      '/quiz/sprint/$questionId/grade',
      data: {'grade': grade},
    );
    return true;
  }
}
