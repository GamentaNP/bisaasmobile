/// Remote flags — Firebase Remote Config + local fallback.
/// Mirrors server Pennant flags at `C:\laragon\www\bisaas\config\features.php` + MOBILE_API_INTEGRATION_GUIDE.md /app/config.
library;

import 'package:firebase_remote_config/firebase_remote_config.dart';

class FeatureFlags {
  FeatureFlags._(this._rc);
  final FirebaseRemoteConfig _rc;

  static FeatureFlags? _instance;
  static FeatureFlags get instance => _instance!;
  static bool get isReady => _instance != null;

  static Future<FeatureFlags> init() async {
    if (_instance != null) return _instance!;
    final rc = FirebaseRemoteConfig.instance;
    await rc.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );
    await rc.setDefaults(const {
      'economy_enabled': true,
      'ads_enabled': true,
      'guest_calculator_enabled': true,
      'social_engine_enabled': false,
      'referral_rewards_enabled': false,
      'share_creatives_enabled': false,
    });
    try {
      await rc.fetchAndActivate();
    } catch (_) {
      // offline — keep defaults, next fetch will update
    }
    _instance = FeatureFlags._(rc);
    return _instance!;
  }

  bool get economyEnabled => _rc.getBool('economy_enabled');
  bool get adsEnabled => _rc.getBool('ads_enabled');
  bool get socialEngineEnabled => _rc.getBool('social_engine_enabled');
  bool get guestCalculatorEnabled => _rc.getBool('guest_calculator_enabled');

  // Force-update gate from /api/v1/app/config (not Remote Config) — caller should compare build version vs min_app_version
  // See lib/core/network/app_config_repository.dart in future
}
