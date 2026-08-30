// ignore_for_file: cast_nullable_to_non_nullable, avoid_dynamic_calls, use_null_aware_elements, unnecessary_cast
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/api_response.dart';
import '../models/learning_dto.dart';

/// Server-verified routes (php artisan route:list --path=api/v1/learning in C:\laragon\www\bisaas):
/// - GET /learning/tracks
/// - GET /learning/goals + POST /learning/goals + GET /learning/goals/{goal} + GET /learning/goals/{goal}/readiness + DELETE
/// - GET /learning/today + POST /learning/today/{plan}/complete-item
/// - GET /learning/reviews/due + POST /learning/reviews/{review}/grade
/// - POST /learning/tutor (non-streaming, per AGENTS.md streaming is web-only)
///
/// All authenticated via Bearer (Dio AuthInterceptor). Do NOT hardcode host, do NOT add /api/v1 twice — baseUrl already has it.
class LearningRemoteDataSource {
  const LearningRemoteDataSource(this._dio);
  final Dio _dio;
  static const _uuid = Uuid();

  Map<String, String> _idempotencyHeader([String? key]) => {'Idempotency-Key': key ?? _uuid.v4()};

  // ── Tracks ──────────────────────────────────────────────────────────────────

  Future<List<LearningTrackDto>> getTracks() async {
    final res = await _dio.get<Map<String, dynamic>>('/learning/tracks');
    final body = res.data;
    if (body == null) return [];
    final data = body['data'];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map(LearningTrackDto.fromJson).toList();
    }
    if (data is Map<String, dynamic>) {
      // envelope fallback: data.tracks
      final nested = data['tracks'] ?? data['data'] ?? [];
      if (nested is List) {
        return nested.whereType<Map<String, dynamic>>().map(LearningTrackDto.fromJson).toList();
      }
    }
    try {
      final env = ApiResponse.fromJson(body, (json) {
        if (json is List) return (json as List).cast<Map<String, dynamic>>();
        if (json is Map<String, dynamic> && json['tracks'] is List) {
          return (json['tracks'] as List).cast<Map<String, dynamic>>();
        }
        return <Map<String, dynamic>>[];
      });
      return (env.data ?? []).map(LearningTrackDto.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  // ── Goals ───────────────────────────────────────────────────────────────────

  Future<List<LearningGoalDto>> getGoals() async {
    final res = await _dio.get<Map<String, dynamic>>('/learning/goals');
    final body = res.data;
    if (body == null) return [];
    final data = body['data'];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map(LearningGoalDto.fromJson).toList();
    }
    try {
      final env = ApiResponse.fromJson(body, (json) {
        if (json is List) return (json as List).cast<Map<String, dynamic>>();
        return <Map<String, dynamic>>[];
      });
      return (env.data ?? []).map(LearningGoalDto.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  Future<LearningGoalDto> createGoal({
    required int trackId,
    String? targetDate, // YYYY-MM-DD
    int? dailyMinutes,
    String? intensity, // casual | regular | intense
    Map<String, dynamic>? placementMeta,
    String? idempotencyKey,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/learning/goals',
      data: {
        'track_id': trackId,
        if (targetDate != null) 'target_date': targetDate,
        if (dailyMinutes != null) 'daily_minutes': dailyMinutes,
        if (intensity != null) 'intensity': intensity,
        if (placementMeta != null) 'placement_meta': placementMeta,
      },
      options: Options(headers: _idempotencyHeader(idempotencyKey)),
    );
    final body = res.data;
    if (body == null) throw Exception('Create goal response empty');
    Map<String, dynamic>? data;
    if (body['data'] is Map<String, dynamic>) {
      data = body['data'] as Map<String, dynamic>;
    } else {
      try {
        final env = ApiResponse.fromJson(body, (j) => j as Map<String, dynamic>?);
        data = env.data;
      } catch (_) {}
    }
    if (data == null) throw Exception('Create goal data missing');
    return LearningGoalDto.fromJson(data);
  }

  Future<LearningGoalDto> getGoal(int goalId) async {
    final res = await _dio.get<Map<String, dynamic>>('/learning/goals/$goalId');
    final body = res.data;
    if (body == null) throw Exception('Goal not found: $goalId');
    Map<String, dynamic>? data;
    if (body['data'] is Map<String, dynamic>) {
      data = body['data'] as Map<String, dynamic>;
    } else {
      final env = ApiResponse.fromJson(body, (j) => j as Map<String, dynamic>?);
      data = env.data;
    }
    if (data == null) throw Exception('Goal data missing for $goalId');
    return LearningGoalDto.fromJson(data);
  }

  Future<LearningGoalReadinessDto> getGoalReadiness(int goalId) async {
    final res = await _dio.get<Map<String, dynamic>>('/learning/goals/$goalId/readiness');
    final body = res.data;
    if (body == null) throw Exception('Readiness response empty');
    Map<String, dynamic>? data;
    if (body['data'] is Map<String, dynamic>) {
      data = body['data'] as Map<String, dynamic>;
    } else {
      try {
        final env = ApiResponse.fromJson(body, (j) => j as Map<String, dynamic>?);
        data = env.data;
      } catch (_) {}
    }
    if (data == null) throw Exception('Readiness data missing');
    return LearningGoalReadinessDto.fromJson(data);
  }

  Future<void> deleteGoal(int goalId) async {
    await _dio.delete<Map<String, dynamic>>('/learning/goals/$goalId');
  }

  // ── Today ───────────────────────────────────────────────────────────────────

  Future<DailyPlanDto?> getToday() async {
    final res = await _dio.get<Map<String, dynamic>>('/learning/today');
    final body = res.data;
    if (body == null) return null;
    // Controller returns success(data:null) when no active goal
    if (body['data'] == null) return null;
    Map<String, dynamic>? data;
    if (body['data'] is Map<String, dynamic>) {
      data = body['data'] as Map<String, dynamic>;
    } else {
      try {
        final env = ApiResponse.fromJson(body, (j) => j as Map<String, dynamic>?);
        data = env.data;
      } catch (_) {}
    }
    if (data == null) return null;
    // If data is empty map, treat as no plan
    if (data.isEmpty) return null;
    return DailyPlanDto.fromJson(data);
  }

  Future<DailyPlanDto> completeTodayItem(int planId, int itemIndex, {String? idempotencyKey}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/learning/today/$planId/complete-item',
      data: {'item_index': itemIndex},
      options: Options(headers: _idempotencyHeader(idempotencyKey)),
    );
    final body = res.data;
    if (body == null) throw Exception('Complete item response empty');
    Map<String, dynamic>? data;
    if (body['data'] is Map<String, dynamic>) {
      data = body['data'] as Map<String, dynamic>;
    } else {
      final env = ApiResponse.fromJson(body, (j) => j as Map<String, dynamic>?);
      data = env.data;
    }
    if (data == null) throw Exception('Complete item data missing');
    return DailyPlanDto.fromJson(data);
  }

  // ── Reviews (Spaced Repetition) ────────────────────────────────────────────

  Future<List<ReviewItemDto>> getReviewsDue() async {
    final res = await _dio.get<Map<String, dynamic>>('/learning/reviews/due');
    final body = res.data;
    if (body == null) return [];
    final data = body['data'];
    if (data is List) {
      return data.whereType<Map<String, dynamic>>().map(ReviewItemDto.fromJson).toList();
    }
    if (data is Map<String, dynamic> && data['reviews'] is List) {
      return (data['reviews'] as List).whereType<Map<String, dynamic>>().map(ReviewItemDto.fromJson).toList();
    }
    try {
      final env = ApiResponse.fromJson(body, (json) {
        if (json is List) return (json as List).cast<Map<String, dynamic>>();
        if (json is Map<String, dynamic> && json['reviews'] is List) {
          return (json['reviews'] as List).cast<Map<String, dynamic>>();
        }
        return <Map<String, dynamic>>[];
      });
      return (env.data ?? []).map(ReviewItemDto.fromJson).toList();
    } catch (_) {
      return [];
    }
  }

  /// Grade a review — outcome one of again|hard|good|easy (FSRS). Uses Idempotency-Key.
  Future<ReviewItemDto> gradeReview(int reviewId, String outcome, {String? idempotencyKey}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/learning/reviews/$reviewId/grade',
      data: {'outcome': outcome},
      options: Options(headers: _idempotencyHeader(idempotencyKey)),
    );
    final body = res.data;
    if (body == null) throw Exception('Grade response empty');
    Map<String, dynamic>? data;
    if (body['data'] is Map<String, dynamic>) {
      data = body['data'] as Map<String, dynamic>;
    } else {
      final env = ApiResponse.fromJson(body, (j) => j as Map<String, dynamic>?);
      data = env.data;
    }
    if (data == null) throw Exception('Grade data missing');
    // Grade response shape is sparse {id, due_at, interval_index, state, lapses}
    // Need to preserve knowledge_atom_id if not returned — fallback to input id
    if (data['knowledge_atom_id'] == null) {
      data = {...data, 'knowledge_atom_id': 0};
    }
    if (data['id'] == null) data['id'] = reviewId;
    return ReviewItemDto.fromJson(data);
  }

  // ── Tutor (non-streaming) ──────────────────────────────────────────────────

  /// POST /learning/tutor with {topic, question, learner_answer?, misconception?}
  /// Returns structured TutorReply. Non-streaming per AGENTS.md.
  Future<LearningTutorReplyDto> askTutor({
    required String topic,
    required String question,
    String? learnerAnswer,
    String? misconception,
    String? idempotencyKey,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/learning/tutor',
      data: {
        'topic': topic,
        'question': question,
        if (learnerAnswer != null && learnerAnswer.isNotEmpty) 'learner_answer': learnerAnswer,
        if (misconception != null && misconception.isNotEmpty) 'misconception': misconception,
      },
      options: Options(headers: _idempotencyHeader(idempotencyKey)),
    );
    final body = res.data;
    if (body == null) throw Exception('Tutor response empty');

    // Tolerant: could be {ok, reply:{...}, meta} not envelope, or envelope.
    // Try to parse via DTO which handles both.
    // First try to detect 503 control plane unavailable
    if (body['ok'] == false || (body['ok'] == null && body['success'] == false && body['reason'] == 'control_plane_unavailable')) {
      throw Exception((body['message'] as String?) ?? 'The AI tutor is temporarily unavailable. Please try again.');
    }
    // DTO will unwrap reply or data
    return LearningTutorReplyDto.fromJson(body);
  }

  /// Compatibility alias for generic prompt/history style chat if needed by legacy callers
  Future<String> askTutorLegacy(String prompt, {List<Map<String, String>>? history}) async {
    // Adapt legacy prompt to topic/question shape: use prompt as question, history ignored for core endpoint but we keep it for fallback
    final dto = await askTutor(topic: 'General', question: prompt, learnerAnswer: history?.isNotEmpty == true ? history!.last['content'] : null);
    return dto.hint.isNotEmpty ? dto.hint : dto.workedExample;
  }
}
