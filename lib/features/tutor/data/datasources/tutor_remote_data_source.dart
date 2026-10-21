import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/api_failure.dart';
import '../../../../core/network/api_response.dart';
import '../models/tutor_dto.dart';

/// Tutor surfaces — `routes/api/v1/learning.php`.
///
/// The chat posts to **`POST /learning/tutor`**, not
/// `POST /learning/ai-tutor/chat`.
///
/// The reason is not cosmetic: `/learning/tutor` is the only mobile-reachable
/// route the server records in `ai_invocations`, and the nightly rollup that
/// feeds `GET /me/ai-usage` reads from. The `/learning/ai-tutor/*` family
/// answers with the same content but never reaches the usage ledger, so
/// "Your AI usage" showed zero requests no matter how much the user had
/// chatted. Asking the endpoint that is actually recorded is what makes the
/// user's own usage page meaningful.
///
/// `/learning/tutor` validates `topic` and `question`; the topic is the
/// subject the user is studying, and the question is their message.
class TutorRemoteDataSource {
  const TutorRemoteDataSource(this._dio);
  final Dio _dio;
  static const _uuid = Uuid();

  Map<String, String> _idempotencyHeader([String? key]) =>
      {'Idempotency-Key': key ?? _uuid.v4()};

  /// Reads the `data` object out of an envelope.
  ///
  /// Returns null **only** when the server published no payload at all
  /// (`data: null`) — a real "there is no plan". A body the client cannot
  /// read is drift and throws, so it can never be rendered as an empty
  /// study plan.
  Map<String, dynamic>? _data(Map<String, dynamic>? body, String endpoint) {
    if (body == null) {
      throw ContractViolation('Empty response body', endpoint: endpoint);
    }
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    if (data == null && body.containsKey('data')) return null;
    try {
      final env = ApiResponse.fromJson(body, (j) => j as Map<String, dynamic>?);
      final parsed = env.data;
      if (parsed != null) return parsed;
    } on Object {
      // Fall through to the contract violation below.
    }
    throw ContractViolation(
      'Tutor payload not understood: expected `data` to be an object',
      endpoint: endpoint,
    );
  }

  // ── Onboarding ─────────────────────────────────────────────────────────────

  Future<TutorOnboardingStartDto> startOnboarding({
    Map<String, dynamic>? payload,
    String? idempotencyKey,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/learning/ai-tutor/onboarding/start',
      data: payload ?? const {},
      options: Options(headers: _idempotencyHeader(idempotencyKey)),
    );
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty response body',
        endpoint: '/learning/ai-tutor/onboarding/start',
      );
    }
    Map<String, dynamic> data;
    if (body['data'] is Map<String, dynamic>) {
      data = body['data'] as Map<String, dynamic>;
    } else {
      data = _data(body, '/learning/ai-tutor/onboarding/start') ?? const {};
    }
    return TutorOnboardingStartDto.fromJson(data);
  }

  Future<TutorOnboardingCompleteDto> completeOnboarding({
    required String sessionId,
    Map<String, dynamic>? payload,
    String? idempotencyKey,
  }) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/learning/ai-tutor/onboarding/complete',
      data: {'session_id': sessionId, ...?payload},
      options: Options(headers: _idempotencyHeader(idempotencyKey)),
    );
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty response body',
        endpoint: '/learning/ai-tutor/onboarding/complete',
      );
    }
    final data = _data(body, '/learning/ai-tutor/onboarding/complete') ?? const {};
    return TutorOnboardingCompleteDto.fromJson(data);
  }

  // ── Chat ──────────────────────────────────────────────────────────────────

  /// Asks the tutor a question.
  ///
  /// `POST /learning/tutor {topic, question, learner_answer?}` — the route
  /// the server records in the AI usage ledger.
  Future<TutorChatResponseDto> chat(
    String message, {
    String topic = 'General',
    List<Map<String, String>>? history,
    String? idempotencyKey,
  }) async {
    // The learner's own previous answer is the "learner answer" the endpoint
    // wants when it is tutoring a specific misconception.
    final learnerAnswer = _lastUserMessage(history);

    final res = await _dio.post<Map<String, dynamic>>(
      '/learning/tutor',
      data: <String, dynamic>{
        'topic': topic,
        'question': message,
        'learner_answer': ?learnerAnswer,
      },
      options: Options(headers: _idempotencyHeader(idempotencyKey)),
    );
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty response body',
        endpoint: '/learning/tutor',
      );
    }
    // The body may be an envelope, a direct payload, or nest the reply under
    // `reply` / `chat`.
    Map<String, dynamic> data;
    if (body['data'] is Map<String, dynamic>) {
      data = body['data'] as Map<String, dynamic>;
    } else {
      data = _data(body, '/learning/tutor') ?? const {};
    }
    for (final key in const ['reply', 'chat', 'tutor']) {
      final nested = data[key];
      if (nested is Map<String, dynamic>) {
        data = nested;
        break;
      }
    }
    return TutorChatResponseDto.fromJson(data);
  }

  /// The most recent user message in the history, if any.
  static String? _lastUserMessage(List<Map<String, String>>? history) {
    if (history == null || history.isEmpty) return null;
    for (final entry in history.reversed) {
      final role = entry['role'];
      final content = entry['content'];
      if (role == 'user' && content != null && content.trim().isNotEmpty) {
        return content.trim();
      }
    }
    return null;
  }

  // ── Plan / Today ──────────────────────────────────────────────────────────

  Future<TutorPlanDto> getPlan() async {
    final res = await _dio.get<Map<String, dynamic>>('/learning/ai-tutor/plan');
    final data = _data(res.data, '/learning/ai-tutor/plan');
    // No plan yet is a real answer, not a failure.
    if (data == null || data.isEmpty) return TutorPlanDto.fromJson(const {});
    return TutorPlanDto.fromJson(data);
  }

  Future<TutorTodayDto> getToday() async {
    final res = await _dio.get<Map<String, dynamic>>('/learning/ai-tutor/today');
    final data = _data(res.data, '/learning/ai-tutor/today');
    if (data == null || data.isEmpty) {
      return TutorTodayDto.fromJson({'date': DateTime.now().toIso8601String()});
    }
    return TutorTodayDto.fromJson(data);
  }

  Future<void> completeDay({String? dayId, int? dayIndex, String? idempotencyKey}) async {
    await _dio.post<Map<String, dynamic>>(
      '/learning/ai-tutor/complete-day',
      data: <String, dynamic>{
        'day_id': ?dayId,
        'day_index': ?dayIndex,
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

  /// `GET /learning/ai-tutor/weak-areas`
  ///
  /// The real response nests the list one level deeper than this parser
  /// previously looked (verified live 2026-09-27):
  ///   `{data: {report: {weak_areas: [...], suggested_actions: [...]}}}`
  /// The old code only checked `data.weak_areas` / `data.areas` / `data.items`,
  /// so it always returned an empty list — which is why the UI had "weak
  /// topics" hardcoded next to it. `report` is checked first, then the flatter
  /// shapes, so both old and new envelopes work.
  Future<List<WeakAreaDto>> getWeakAreas() async {
    final res = await _dio.get<Map<String, dynamic>>('/learning/ai-tutor/weak-areas');
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty response body',
        endpoint: '/learning/ai-tutor/weak-areas',
      );
    }

    List<Map<String, dynamic>>? fromMap(Map<String, dynamic> map) {
      for (final key in const ['weak_areas', 'areas', 'items']) {
        final value = map[key];
        if (value is List) return value.cast<Map<String, dynamic>>();
      }
      // Nested report envelope.
      final report = map['report'];
      if (report is Map<String, dynamic>) return fromMap(report);
      return null;
    }

    final data = body['data'];
    if (data is List) {
      return data.cast<Map<String, dynamic>>().map(WeakAreaDto.fromJson).toList();
    }
    if (data is Map<String, dynamic>) {
      final raw = fromMap(data);
      // A payload with no list at all is a shape we do not understand; one
      // with an empty list is the server saying "no weak areas".
      if (raw != null) {
        return raw.map(WeakAreaDto.fromJson).toList();
      }
      throw const ContractViolation(
        'Weak-areas payload not understood',
        endpoint: '/learning/ai-tutor/weak-areas',
      );
    }
    throw const ContractViolation(
      'Weak-areas payload not understood',
      endpoint: '/learning/ai-tutor/weak-areas',
    );
  }

  Future<ProjectedScoreDto> getProjectedScore() async {
    final res = await _dio.get<Map<String, dynamic>>('/learning/ai-tutor/projected-score');
    final data = _data(res.data, '/learning/ai-tutor/projected-score');
    if (data == null || data.isEmpty) {
      // No projection yet is a real answer.
      return ProjectedScoreDto.fromJson(const {'score': 0});
    }
    return ProjectedScoreDto.fromJson(data);
  }

  Future<WeeklyReportDto> getWeeklyReport() async {
    final res = await _dio.get<Map<String, dynamic>>('/learning/ai-tutor/weekly-report');
    final data = _data(res.data, '/learning/ai-tutor/weekly-report') ?? const {};
    return WeeklyReportDto.fromJson(data);
  }

  Future<List<RevisionItemDto>> getRevisionsDue() async {
    final res = await _dio.get<Map<String, dynamic>>('/learning/ai-tutor/revisions/due');
    final body = res.data;
    if (body == null) {
      throw const ContractViolation(
        'Empty response body',
        endpoint: '/learning/ai-tutor/revisions/due',
      );
    }
    final data = body['data'];
    if (data is List) {
      return data.cast<Map<String, dynamic>>().map(RevisionItemDto.fromJson).toList();
    }
    if (data is Map<String, dynamic>) {
      for (final key in const ['revisions', 'items', 'due']) {
        final value = data[key];
        if (value is List) {
          return value.cast<Map<String, dynamic>>().map(RevisionItemDto.fromJson).toList();
        }
      }
      throw const ContractViolation(
        'Revisions payload not understood',
        endpoint: '/learning/ai-tutor/revisions/due',
      );
    }
    throw const ContractViolation(
      'Revisions payload not understood',
      endpoint: '/learning/ai-tutor/revisions/due',
    );
  }
}
