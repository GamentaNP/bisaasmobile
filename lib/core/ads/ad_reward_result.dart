/// Typed outcome of a rewarded ad, and the load/show seam the service uses.
///
/// A reward is only ever reported when the official SDK's
/// `onUserEarnedReward` callback fires. A dismissed ad, a load failure and a
/// missing configuration are different outcomes — collapsing them into a
/// boolean is how a UI ends up claiming coins the server never credited.
library;

import 'dart:async';

import 'package:google_mobile_ads/google_mobile_ads.dart';

/// The four outcomes a caller has to handle.
enum AdRewardOutcome {
  /// The SDK reported a completed, rewarded view. Coins are still granted by
  /// the server via the claim endpoint, never here.
  rewarded,

  /// The user closed the ad before earning the reward.
  dismissed,

  /// Loading or showing failed, or the SDK itself could not initialise.
  failed,

  /// Web/desktop, unsupported platform, or missing `--dart-define` values.
  unavailable,
}

/// A reward attempt's result. [error] is diagnostic only and must never be
/// rendered as a coin amount — the server owns the ledger.
class AdRewardResult {
  const AdRewardResult(this.outcome, {this.error});

  const AdRewardResult.rewarded() : this(AdRewardOutcome.rewarded);
  const AdRewardResult.dismissed() : this(AdRewardOutcome.dismissed);
  const AdRewardResult.unavailable() : this(AdRewardOutcome.unavailable);
  AdRewardResult.failed(Object error)
    : this(AdRewardOutcome.failed, error: error);

  final AdRewardOutcome outcome;
  final Object? error;

  bool get isRewarded => outcome == AdRewardOutcome.rewarded;

  @override
  String toString() =>
      'AdRewardResult($outcome${error == null ? '' : ': $error'})';
}

/// One loaded ad that can be shown.
///
/// The plugin's [RewardedAd] is wrapped in a zero-argument closure so unit
/// tests can inject a fake without stubbing a platform channel. The closure
/// returns the SDK's own outcome; it never decides locally that a reward was
/// earned.
typedef RewardedAdHandle = Future<AdRewardOutcome> Function();

/// Result of a load attempt: either a handle or the reason it failed.
class AdLoadResult {
  const AdLoadResult._(this.handle, this.error);

  factory AdLoadResult.success(RewardedAdHandle handle) =>
      AdLoadResult._(handle, null);

  factory AdLoadResult.failure(Object error) => AdLoadResult._(null, error);

  final RewardedAdHandle? handle;
  final Object? error;

  bool get isSuccess => handle != null;
}

/// The tiny surface the service needs from the mobile ad SDK.
abstract interface class RewardedAdGateway {
  /// Initialises the SDK. Throws on failure; the service catches it.
  Future<void> initialize();

  /// Loads a rewarded ad for [adUnitId]. Never throws for a load error —
  /// the SDK reports those through [RewardedAdLoadCallback].
  Future<AdLoadResult> load(String adUnitId);
}

/// Production gateway: the only place that touches `google_mobile_ads`.
class PluginRewardedAdGateway implements RewardedAdGateway {
  PluginRewardedAdGateway({
    MobileAds? mobileAds,
    this.loadTimeout = const Duration(seconds: 30),
  }) : _mobileAds = mobileAds ?? MobileAds.instance;

  final MobileAds _mobileAds;
  final Duration loadTimeout;

  @override
  Future<void> initialize() async {
    await _mobileAds.initialize();
  }

  @override
  Future<AdLoadResult> load(String adUnitId) async {
    final completer = Completer<AdLoadResult>();
    RewardedAd? loaded;
    Object? loadError;

    void settle() {
      if (completer.isCompleted) return;
      if (loaded != null) {
        completer.complete(
          AdLoadResult.success(() => _showPluginRewardedAd(loaded!)),
        );
      } else {
        completer.complete(
          AdLoadResult.failure(
            loadError ?? StateError('Ad load returned no ad'),
          ),
        );
      }
    }

    try {
      await RewardedAd.load(
        adUnitId: adUnitId,
        request: const AdRequest(),
        rewardedAdLoadCallback: RewardedAdLoadCallback(
          onAdLoaded: (ad) {
            loaded = ad;
            settle();
          },
          onAdFailedToLoad: (error) {
            loadError = error;
            settle();
          },
        ),
      );
    } on Object catch (error) {
      if (!completer.isCompleted)
        completer.complete(AdLoadResult.failure(error));
    }

    // `RewardedAd.load` completes when the request was *issued*, not when the
    // callback arrives. Without this guard a slow or dead network could leave
    // the caller waiting forever.
    return completer.future.timeout(
      loadTimeout,
      onTimeout: () => AdLoadResult.failure(
        TimeoutException('Rewarded ad load timed out', loadTimeout),
      ),
    );
  }
}

/// Drains one loaded [RewardedAd]'s callbacks into a single outcome.
Future<AdRewardOutcome> _showPluginRewardedAd(RewardedAd ad) async {
  final completer = Completer<AdRewardOutcome>();
  var earned = false;

  void settle(AdRewardOutcome outcome) {
    if (!completer.isCompleted) completer.complete(outcome);
  }

  ad.fullScreenContentCallback = FullScreenContentCallback<RewardedAd>(
    onAdFailedToShowFullScreenContent: (_, __) =>
        settle(AdRewardOutcome.failed),
    onAdDismissedFullScreenContent: (_) {
      // On iOS the reward callback can trail the dismissal callback by a
      // frame. Give it a moment so a completed view is not reported as a
      // dismissal (which would make the user watch for nothing).
      Future<void>.delayed(const Duration(milliseconds: 150), () {
        settle(earned ? AdRewardOutcome.rewarded : AdRewardOutcome.dismissed);
      });
    },
  );

  try {
    await ad.show(
      onUserEarnedReward: (_, __) {
        earned = true;
        settle(AdRewardOutcome.rewarded);
      },
    );
  } on Object catch (_) {
    settle(AdRewardOutcome.failed);
  }

  final outcome = await completer.future.timeout(
    const Duration(minutes: 5),
    onTimeout: () => AdRewardOutcome.failed,
  );
  await ad.dispose();
  return outcome;
}
