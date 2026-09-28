// ignore_for_file: cast_nullable_to_non_nullable

import 'package:dio/dio.dart';

import '../../../core/network/api_response.dart';

/// Study-planner / sprint surfaces:
///   * `GET  /quiz/study-planner/{exam}/coach`
///   * `GET  /quiz/study-planner/{exam}/triage`
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

  Future<Map<String, dynamic>?> getCoach(String exam) async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/study-planner/$exam/coach');
    return _dataOf(res.data);
  }

  Future<Map<String, dynamic>?> getTriage(String exam) async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/study-planner/$exam/triage');
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
