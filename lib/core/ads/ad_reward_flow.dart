/// Orchestrates the ad view and the server claim without crediting locally.
///
/// Order is load-bearing: initiate → show → SDK reward callback → claim.
/// Claiming first and showing later (or never) is exactly the fraud pattern
/// the server's verification service exists to reject.
library;

import 'ad_reward_remote_data_source.dart';
import 'ad_reward_result.dart';
import 'ad_reward_service.dart';

/// A completed view is only a success if the server accepted the claim.
class AdRewardFlowResult {
  const AdRewardFlowResult(this.outcome, {this.claimError});

  AdRewardFlowResult.rewarded() : this(AdRewardOutcome.rewarded);
  AdRewardFlowResult.failed(Object error)
      : this(AdRewardOutcome.failed, claimError: error);

  final AdRewardOutcome outcome;

  /// Set when the initiate or claim call failed. A failed claim means no coins
  /// were granted — even though the user watched a video.
  final Object? claimError;

  bool get rewarded => outcome == AdRewardOutcome.rewarded;
}

/// Thin composition of the ad service and the server endpoints.
class AdRewardFlow {
  const AdRewardFlow({required this.service, required this.remote});

  final AdRewardService service;
  final AdRewardRemoteDataSource remote;

  /// Runs one rewarded-ad session end to end.
  ///
  /// [claimIdempotencyKey] should be minted once by the caller and reused on
  /// any retry of the same session. Pass a `rewardType`/`slotCode` only when
  /// the calling screen has a server-defined value for them.
  Future<AdRewardFlowResult> run({
    String? rewardType,
    String? slotCode,
    String? claimIdempotencyKey,
  }) async {
    if (!service.isAvailable) {
      return const AdRewardFlowResult(AdRewardOutcome.unavailable);
    }

    try {
      final session = await remote.initiate(
        rewardType: rewardType,
        slotCode: slotCode,
      );

      final ad = await service.showRewardedAd();
      if (!ad.isRewarded) {
        return AdRewardFlowResult(ad.outcome, claimError: ad.error);
      }

      await remote.claim(
        session.claimToken,
        idempotencyKey: claimIdempotencyKey,
      );
    } on Object catch (error) {
      // An initiate failure, a transport error or a failed claim are all
      // "failed", never "unavailable": configuration is fine, the operation
      // was not. The error is exposed so the UI can offer a retry — with the
      // SAME claim idempotency key when the claim is what failed.
      return AdRewardFlowResult.failed(error);
    }
    return AdRewardFlowResult.rewarded();
  }
}
