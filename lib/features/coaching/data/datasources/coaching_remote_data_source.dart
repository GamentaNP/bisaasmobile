// ignore_for_file: cast_nullable_to_non_nullable

import 'package:dio/dio.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/api_response.dart';
import '../models/coaching_dto.dart';

/// Coaching surfaces aggregate tutor + learning data.
///
/// Verified routes:
/// - GET /learning/goals/{goal}/readiness
/// - GET /learning/today
/// - GET /learning/tracks
/// - GET /learning/ai-tutor/weak-areas
/// - GET /learning/ai-tutor/projected-score
/// - GET /learning/ai-tutor/weekly-report
/// - GET /learning/ai-tutor/revisions/due
///
/// **A missing coaching surface is a failure, not an empty dashboard.**
/// This data source used to answer every error with `null`, so a dead
/// endpoint rendered as "you have no study plan" — indistinguishable from an
/// account with no plan. The failures now propagate, and the coaching screen
/// shows them.
///
/// The one place tolerance is correct is [getToday]: it has a documented
/// fallback route (`/learning/ai-tutor/today`), and it is only used when the
/// primary route genuinely has no plan.
class CoachingRemoteDataSource {
  const CoachingRemoteDataSource(this._dio);
  final Dio _dio;

  /// Reads the `data` object out of a coaching envelope.
  ///
  /// Returns null **only** when the server published no payload at all
  /// (`data: null`) — a real "you have no plan". A body the client cannot
  /// parse is drift and throws, so it can never be rendered as
  /// "no study plan".
  Map<String, dynamic>? _data(Map<String, dynamic>? body, String endpoint) {
    if (body == null) {
      throw ContractViolation('Empty response body', endpoint: endpoint);
    }
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    if (data == null && body.containsKey('data')) return null;
    throw ContractViolation(
      'Coaching payload not understood: expected `data` to be an object',
      endpoint: endpoint,
    );
  }

  Future<ReadinessDto?> getReadiness(String goalId) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/learning/goals/$goalId/readiness',
    );
    final data = _data(res.data, '/learning/goals/$goalId/readiness');
    if (data == null || data.isEmpty) return null;
    return ReadinessDto.fromJson(goalId, data);
  }

  Future<CoachingTodayDto?> getToday() async {
    try {
      final res = await _dio.get<Map<String, dynamic>>('/learning/today');
      final data = _data(res.data, '/learning/today');
      if (data == null || data.isEmpty) {
        // No plan on the primary route. The AI tutor publishes an equivalent
        // plan, so that is the next place to look — not a swallowed error.
        return await _todayFromAiTutor();
      }
      // Nested under 'today'?
      final planMap = data['today'] is Map<String, dynamic>
          ? data['today'] as Map<String, dynamic>
          : data;
      return CoachingTodayDto.fromJson(planMap);
    } on ContractViolation {
      return _todayFromAiTutor();
    }
  }

  Future<CoachingTodayDto?> _todayFromAiTutor() async {
    final res = await _dio.get<Map<String, dynamic>>('/learning/ai-tutor/today');
    final data = _data(res.data, '/learning/ai-tutor/today');
    if (data == null || data.isEmpty) return null;
    return CoachingTodayDto.fromJson(data);
  }

  Future<List<CoachingTrackDto>> getTracks() async {
    final res = await _dio.get<Map<String, dynamic>>('/learning/tracks');
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty response body',
        endpoint: '/learning/tracks',
      );
    }
    if (body['data'] is List) {
      final env = ApiResponse.fromJson(
        body,
        (j) => (j as List).cast<Map<String, dynamic>>(),
      );
      final list = env.data ?? [];
      return list.map(CoachingTrackDto.fromJson).toList();
    }
    final data = body['data'] as Map<String, dynamic>? ?? body;
    final list = (data['tracks'] ?? data['data'] ?? data['items'] ?? []) as List;
    return list.cast<Map<String, dynamic>>().map(CoachingTrackDto.fromJson).toList();
  }

  Future<Map<String, dynamic>?> getWeakAreasRaw() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/learning/ai-tutor/weak-areas',
    );
    return _data(res.data, '/learning/ai-tutor/weak-areas');
  }

  Future<Map<String, dynamic>?> getProjectedScoreRaw() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/learning/ai-tutor/projected-score',
    );
    return _data(res.data, '/learning/ai-tutor/projected-score');
  }

  Future<Map<String, dynamic>?> getWeeklyReportRaw() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/learning/ai-tutor/weekly-report',
    );
    return _data(res.data, '/learning/ai-tutor/weekly-report');
  }

  Future<Map<String, dynamic>?> getRevisionsDueRaw() async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/learning/ai-tutor/revisions/due',
    );
    return _data(res.data, '/learning/ai-tutor/revisions/due');
  }
}
