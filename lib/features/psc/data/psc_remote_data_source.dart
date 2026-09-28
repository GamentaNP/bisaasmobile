

import 'package:dio/dio.dart';

import '../../../core/network/api_response.dart';

/// PSC exam blueprints — `GET /api/v1/psc/blueprints` and the exam lifecycle
/// (`POST /psc/blueprints/{id}/exam`, `POST|PUT .../submission`).
///
/// These used to swallow every failure into `[]` / `null`, which made an
/// outage indistinguishable from "the server publishes no PSC exams": the
/// screen rendered "No blueprints - empty or offline". Failures are now
/// re-thrown so the UI can offer a retry, and the empty case stays empty.
class PscRemoteDataSource {
  const PscRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<Map<String, dynamic>>> getBlueprints() async {
    final res = await _dio.get<Map<String, dynamic>>('/psc/blueprints');
    final body = res.data;
    if (body == null) return const [];
    if (body['data'] is List) {
      return (body['data'] as List).cast<Map<String, dynamic>>();
    }
    final env = ApiResponse.fromJson(body, (j) => (j as List?)?.cast<Map<String, dynamic>>() ?? []);
    return env.data ?? const [];
  }

  Future<Map<String, dynamic>?> startExam(String id) async {
    final res = await _dio.post<Map<String, dynamic>>('/psc/blueprints/$id/exam');
    final body = res.data;
    if (body == null) return null;
    final env = ApiResponse.fromJson(body, (j) => j as Map<String, dynamic>?);
    return env.data ?? body['data'] as Map<String, dynamic>?;
  }

  Future<Map<String, dynamic>?> submit(String id, Map<String, dynamic> payload) async {
    // Canonical transition is PUT /blueprints/{id}/submission
    // (routes/api/v1.php:615); the POST .../submit form is the alias.
    final res = await _dio.put<Map<String, dynamic>>('/psc/blueprints/$id/submission', data: payload);
    final body = res.data;
    if (body == null) return null;
    final env = ApiResponse.fromJson(body, (j) => j as Map<String, dynamic>?);
    return env.data ?? body['data'] as Map<String, dynamic>?;
  }
}
