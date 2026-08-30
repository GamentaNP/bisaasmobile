// ignore_for_file: avoid_dynamic_calls, cast_nullable_to_non_nullable

import 'package:dio/dio.dart';

import '../../../../core/network/api_response.dart';
import '../models/coaching_dto.dart';

/// Coaching surfaces are intentionally tolerant — if a dedicated coaching route
/// does not exist, coaching aggregates tutor + learning data.
///
/// Verified / tolerant routes:
/// - GET /learning/goals/{goal}/readiness
/// - GET /learning/today
/// - GET /learning/tracks
/// - GET /learning/ai-tutor/weak-areas
/// - GET /learning/ai-tutor/projected-score
/// - GET /learning/ai-tutor/weekly-report
/// - GET /learning/ai-tutor/revisions/due
///
/// All calls degrade gracefully to null/[] on 404/500 so dashboard never
/// hard-fails on a single missing backend surface.
class CoachingRemoteDataSource {
  const CoachingRemoteDataSource(this._dio);
  final Dio _dio;

  Future<ReadinessDto?> getReadiness(String goalId) async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/learning/goals/$goalId/readiness');
      final body = res.data;
      if (body == null) return null;
      Map<String, dynamic> data;
      if (body['data'] is Map<String, dynamic>) {
        data = body['data'] as Map<String, dynamic>;
      } else {
        final env = ApiResponse.fromJson(body, (j) => j as Map<String, dynamic>?);
        data = env.data ?? {};
      }
      if (data.isEmpty) return null;
      return ReadinessDto.fromJson(goalId, data);
    } catch (_) {
      return null;
    }
  }

  Future<CoachingTodayDto?> getToday() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/learning/today');
      final body = res.data;
      if (body == null) return null;
      Map<String, dynamic> data;
      if (body['data'] is Map<String, dynamic>) {
        data = body['data'] as Map<String, dynamic>;
      } else {
        final env = ApiResponse.fromJson(body, (j) => j as Map<String, dynamic>?);
        data = env.data ?? {};
      }
      if (data.isEmpty) return null;
      // Nested under 'today'?
      final planMap = data['today'] is Map<String, dynamic> ? data['today'] as Map<String, dynamic> : data;
      return CoachingTodayDto.fromJson(planMap);
    } catch (_) {
      // Fallback to ai-tutor today
      try {
        final res = await _dio.get<Map<String, dynamic>>('/learning/ai-tutor/today');
        final body = res.data;
        if (body == null) return null;
        Map<String, dynamic> data;
        if (body['data'] is Map<String, dynamic>) {
          data = body['data'] as Map<String, dynamic>;
        } else {
          final env = ApiResponse.fromJson(body, (j) => j as Map<String, dynamic>?);
          data = env.data ?? {};
        }
        if (data.isEmpty) return null;
        return CoachingTodayDto.fromJson(data);
      } catch (_) {
        return null;
      }
    }
  }

  Future<List<CoachingTrackDto>> getTracks() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/learning/tracks');
      final body = res.data;
      if (body == null) return [];
      if (body['data'] is List) {
        final env = ApiResponse.fromJson(body, (j) => (j as List).cast<Map<String, dynamic>>());
        final list = env.data ?? [];
        return list.map(CoachingTrackDto.fromJson).toList();
      }
      final data = body['data'] as Map<String, dynamic>? ?? body;
      final list = (data['tracks'] ?? data['data'] ?? data['items'] ?? []) as List;
      return list.cast<Map<String, dynamic>>().map(CoachingTrackDto.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  Future<Map<String, dynamic>?> getWeakAreasRaw() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/learning/ai-tutor/weak-areas');
      return res.data;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getProjectedScoreRaw() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/learning/ai-tutor/projected-score');
      return res.data;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getWeeklyReportRaw() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/learning/ai-tutor/weekly-report');
      return res.data;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>?> getRevisionsDueRaw() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/learning/ai-tutor/revisions/due');
      return res.data;
    } catch (_) {
      return null;
    }
  }
}
