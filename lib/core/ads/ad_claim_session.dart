/// The server-issued claim from `POST /ads/reward/initiate`.
///
/// `claimToken` is camelCase on the wire (MOBILE_API_INTEGRATION_GUIDE.md §8d)
/// and must be echoed as `claim_token` on the claim. It is *not* an ad proof
/// the client invented: a fabricated token is rejected with 422. The client
/// only holds it long enough to make the claim after a completed view.
library;

import '../network/api_failure.dart';

class AdClaimSession {
  const AdClaimSession({
    required this.claimToken,
    required this.requiredDurationSeconds,
    this.coinsExpected,
  });

  factory AdClaimSession.fromJson(Map<String, dynamic> json) {
    final token = json['claimToken'];
    if (token is! String || token.isEmpty) {
      throw const ContractViolation(
        'initiate response has no `data.claimToken`',
        endpoint: '/ads/reward/initiate',
      );
    }

    final duration = json['requiredDurationSeconds'];
    final seconds = duration is num ? duration.toInt() : 0;

    return AdClaimSession(
      claimToken: token,
      requiredDurationSeconds: seconds < 0 ? 0 : seconds,
      coinsExpected: json['coinsExpected'] is num
          ? (json['coinsExpected'] as num).toInt()
          : null,
    );
  }

  /// Server-issued, short-lived (TTL 300s) token. Never client-generated.
  final String claimToken;

  /// Minimum watch time the server will require before accepting the claim.
  /// Informational here — the SDK's reward callback is the completion signal.
  final int requiredDurationSeconds;

  /// Server's own expected amount. Never credited locally; it only describes
  /// what the server intends to award when it validates the claim.
  final int? coinsExpected;
}
