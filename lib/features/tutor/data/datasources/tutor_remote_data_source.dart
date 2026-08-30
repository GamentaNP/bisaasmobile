// ignore_for_file: cast_nullable_to_non_nullable, avoid_dynamic_calls, use_null_aware_elements, dead_code, dead_null_aware_expression, unnecessary_cast, omit_local_variable_types

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/api_response.dart';
import '../models/tutor_dto.dart';
import '../../domain/entities/tutor.dart';

/// Server-verified routes (php artisan route:list --path=api/v1 in C:\laragon\www\bisaas):
/// - POST /learning/ai-tutor/onboarding/start
/// - POST /learning/ai-tutor/onboarding/complete
/// - POST /learning/ai-tutor/chat
/// - GET /learning/ai-tutor/plan
/// - GET /learning/ai-tutor/today
/// - POST /learning/ai-tutor/complete-day
/// - GET /learning/ai-tutor/weak-areas
/// - GET /learning/ai-tutor/projected-score
/// - POST /learning/ai-tutor/adjust-plan
/// - GET /learning/ai-tutor/weekly-report
/// - GET /learning/ai-tutor/revisions/due
/// - POST /learning/tutor (non-streaming, per AGENTS.md streaming is web-only)
///
/// Do NOT hardcode host, do NOT add /api/v1 twice — Dio baseUrl already has it.
class TutorRemoteDataSource {
  const TutorRemoteDataSource(this._dio);
  final Dio _dio;
  static const _uuid = Uuid();

  Map<String, String> _idempotencyHeader([String? key]) => {
        'Idempotency-Key': key ?? _uuid.v4(),
      };

  // ── Onboarding ────────────────────────────────────────────────────────────

  Future<TutorOnboardingStartDto> startOnboarding({Map<String, dynamic>? payload, String? idempotencyKey}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/learning/ai-tutor/onboarding/start',
      data: payload ?? {},
      options: Options(headers: _idempotencyHeader(idempotencyKey)),
    );
    final body = res.data;
    if (body == null) return const TutorOnboardingStartDto(sessionId: '');
    // Envelope tolerant
    Map<String, dynamic>? data;
    if (body['data'] is Map<String, dynamic>) {
      data = body['data'] as Map<String, dynamic>;
    } else {
      try {
        final env = ApiResponse.fromJson(body, (j) => j as Map<String, dynamic>?);
        data = env.data;
      } catch (_) {
        data = body;
      }
    }
    if (data == null) return const TutorOnboardingStartDto(sessionId: '');
    return TutorOnboardingStartDto.fromJson(data);
  }

  Future<TutorOnboardingCompleteDto> completeOnboarding(
    String sessionId, {
    Map<String, dynamic>? payload,
    String? idempotencyKey,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/learning/ai-tutor/onboarding/complete',
      data: {
        'session_id': sessionId,
        if (payload != null) ...payload,
      },
      options: Options(headers: _idempotencyHeader(idempotencyKey)),
    );
    final body = res.data;
    if (body == null) return const TutorOnboardingCompleteDto();
    Map<String, dynamic>? data;
    if (body['data'] is Map<String, dynamic>) {
      data = body['data'] as Map<String, dynamic>;
    } else {
      try {
        final env = ApiResponse.fromJson(body, (j) => j as Map<String, dynamic>?);
        data = env.data ?? body;
      } catch (_) {
        data = body;
      }
    }
    return TutorOnboardingCompleteDto.fromJson(data ?? {});
  }

  // ── Chat ──────────────────────────────────────────────────────────────────

  Future<TutorChatResponseDto> chat(
    String message, {
    List<Map<String, String>>? history,
    String? idempotencyKey,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/learning/ai-tutor/chat',
      data: {
        'message': message,
        'prompt': message,
        if (history != null && history.isNotEmpty) 'history': history,
      },
      options: Options(headers: _idempotencyHeader(idempotencyKey)),
    );
    final body = res.data;
    if (body == null) return const TutorChatResponseDto(answer: '');
    // Body may be envelope or direct
    Map<String, dynamic> data;
    if (body['data'] is Map<String, dynamic>) {
      data = body['data'] as Map<String, dynamic>;
    } else {
      try {
        final env = ApiResponse.fromJson(body, (j) => j as Map<String, dynamic>?);
        data = env.data ?? body;
      } catch (_) {
        data = body;
      }
    }
    // Also handle case where data is nested under 'chat' or is direct answer string
    if (data.containsKey('chat') && data['chat'] is Map<String, dynamic>) {
      data = data['chat'] as Map<String, dynamic>;
    }
    return TutorChatResponseDto.fromJson(data);
  }

  Future<String> askLegacyTutor(
    String prompt, {
    List<Map<String, String>>? history,
    String? idempotencyKey,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/learning/tutor',
      data: {
        'prompt': prompt,
        'message': prompt,
        if (history != null && history.isNotEmpty) 'history': history,
      },
      options: Options(headers: _idempotencyHeader(idempotencyKey)),
    );
    final body = res.data;
    if (body == null) return '';
    try {
      final env = ApiResponse.fromJson(body, (j) => j as Map<String, dynamic>?);
      final data = env.data ?? body['data'];
      if (data is Map) {
        return (data['answer'] ?? data['response'] ?? data['content'] ?? data['message'] ?? '').toString();
      }
      if (data is String) return data;
    } catch (_) {}
    final data = body['data'];
    if (data is Map) return (data['answer'] ?? body['answer'] ?? '').toString();
    return (body['answer'] ?? body['response'] ?? body['message'] ?? '').toString();
  }

  // ── Plan / Today ──────────────────────────────────────────────────────────

  Future<TutorPlanDto> getPlan() async {
    final res = await _dio.get<Map<String, dynamic>>('/learning/ai-tutor/plan');
    final body = res.data;
    if (body == null) return TutorPlanDto.fromJson({});
    Map<String, dynamic> data;
    if (body['data'] is Map<String, dynamic>) {
      data = body['data'] as Map<String, dynamic>;
    } else {
      try {
        final env = ApiResponse.fromJson(body, (j) => j as Map<String, dynamic>?);
        data = env.data ?? {};
      } catch (_) {
        data = {};
      }
    }
    // data may be plan directly or nested
    if (data.isEmpty) return TutorPlanDto.fromJson({});
    return TutorPlanDto.fromJson(data);
  }

  Future<TutorTodayDto> getToday() async {
    final res = await _dio.get<Map<String, dynamic>>('/learning/ai-tutor/today');
    final body = res.data;
    if (body == null) return TutorTodayDto.fromJson({'date': DateTime.now().toIso8601String()});
    Map<String, dynamic> data;
    if (body['data'] is Map<String, dynamic>) {
      data = body['data'] as Map<String, dynamic>;
    } else {
      try {
        final env = ApiResponse.fromJson(body, (j) => j as Map<String, dynamic>?);
        data = env.data ?? {};
      } catch (_) {
        data = {};
      }
    }
    if (data.isEmpty) return TutorTodayDto.fromJson({'date': DateTime.now().toIso8601String()});
    return TutorTodayDto.fromJson(data);
  }

  Future<void> completeDay({String? dayId, int? dayIndex, String? idempotencyKey}) async {
    await _dio.post<Map<String, dynamic>>(
      '/learning/ai-tutor/complete-day',
      data: {
        if (dayId != null) 'day_id': dayId,
        if (dayIndex != null) 'day_index': dayIndex,
      },
      options: Options(headers: _idempotencyHeader(idempotencyKey)),
    );
  }

  Future<void> adjustPlan(Map<String, dynamic> adjustments, {String? idempotencyKey}) async {
    await _dio.post<Map<String, dynamic>>(
      '/learning/ai-tutor/adjust-plan',
      data: adjustments,
      options: Options(headers: _idempotencyHeader(idempotencyKey)),
    );
  }

  // ── Insights ──────────────────────────────────────────────────────────────

  Future<List<WeakAreaDto>> getWeakAreas() async {
    final res = await _dio.get<Map<String, dynamic>>('/learning/ai-tutor/weak-areas');
    final body = res.data;
    if (body == null) return [];
    final data = body['data'];
    List<Map<String, dynamic>> raw = [];
    if (data is List) {
      raw = data.cast<Map<String, dynamic>>();
    } else if (data is Map<String, dynamic>) {
      if (data['weak_areas'] is List) raw = (data['weak_areas'] as List).cast<Map<String, dynamic>>();
      if (data['areas'] is List) raw = (data['areas'] as List).cast<Map<String, dynamic>>();
      if (data['items'] is List) raw = (data['items'] as List).cast<Map<String, dynamic>>();
    }
    if (raw.isEmpty) {
      try {
        final env = ApiResponse.fromJson(body, (j) {
          if (j is List) return (j as List).cast<Map<String, dynamic>>();
          if (j is Map<String, dynamic>) {
            if (j['weak_areas'] is List) return (j['weak_areas'] as List).cast<Map<String, dynamic>>();
            if (j['items'] is List) return (j['items'] as List).cast<Map<String, dynamic>>();
            if (j['areas'] is List) return (j['areas'] as List).cast<Map<String, dynamic>>();
          }
          return <Map<String, dynamic>>[];
        });
        raw = env.data ?? [];
      } catch (_) {}
    }
    return raw.map(WeakAreaDto.fromJson).toList();
  }

  Future<ProjectedScoreDto> getProjectedScore() async {
    final res = await _dio.get<Map<String, dynamic>>('/learning/ai-tutor/projected-score');
    final body = res.data;
    if (body == null) return ProjectedScoreDto.fromJson({'score': 0});
    Map<String, dynamic> data;
    if (body['data'] is Map<String, dynamic>) {
      data = body['data'] as Map<String, dynamic>;
    } else {
      try {
        final env = ApiResponse.fromJson(body, (j) => j as Map<String, dynamic>?);
        data = env.data ?? {};
      } catch (_) {
        data = {};
      }
    }
    if (data.isEmpty) return ProjectedScoreDto.fromJson({'score': 0});
    return ProjectedScoreDto.fromJson(data);
  }

  Future<WeeklyReportDto> getWeeklyReport() async {
    final res = await _dio.get<Map<String, dynamic>>('/learning/ai-tutor/weekly-report');
    final body = res.data;
    if (body == null) return WeeklyReportDto.fromJson({});
    Map<String, dynamic> data;
    if (body['data'] is Map<String, dynamic>) {
      data = body['data'] as Map<String, dynamic>;
    } else {
      try {
        final env = ApiResponse.fromJson(body, (j) => j as Map<String, dynamic>?);
        data = env.data ?? {};
      } catch (_) {
        data = {};
      }
    }
    return WeeklyReportDto.fromJson(data);
  }

  Future<List<RevisionItemDto>> getRevisionsDue() async {
    final res = await _dio.get<Map<String, dynamic>>('/learning/ai-tutor/revisions/due');
    final body = res.data;
    if (body == null) return [];
    final data = body['data'];
    List<Map<String, dynamic>> raw = [];
    if (data is List) {
      raw = data.cast<Map<String, dynamic>>();
    } else if (data is Map<String, dynamic>) {
      if (data['revisions'] is List) raw = (data['revisions'] as List).cast<Map<String, dynamic>>();
      if (data['items'] is List) raw = (data['items'] as List).cast<Map<String, dynamic>>();
      if (data['due'] is List) raw = (data['due'] as List).cast<Map<String, dynamic>>();
    }
    if (raw.isEmpty) {
      try {
        final env = ApiResponse.fromJson(body, (j) {
          if (j is List) return (j as List).cast<Map<String, dynamic>>();
          if (j is Map<String, dynamic>) {
            if (j['revisions'] is List) return (j['revisions'] as List).cast<Map<String, dynamic>>();
            if (j['items'] is List) return (j['items'] as List).cast<Map<String, dynamic>>();
          }
          return <Map<String, dynamic>>[];
        });
        raw = env.data ?? [];
      } catch (_) {}
    }
    return raw.map(RevisionItemDto.fromJson).toList();
  }

  // ── Helpers for tolerant testing ──────────────────────────────────────────

  TutorChatResult parseChatEnvelope(Map<String, dynamic> envelope) {
    final data = envelope['data'] is Map<String, dynamic>
        ? envelope['data'] as Map<String, dynamic>
        : envelope;
    return TutorChatResponseDto.fromJson(data).toDomain();
  }
}
