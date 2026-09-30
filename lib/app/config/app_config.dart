import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/app_update_gate.dart';
import '../../core/network/install_identity_interceptor.dart';

/// Operator configuration served by `GET /api/v1/app/config`.
///
/// This is the only public (pre-auth) endpoint that carries the maintenance
/// switch and the force-update floor, and it was never called. That mattered
/// because `feature_flags.dart` hardcoded its own defaults which **contradicted
/// the server**: the app shipped `economy_enabled: true` while the operator's
/// live config said `false`.
///
/// Observed live payload:
/// ```json
/// {"min_app_version":{"android":"1.0.0","ios":"1.0.0"},
///  "force_update":false,"maintenance":false,
///  "features":{"economy_enabled":false,"ads_enabled":false,
///              "guest_calculator_enabled":false,...}}
/// ```
@immutable
class AppConfig {
  const AppConfig({
    this.minAndroidVersion = '1.0.0',
    this.minIosVersion = '1.0.0',
    this.forceUpdate = false,
    this.maintenance = false,
    this.features = const {},
  });

  final String minAndroidVersion;
  final String minIosVersion;
  final bool forceUpdate;

  /// Operator kill-switch. When true the app is not usable, so the UI must
  /// block rather than degrade.
  final bool maintenance;

  final Map<String, bool> features;

  /// Absent keys are treated as ENABLED.
  ///
  /// Deliberate: this endpoint is additive, so a key the client does not know
  /// about yet must not silently disable a feature an operator has not turned
  /// off. The risk of defaulting to disabled is that every unrecognised flag
  /// would break the app until the client is updated; the risk of defaulting to
  /// enabled is only that a brand-new flag is not honoured until shipped.
  bool flag(String key, {bool defaultValue = true}) => features[key] ?? defaultValue;

  bool get economyEnabled => flag('economy_enabled');
  bool get adsEnabled => flag('ads_enabled');
  bool get guestCalculatorEnabled => flag('guest_calculator_enabled');
  bool get competitiveEnabled => flag('competitive_enabled');
  bool get premiumDownloadEnabled => flag('premium_download_enabled');
  bool get offlinePremiumEnabled => flag('offline_premium_enabled');

  String minVersionFor({TargetPlatform? platform}) {
    final isIos = platform == TargetPlatform.iOS;
    return isIos ? minIosVersion : minAndroidVersion;
  }

  factory AppConfig.fromJson(Map<String, dynamic> json) {
    final min = json['min_app_version'];
    final minMap = min is Map ? min : const {};
    final featuresRaw = json['features'];
    final features = <String, bool>{};
    if (featuresRaw is Map) {
      for (final entry in featuresRaw.entries) {
        // Only accept real booleans; a string "false" must not read as true.
        if (entry.value is bool) {
          features[entry.key.toString()] = entry.value as bool;
        }
      }
    }
    return AppConfig(
      minAndroidVersion: (minMap['android'] ?? '1.0.0').toString(),
      minIosVersion: (minMap['ios'] ?? '1.0.0').toString(),
      forceUpdate: json['force_update'] == true,
      maintenance: json['maintenance'] == true,
      features: features,
    );
  }
}

/// Reads `GET /app/config`.
///
/// Deliberately separate from `FeatureFlags` (Firebase Remote Config). Remote
/// Config is eventually-consistent, needs Google Play Services, and cannot be
/// read before `runApp` on a device without them — which is exactly the wrong
/// place to learn "we are in maintenance". This endpoint is public, served by
/// our own backend, and available pre-auth.
class AppConfigDataSource {
  const AppConfigDataSource(this._dio);
  final Dio _dio;

  Future<AppConfig?> fetch() async {
    final res = await _dio.get<Map<String, dynamic>>('/app/config');
    final body = res.data;
    if (body == null) return null;
    final data = body['data'];
    if (data is Map<String, dynamic>) return AppConfig.fromJson(data);
    return null;
  }
}

/// Holds the config fetched during `bootstrap()` so the provider does not
/// immediately re-request it.
///
/// The provider still fetches on its own; this only exists so that a config
/// obtained early — or injected by a test — is reused rather than re-requested.
class AppConfigCache {
  const AppConfigCache._();

  /// The most recent config seen, if any. Public so the provider can reuse it
  /// instead of issuing a second identical request.
  static AppConfig? value;

  /// Test seam.
  static void reset() => value = null;
}

/// Latches the operator's version floor into [AppUpdateGate].
///
/// Called from `appConfigProvider` as soon as a config is available, which is
/// *after* the first frame rather than before it. `AppUpdateGate` is a
/// `Listenable` and `ForceUpdateGate` listens to it, so a build below the floor
/// is still swapped out — one frame later, instead of never having painted at
/// all.
///
/// Doing this in `bootstrap()` meant a 15-second connect timeout on a bad
/// network produced a blank screen, for a 578-byte request. That is the wrong
/// trade: an hour-old maintenance switch is survivable, a blank launch is not.
void applyAppConfig(AppConfig? config) {
  if (config == null) return;
  AppConfigCache.value = config;

  final current = InstallIdentityInterceptor.defaultAppVersion();
  if (current.isEmpty) return;

  final floor = config.minVersionFor(
    platform: defaultTargetPlatform == TargetPlatform.iOS
        ? TargetPlatform.iOS
        : TargetPlatform.android,
  );
  if (!isVersionBelow(current, floor)) return;

  AppUpdateGate.instance.observe(
    ApiException(
      statusCode: 426,
      code: ApiErrorCode.upgradeRequired,
      message: 'This app version is no longer supported.',
      details: <String, dynamic>{
        'min_version': floor,
        'platform':
            defaultTargetPlatform == TargetPlatform.iOS ? 'ios' : 'android',
        'current_version': current,
      },
    ),
  );
}

/// Compares two dotted version strings.
///
/// A tolerant numeric-segment compare: a pre-release suffix is stripped, and a
/// non-numeric segment stops the comparison rather than throwing, so a malformed
/// floor cannot lock every user out.
bool isVersionBelow(String current, String minimum) {
  List<int> parse(String v) => v
      .split('-')
      .first
      .split('.')
      .map((s) => int.tryParse(s.trim()) ?? 0)
      .toList();

  // An unknown current version cannot be judged, so it is never "below". A
  // local or CI build compiled without --dart-define=APP_VERSION parses to [0]
  // and would otherwise be locked out by any raised floor. This mirrors the
  // server's own rule in EnforceAppVersion, which deliberately lets a
  // header-less or unparseable version through rather than refusing it.
  if (current.trim().isEmpty || minimum.trim().isEmpty) return false;

  final a = parse(current);
  final b = parse(minimum);
  final len = a.length > b.length ? a.length : b.length;
  for (var i = 0; i < len; i++) {
    final x = i < a.length ? a[i] : 0;
    final y = i < b.length ? b[i] : 0;
    if (x != y) return x < y;
  }
  return false;
}
