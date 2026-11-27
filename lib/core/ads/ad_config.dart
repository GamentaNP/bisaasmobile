/// Compile-time AdMob configuration.
///
/// There are deliberately **no** ad unit IDs or app IDs in this file (or
/// anywhere else in the repository). All four values arrive through
/// `--dart-define`, so a build cannot accidentally ship somebody else's
/// AdMob account, and a build that omits them simply has ads disabled:
///
///   ADMOB_APP_ID_ANDROID
///   ADMOB_APP_ID_IOS
///   ADMOB_REWARDED_UNIT_ID_ANDROID
///   ADMOB_REWARDED_UNIT_ID_IOS
///
/// The platform guard is load-bearing: `google_mobile_ads` has no web or
/// desktop implementation, so `kIsWeb` and every `TargetPlatform` other than
/// Android/iOS produce an unsupported config. The no-op service returned by
/// `createAdRewardService` hides the entry point instead of crashing.
library;

import 'package:flutter/foundation.dart'
    show TargetPlatform, defaultTargetPlatform, kIsWeb;

abstract final class AdConfigKeys {
  static const appIdAndroid = 'ADMOB_APP_ID_ANDROID';
  static const appIdIos = 'ADMOB_APP_ID_IOS';
  static const rewardedUnitIdAndroid = 'ADMOB_REWARDED_UNIT_ID_ANDROID';
  static const rewardedUnitIdIos = 'ADMOB_REWARDED_UNIT_ID_IOS';
}

/// Resolved, immutable ad configuration for one build.
///
/// Tests construct this directly so they never depend on the compiler's
/// environment. Production uses [AdConfig.fromEnvironment].
class AdConfig {
  const AdConfig({
    required this.appId,
    required this.rewardedUnitId,
    required this.supported,
  });

  /// Reads the four `--dart-define` values for the *current* platform.
  ///
  /// `String.fromEnvironment` is a compile-time constant, so an omitted define
  /// is an empty string — never a thrown error. Unsupported platforms get an
  /// empty config even if defines were supplied, which keeps a web/desktop
  /// build free of any mobile SDK call.
  factory AdConfig.fromEnvironment() {
    if (kIsWeb)
      return const AdConfig(appId: '', rewardedUnitId: '', supported: false);

    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return AdConfig(
          appId: const String.fromEnvironment(AdConfigKeys.appIdAndroid),
          rewardedUnitId: const String.fromEnvironment(
            AdConfigKeys.rewardedUnitIdAndroid,
          ),
          supported: true,
        );
      case TargetPlatform.iOS:
        return AdConfig(
          appId: const String.fromEnvironment(AdConfigKeys.appIdIos),
          rewardedUnitId: const String.fromEnvironment(
            AdConfigKeys.rewardedUnitIdIos,
          ),
          supported: true,
        );
      // `google_mobile_ads` has no implementation on these platforms. Listing
      // them explicitly keeps the switch exhaustive without a `default`, so a
      // newly added TargetPlatform fails to compile here instead of silently
      // being treated as an ad-capable platform.
      case TargetPlatform.fuchsia:
      case TargetPlatform.linux:
      case TargetPlatform.macOS:
      case TargetPlatform.windows:
        return const AdConfig(
          appId: '',
          rewardedUnitId: '',
          supported: false,
        );
    }
  }

  /// AdMob app ID for this platform (`ca-app-pub-…~…`). Empty when missing.
  final String appId;

  /// Rewarded ad unit ID for this platform (`ca-app-pub-…/…`). Empty when missing.
  final String rewardedUnitId;

  /// False on web, desktop and any other platform without the mobile SDK.
  final bool supported;

  /// True only when both IDs were supplied for a supported platform.
  ///
  /// A missing app ID means the native manifest/plist placeholder is empty;
  /// a missing unit ID means there is nothing to load. Either one disables
  /// the service — never a crash, never an ad request.
  bool get isConfigured =>
      supported && appId.isNotEmpty && rewardedUnitId.isNotEmpty;
}
