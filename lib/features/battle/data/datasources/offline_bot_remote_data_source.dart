import 'package:dio/dio.dart';

import '../../../../core/network/api_response.dart';
import '../../domain/offline/offline_bot_models.dart';

/// Verified server routes (`routes/api/v1/quiz.php`, quiz contract 2026.10.4):
/// - GET  /quiz/offline/bot-roster      → OfflineBotRoster
/// - POST /quiz/offline/match-receipt   → OfflineReceiptVerdict
///
/// Dio's baseUrl already ends with `/api/v1`, so paths are written relative to
/// it, exactly as the battle data source does.
///
/// Both calls are made through the authenticated Dio, so the bearer token and
/// the `X-Request-Id` logging interceptor apply. Neither route is a toggle or a
/// verb-shaped mutation: the roster is a read, and the receipt is a state
/// transition that is idempotent on the manifest id server-side.
class OfflineBotRemoteDataSource {
  const OfflineBotRemoteDataSource(this._dio);

  final Dio _dio;

  /// `data` out of the envelope, tolerating a raw body.
  ///
  /// Same defensive shape as the battle data source: a response that cannot be
  /// read yields an empty map rather than an exception, because a device must
  /// queue and retry rather than crash on an unexpected payload.
  Map<String, dynamic> _dataOrEmpty(Map<String, dynamic>? body) {
    if (body == null) return const {};
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    try {
      return ApiResponse.fromJson(
        body,
        (j) => j as Map<String, dynamic>?,
      ).data ??
          const {};
    } catch (_) {
      return const {};
    }
  }

  /// Fetch the opponents for an offline match.
  ///
  /// [size] is clamped server-side to 1..8; [questionIds] pins the pack so the
  /// receipt cannot later reference questions the server never issued. Omitting
  /// it is allowed — a device that has not chosen its pack yet can still get a
  /// roster — but then the receipt is only corroborated on the bot decisions.
  ///
  /// Returns null when the response cannot be read, which the caller treats as
  /// "try again later" rather than as "no opponents".
  Future<OfflineBotRoster?> fetchRoster({
    int? size,
    String? seed,
    List<int>? questionIds,
  }) async {
    // Built imperatively rather than with collection-if: these are all
    // conditionally *omitted*, and Dio serialises a null value as the literal
    // string "null" rather than dropping the key, so `?size: size` would send
    // size=null and the server would reject the whole request.
    final query = <String, dynamic>{};
    if (size != null) query['size'] = size;
    if (seed != null && seed.isNotEmpty) query['seed'] = seed;
    if (questionIds != null && questionIds.isNotEmpty) {
      query['question_ids'] = questionIds.map((id) => id.toString()).toList();
    }

    final response = await _dio.get<Map<String, dynamic>>(
      '/quiz/offline/bot-roster',
      queryParameters: query.isEmpty ? null : query,
    );

    final roster = OfflineBotRoster.fromJson(_dataOrEmpty(response.data));
    if (roster == null) return null;

    // An empty roster is a valid answer, not a failure: an installation with no
    // seeded bots serves none. Surface it so the UI can say so, rather than
    // pretending the request failed.
    return roster;
  }

  /// Submit a receipt for corroboration.
  ///
  /// Throws [DioException] on transport failure so the caller can queue it; the
  /// server answers 200 even for a quarantined receipt, so a rejection here is
  /// always a transport or contract problem rather than a bad report.
  Future<OfflineReceiptVerdict?> submitReceipt(
    OfflineMatchReceipt receipt,
  ) async {
    final response = await _dio.post<Map<String, dynamic>>(
      '/quiz/offline/match-receipt',
      data: receipt.toJson(),
    );

    return OfflineReceiptVerdict.fromJson(_dataOrEmpty(response.data));
  }
}
