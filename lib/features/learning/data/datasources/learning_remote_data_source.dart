// ignore_for_file: cast_nullable_to_non_nullable

import 'package:dio/dio.dart';

import '../../../../core/network/api_response.dart';
import '../models/learning_dto.dart';

class LearningRemoteDataSource {
  const LearningRemoteDataSource(this._dio);
  final Dio _dio;

  Future<List<LearningTrackDto>> getTracks() async {
    final res = await _dio.get<Map<String, dynamic>>('/learning/tracks');
    final body = res.data!;
    // envelope `data` may be List or {tracks:[]}
    if (body['data'] is List) {
      final env = ApiResponse.fromJson(body, (j) => (j as List).cast<Map<String, dynamic>>());
      final list = env.data ?? [];
      return list.map(LearningTrackDto.fromJson).toList();
    }
    final data = body['data'] as Map<String, dynamic>? ?? body;
    final list = (data['tracks'] ?? data['data'] ?? []) as List;
    return list.cast<Map<String, dynamic>>().map(LearningTrackDto.fromJson).toList();
  }

  Future<TodayPlanDto> getToday() async {
    final res = await _dio.get<Map<String, dynamic>>('/learning/today');
    final env = ApiResponse.fromJson(res.data!, (j) => j as Map<String, dynamic>?);
    final data = env.data ?? res.data!['data'] as Map<String, dynamic>? ?? res.data!;
    // `data` may be the plan itself or nested under `today`
    final planMap = data['today'] is Map<String, dynamic> ? data['today'] as Map<String, dynamic> : data;
    return TodayPlanDto.fromJson(planMap);
  }

  Future<List<ReviewItemDto>> getReviewsDue() async {
    final res = await _dio.get<Map<String, dynamic>>('/learning/reviews/due');
    final env = ApiResponse.fromJson(res.data!, (j) => (j as List?)?.cast<Map<String, dynamic>>() ?? []);
    if (env.data != null) return env.data!.map(ReviewItemDto.fromJson).toList();
    final body = res.data!;
    final data = body['data'];
    if (data is List) return data.cast<Map<String, dynamic>>().map(ReviewItemDto.fromJson).toList();
    if (data is Map && data['reviews'] is List) return (data['reviews'] as List).cast<Map<String, dynamic>>().map(ReviewItemDto.fromJson).toList();
    return [];
  }

  Future<String> askTutor(String prompt, {List<Map<String, String>>? history}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/learning/tutor',
      data: {'prompt': prompt, 'message': prompt, 'history': history ?? []},
    );
    final body = res.data!;
    final env = ApiResponse.fromJson(body, (j) => j as Map<String, dynamic>?);
    final data = env.data ?? body['data'];
    if (data is Map) return (data['answer'] ?? data['response'] ?? data['content'] ?? data['message'] ?? '').toString();
    if (data is String) return data;
    return (body['answer'] ?? body['response'] ?? body['message'] ?? '').toString();
  }
}
