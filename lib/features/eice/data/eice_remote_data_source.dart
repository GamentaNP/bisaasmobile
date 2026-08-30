// ignore_for_file: cast_nullable_to_non_nullable

import 'package:dio/dio.dart';

import '../../../core/network/api_response.dart';

class EiceRemoteDataSource {
  const EiceRemoteDataSource(this._dio);
  final Dio _dio;

  Future<Map<String, dynamic>?> getCoach(String exam) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/quiz/study-planner/$exam/coach');
      final env = ApiResponse.fromJson(res.data!, (j) => j as Map<String, dynamic>?);
      return env.data ?? res.data!['data'] as Map<String, dynamic>?;
    } catch (_) { return null; }
  }

  Future<Map<String, dynamic>?> getTriage(String exam) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/quiz/study-planner/$exam/triage');
      final env = ApiResponse.fromJson(res.data!, (j) => j as Map<String, dynamic>?);
      return env.data ?? res.data!['data'] as Map<String, dynamic>?;
    } catch (_) { return null; }
  }

  Future<List<Map<String, dynamic>>> getSprint() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/quiz/sprint');
      final body = res.data!;
      if (body['data'] is List) return (body['data'] as List).cast<Map<String, dynamic>>();
      final env = ApiResponse.fromJson(body, (j) => (j as List?)?.cast<Map<String, dynamic>>() ?? []);
      return env.data ?? [];
    } catch (_) { return []; }
  }

  Future<Map<String, dynamic>?> getWeekly() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/quiz/reports/weekly');
      final env = ApiResponse.fromJson(res.data!, (j) => j as Map<String, dynamic>?);
      return env.data ?? res.data!['data'] as Map<String, dynamic>?;
    } catch (_) { return null; }
  }

  Future<bool> gradeSprint(String questionId, int grade) async {
    try {
      await _dio.post<Map<String, dynamic>>('/quiz/sprint/$questionId/grade', data: {'grade': grade});
      return true;
    } catch (_) { return false; }
  }
}
