// ignore_for_file: use_null_aware_elements
import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../app/localization/l10n.dart';
import '../../../../core/network/api_failure.dart';
import '../../../../core/network/envelope.dart';
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

  /// Reads a collection endpoint's rows. The server publishes either a bare
  /// `data` list or a named list inside `data`; anything else is contract
  /// drift and throws, so an unreadable body can never render as "0 rows".
  List<Map<String, dynamic>> _rows(
    Map<String, dynamic>? body,
    String endpoint,
    List<String> keys,
  ) {
    if (body == null) {
      throw ContractViolation('Empty response body', endpoint: endpoint);
    }
    final data = body['data'];
    if (data is List) return data.whereType<Map<String, dynamic>>().toList();
    if (data is Map<String, dynamic>) {
      for (final key in keys) {
        final nested = data[key];
        if (nested is List) {
          return nested.whereType<Map<String, dynamic>>().toList();
        }
      }
    }
    throw ContractViolation(
      'Expected a list under `data`, got ${data.runtimeType}',
      endpoint: endpoint,
    );
  }

  // ── Tracks ──────────────────────────────────────────────────────────────────

  Future<List<LearningTrackDto>> getTracks() async {
    const endpoint = '/learning/tracks';
    final res = await _dio.get<Map<String, dynamic>>(endpoint);
    return _rows(res.data, endpoint, const ['tracks', 'data', 'items'])
        .map(LearningTrackDto.fromJson)
        .toList();
  }

  // ── Goals ───────────────────────────────────────────────────────────────────

  Future<List<LearningGoalDto>> getGoals() async {
    const endpoint = '/learning/goals';
    final res = await _dio.get<Map<String, dynamic>>(endpoint);
    return _rows(res.data, endpoint, const ['goals', 'items', 'data'])
        .map(LearningGoalDto.fromJson)
        .toList();
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
    if (body == null) {
      throw const ContractViolation(
        'Empty response body',
        endpoint: '/learning/goals',
      );
    }
    return LearningGoalDto.fromJson(
      requireDataMap(body, endpoint: '/learning/goals'),
    );
  }

  Future<LearningGoalDto> getGoal(int goalId) async {
    final endpoint = '/learning/goals/$goalId';
    final res = await _dio.get<Map<String, dynamic>>(endpoint);
    final body = res.data;
    if (body == null) {
      throw ContractViolation('Empty response body', endpoint: endpoint);
    }
    return LearningGoalDto.fromJson(requireDataMap(body, endpoint: endpoint));
  }

  Future<LearningGoalReadinessDto> getGoalReadiness(int goalId) async {
    final res = await _dio.get<Map<String, dynamic>>('/learning/goals/$goalId/readiness');
    final endpoint = '/learning/goals/$goalId/readiness';
    final body = res.data;
    if (body == null) {
      throw ContractViolation('Empty response body', endpoint: endpoint);
    }
    return LearningGoalReadinessDto.fromJson(
      requireDataMap(body, endpoint: endpoint),
    );
  }

  Future<void> deleteGoal(int goalId) async {
    await _dio.delete<Map<String, dynamic>>('/learning/goals/$goalId');
  }

  // ── Today ───────────────────────────────────────────────────────────────────

  Future<DailyPlanDto?> getToday() async {
    final res = await _dio.get<Map<String, dynamic>>('/learning/today');
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty response body',
        endpoint: '/learning/today',
      );
    }
    // The controller returns success(data:null) when there is no active goal —
    // that is a real answer, not a failure.
    if (body['data'] == null) return null;
    final data = requireDataMap(body, endpoint: '/learning/today');
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
    final endpoint = '/learning/today/$planId/complete-item';
    final body = res.data;
    if (body == null) {
      throw ContractViolation('Empty response body', endpoint: endpoint);
    }
    return DailyPlanDto.fromJson(requireDataMap(body, endpoint: endpoint));
  }

  // ── Reviews (Spaced Repetition) ────────────────────────────────────────────

  Future<List<ReviewItemDto>> getReviewsDue() async {
    const endpoint = '/learning/reviews/due';
    final res = await _dio.get<Map<String, dynamic>>(endpoint);
    return _rows(res.data, endpoint, const ['reviews', 'items', 'data'])
        .map(ReviewItemDto.fromJson)
        .toList();
  }

  /// Grade a review — outcome one of again|hard|good|easy (FSRS). Uses Idempotency-Key.
  Future<ReviewItemDto> gradeReview(int reviewId, String outcome, {String? idempotencyKey}) async {
    // Canonical verb is PUT (routes/api/v1/learning.php:46); the POST form is
    // the additive alias at :49 and goes away at the grammar freeze.
    final res = await _dio.put<Map<String, dynamic>>(
      '/learning/reviews/$reviewId/grade',
      data: {'outcome': outcome},
      options: Options(headers: _idempotencyHeader(idempotencyKey)),
    );
    final endpoint = '/learning/reviews/$reviewId/grade';
    final body = res.data;
    if (body == null) {
      throw ContractViolation('Empty response body', endpoint: endpoint);
    }
    final payload = requireDataMap(body, endpoint: endpoint);
    // Grade response shape is sparse {id, due_at, interval_index, state, lapses}
    // Need to preserve knowledge_atom_id if not returned — fallback to input id
    var data = payload;
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
      throw Exception((body['message'] as String?) ?? appL10n().errFeatureDisabled);
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
