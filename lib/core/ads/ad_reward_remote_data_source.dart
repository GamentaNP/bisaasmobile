/// Server-authoritative two-step rewarded-ad flow.
///
/// ```text
/// POST /ads/reward/initiate  -> data.claimToken
/// PUT  /ads/reward/claim     {claim_token: <that token>} + Idempotency-Key
/// ```
///
/// Registered routes only (MOBILE_API_INTEGRATION_GUIDE.md §8d): `POST
/// /ads/reward/claim` does **not** exist. Coins are credited by the server's
/// verification service, never by a line of Dart code here.
///
/// Failures throw a typed [ApiException] or [ContractViolation] — an outage
/// must never be rendered as "no ad available".
library;

import 'package:dio/dio.dart';

import '../network/api_exception.dart' show ApiException;
import '../network/api_failure.dart';
import '../network/envelope.dart';
import 'ad_claim_session.dart';

class AdRewardRemoteDataSource {
  const AdRewardRemoteDataSource(this._dio);

  final Dio _dio;

  /// Starts a claim session. Call this *before* showing the ad: the server
  /// stamps its own start time and enforces the minimum watch duration from
  /// it, so a client-initiated session after the fact is a fraud signal.
  Future<AdClaimSession> initiate({
    String? rewardType,
    String? slotCode,
  }) async {
    const endpoint = '/ads/reward/initiate';
    final payload = <String, dynamic>{};
    if (rewardType != null && rewardType.isNotEmpty) {
      payload['reward_type'] = rewardType;
    }
    if (slotCode != null && slotCode.isNotEmpty) {
      payload['slot_code'] = slotCode;
    }

    final res = await _dio.post<Map<String, dynamic>>(
      endpoint,
      data: payload,
    );
    return AdClaimSession.fromJson(
      requireDataMap(res.data, endpoint: endpoint),
    );
  }

  /// Claims the reward after a completed view.
  ///
  /// [idempotencyKey] is mandatory on the wire. When omitted a fresh UUID is
  /// minted; a caller that retries a *logical* claim must pass the same key so
  /// the server replays the original ledger entry instead of crediting twice.
  Future<void> claim(
    String claimToken, {
    String? idempotencyKey,
    Map<String, dynamic>? telemetry,
  }) async {
    const endpoint = '/ads/reward/claim';
    final payload = <String, dynamic>{'claim_token': claimToken};
    if (telemetry != null) payload['telemetry'] = telemetry;

    await _dio.put<Map<String, dynamic>>(
      endpoint,
      data: payload,
      options: Options(headers: idempotencyHeader(idempotencyKey)),
    );
  }
}
