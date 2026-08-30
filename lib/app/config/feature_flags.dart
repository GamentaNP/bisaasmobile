/// Remote flags — Firebase Remote Config + local fallback.
/// Mirrors server Pennant flags at `C:\laragon\www\bisaas\config\features.php` + MOBILE_API_INTEGRATION_GUIDE.md /app/config.
library;

import 'package:firebase_remote_config/firebase_remote_config.dart';

class FeatureFlags {
  FeatureFlags._(this._rc);
  final FirebaseRemoteConfig _rc;

  static FeatureFlags? _instance;
  static bool get isReady => _instance != null;

  /// Defaults when Remote Config is unavailable (no Firebase, offline first run).
  static const Map<String, bool> defaults = {
    'economy_enabled': true,
    'ads_enabled': true,
    'guest_calculator_enabled': true,
    'social_engine_enabled': false,
    'referral_rewards_enabled': false,
    'share_creatives_enabled': false,
  };

  static Future<void> init() async {
    if (_instance != null) return;
    final rc = FirebaseRemoteConfig.instance;
    await rc.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 10),
        minimumFetchInterval: const Duration(hours: 1),
      ),
    );
    await rc.setDefaults(defaults);
    try {
      await rc.fetchAndActivate();
    } catch (_) {
      // offline — keep defaults, next fetch will update
    }
    _instance = FeatureFlags._(rc);
  }

  /// Safe read — falls back to defaults when Remote Config was never
  /// initialized (dev without Firebase) or the key fetch throws.
  bool _flag(String key) {
    final inst = _instance;
    if (inst == null) return defaults[key] ?? false;
    try {
      return inst._rc.getBool(key);
    } catch (_) {
      return defaults[key] ?? false;
    }
  }

  bool get economyEnabled => _flag('economy_enabled');
  bool get adsEnabled => _flag('ads_enabled');
  bool get socialEngineEnabled => _flag('social_engine_enabled');
  bool get guestCalculatorEnabled => _flag('guest_calculator_enabled');

  // Force-update gate from /api/v1/app/config (not Remote Config) — caller should compare build version vs min_app_version
  // See lib/core/network/app_config_repository.dart in future
}
