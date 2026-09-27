import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../../../core/network/api_response.dart';
import '../models/lifeline_dto.dart';

/// Attempt-scoped lifeline client.
///
/// Verified server routes (`bisaas/routes/api/v1/quiz.php:229-261`,
/// `App\Http\Controllers\Api\Quiz\QuizLifelineApiController`):
///   * `GET  /quiz/attempts/{attempt}/lifelines`                 — catalogue
///   * `POST /quiz/attempts/{attempt}/lifelines/{slug}/use`     — {question_id}
///   * `POST /quiz/attempts/{attempt}/lifelines/{slug}/purchase-and-use` — {question_id}
///   * `POST /quiz/attempts/{attempt}/lifelines/{slug}/purchase` — no body
///   * `POST /quiz/attempts/{attempt}/lifelines/{slug}/ad-unlocks` — {ad_proof}
///
/// Ownership is enforced server-side (403 for someone else's attempt). Every
/// mutation carries an `Idempotency-Key` — without it the server answers 422
/// `IDEMPOTENCY_KEY_REQUIRED` — and is throttled `quiz-answer`.
///
/// The effect is built entirely by `LifelineEffectService`; this client renders
/// it and never derives one locally.
class LifelineRemoteDataSource {
  const LifelineRemoteDataSource(this._dio);

  final Dio _dio;
  static const _uuid = Uuid();

  /// Pull `data` out of the standard envelope, tolerating a raw body.
  Map<String, dynamic>? _data(Map<String, dynamic>? body) {
    if (body == null) return null;
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    try {
      final env = ApiResponse.fromJson(body, (json) => json as Map<String, dynamic>?);
      return env.data;
    } catch (_) {
      return null;
    }
  }

  /// GET /quiz/attempts/{attempt}/lifelines
  Future<LifelineCatalogueDto> getCatalogue(String attemptId) async {
    final res = await _dio.get<Map<String, dynamic>>('/quiz/attempts/$attemptId/lifelines');
    final data = _data(res.data);
    // A failed read must not look like "no lifelines available" — the caller
    // distinguishes an empty catalogue (kill switch) from an error.
    if (data == null) throw Exception('Lifeline catalogue missing from response');
    return LifelineCatalogueDto.fromJson(data);
  }

  /// POST /quiz/attempts/{attempt}/lifelines/{slug}/purchase-and-use
  ///
  /// The single call the attempt screen uses: it spends coins (or a banked
  /// token) and applies the effect in one server round-trip, which is also the
  /// only way to stay atomic if the player has no inventory.
  Future<LifelineUseResultDto> purchaseAndUse({
    required String attemptId,
    required String slug,
    required int questionId,
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? _uuid.v4();
    final res = await _dio.post<Map<String, dynamic>>(
      '/quiz/attempts/$attemptId/lifelines/$slug/purchase-and-use',
      data: {'question_id': questionId},
      options: Options(headers: {'Idempotency-Key': key}),
    );
    final data = _data(res.data);
    if (data == null) throw Exception('Lifeline response missing');
    return LifelineUseResultDto.fromJson(data);
  }

  /// POST /quiz/attempts/{attempt}/lifelines/{slug}/use — banked token only.
  Future<LifelineUseResultDto> use({
    required String attemptId,
    required String slug,
    required int questionId,
    String? idempotencyKey,
  }) async {
    final key = idempotencyKey ?? _uuid.v4();
    final res = await _dio.post<Map<String, dynamic>>(
      '/quiz/attempts/$attemptId/lifelines/$slug/use',
      data: {'question_id': questionId},
      options: Options(headers: {'Idempotency-Key': key}),
    );
    final data = _data(res.data);
    if (data == null) throw Exception('Lifeline response missing');
    return LifelineUseResultDto.fromJson(data);
  }
}
