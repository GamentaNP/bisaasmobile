// ignore_for_file: cast_nullable_to_non_nullable

import 'package:dio/dio.dart';

import '../../../core/network/api_response.dart';

class PscRemoteDataSource {
  const PscRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<Map<String, dynamic>>> getBlueprints() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/psc/blueprints');
      final body = res.data!;
      if (body['data'] is List) return (body['data'] as List).cast<Map<String, dynamic>>();
      final env = ApiResponse.fromJson(body, (j) => (j as List?)?.cast<Map<String, dynamic>>() ?? []);
      return env.data ?? [];
    } catch (_) { return []; }
  }

  Future<Map<String, dynamic>?> startExam(String id) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/psc/blueprints/$id/exam');
      final env = ApiResponse.fromJson(res.data!, (j) => j as Map<String, dynamic>?);
      return env.data ?? res.data!['data'] as Map<String, dynamic>?;
    } catch (_) { return null; }
  }

  Future<Map<String, dynamic>?> submit(String id, Map<String, dynamic> payload) async {
    try {
      final res = await _dio.post<Map<String, dynamic>>('/psc/blueprints/$id/submit', data: payload);
      final env = ApiResponse.fromJson(res.data!, (j) => j as Map<String, dynamic>?);
      return env.data ?? res.data!['data'] as Map<String, dynamic>?;
    } catch (_) { return null; }
  }
}
