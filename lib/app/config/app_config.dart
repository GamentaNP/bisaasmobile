import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';

import '../../core/network/api_exception.dart';
import '../../core/network/api_failure.dart';
import '../../core/network/app_update_gate.dart';
import '../../core/network/envelope.dart';
import '../../core/network/install_identity_interceptor.dart';
import '../../features/ai_settings/domain/entities/ai_settings.dart';
import '../localization/l10n.dart';

/// The server's public regional-policy block (`data.country_policy`).
///
/// Published by `GET /api/v1/app/config`; the per-user version lives on
/// `/me`. Absent keys take the server's own defaults rather than throwing, because
/// this block is additive. A *present* key of the wrong type is contract drift.
@immutable
class CountryPolicyConfig {
  const CountryPolicyConfig({
    this.enabled = false,
    this.defaultCurrency = 'USD',
    this.fxEnabled = false,
  });

  final bool enabled;
  final String defaultCurrency;
  final bool fxEnabled;
}

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
///              "guest_calculator_enabled":false,...},
///  "country_policy":{"enabled":false,"default_currency":"USD","fx_enabled":false},
///  "push":{"vapid_public_key":"..."}}
/// ```
@immutable
class AppConfig {
  const AppConfig({
    this.minAndroidVersion = '1.0.0',
    this.minIosVersion = '1.0.0',
    this.forceUpdate = false,
    this.maintenance = false,
    this.features = const {},
    this.aiKeysEnabled = true,
    this.aiProviders,
    this.countryPolicy = const CountryPolicyConfig(),
    this.vapidPublicKey = '',
  });

  final String minAndroidVersion;
  final String minIosVersion;
  final bool forceUpdate;

  /// Operator kill-switch. When true the app is not usable, so the UI must
  /// block rather than degrade.
  final bool maintenance;

  final Map<String, bool> features;

  /// The operator's BYOK switch. Absent on older servers, so it defaults on.
  final bool aiKeysEnabled;

  /// The provider catalogue published by `data.ai_keys.providers`.
  ///
  /// `null` means the server did not publish a catalogue at all — which is
  /// different from publishing an empty one. Consumers fall back to the closed
  /// set of known providers only in the `null` case; a published list is
  /// authoritative, including when it introduces a provider this build has
  /// never seen.
  final List<AiProviderDescriptor>? aiProviders;

  /// The server's `data.country_policy`, with the server's own defaults when
  /// the block is absent on an older deployment.
  final CountryPolicyConfig countryPolicy;

  /// Public Web Push VAPID key, used only by browser subscribe flows. Public
  /// material: the private half never leaves the server.
  final String vapidPublicKey;

  /// Flags this build already knows and that the server has published since
  /// the first app-config release. Only these may fall back to `true` when an
  /// older server omits them.
  ///
  /// Everything else — including a brand-new operator kill switch — falls back
  /// to `false`. This is deliberately the opposite of the old rule: with
  /// "unknown means enabled", a new published `false` was honoured but a new
  /// published `true` (or a key the client forgot to model) was treated as
  /// enabled, so a freshly introduced kill switch could not disable a feature
  /// on an un-updated client. The explicit allowlist keeps the known additive
  /// flags working on old servers without re-opening that hole.
  static const knownEnabledByDefaultFlags = <String>{
    'external_api_enabled',
    'economy_enabled',
    'ads_enabled',
    'guest_calculator_enabled',
    'premium_download_enabled',
    'offline_premium_enabled',
    'competitive_enabled',
  };

  /// Reads a published flag.
  ///
  /// A published value always wins. An explicit [defaultValue] at a call site
  /// is still honoured (used by feature surfaces with their own legacy
  /// defaults). Otherwise the key is in [knownEnabledByDefaultFlags] → true,
  /// and unknown → false.
  bool flag(String key, {bool? defaultValue}) {
    final published = features[key];
    if (published != null) return published;
    if (defaultValue != null) return defaultValue;
    return knownEnabledByDefaultFlags.contains(key);
  }

  bool get externalApiEnabled => flag('external_api_enabled');
  bool get economyEnabled => flag('economy_enabled');
  bool get adsEnabled => flag('ads_enabled');

  /// Mirrors the admin `ads_earn_coins_enabled` toggle. Deliberately not in
  /// [knownEnabledByDefaultFlags]: an older server that never published this
  /// flag must not silently enable coin-earning ads.
  bool get adsRewardsEnabled => flag('ads_rewards_enabled');
  bool get guestCalculatorEnabled => flag('guest_calculator_enabled');
  bool get competitiveEnabled => flag('competitive_enabled');
  bool get premiumDownloadEnabled => flag('premium_download_enabled');
  bool get offlinePremiumEnabled => flag('offline_premium_enabled');

  /// W3.6 mobile kill switches. Deliberately NOT in the allowlist: an older
  /// server did not publish them and its own config default is off.
  bool get rewardRequiresIntegrity => flag('reward_requires_integrity');
  bool get emergencyContentProtection => flag('emergency_content_protection');

  /// Typed views of `data.country_policy`.
  bool get countryPolicyEnabled => countryPolicy.enabled;
  String get defaultCurrency => countryPolicy.defaultCurrency;
  bool get fxEnabled => countryPolicy.fxEnabled;

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

    var aiKeysEnabled = true;
    List<AiProviderDescriptor>? aiProviders;
    final aiKeysRaw = json['ai_keys'];
    if (aiKeysRaw != null && aiKeysRaw is! Map) {
      throw ContractViolation(
        'Expected `ai_keys` to be an object, got ${aiKeysRaw.runtimeType}',
        endpoint: '/app/config',
      );
    }
    if (aiKeysRaw is Map) {
      final aiKeys = aiKeysRaw.cast<String, dynamic>();
      if (aiKeys['enabled'] is bool) aiKeysEnabled = aiKeys['enabled'] as bool;
      final providersRaw = aiKeys['providers'];
      if (providersRaw != null && providersRaw is! List) {
        throw ContractViolation(
          'Expected `ai_keys.providers` to be an array, '
          'got ${providersRaw.runtimeType}',
          endpoint: '/app/config',
        );
      }
      if (providersRaw is List) {
        final parsed = <AiProviderDescriptor>[];
        for (final entry in providersRaw) {
          if (entry is! Map) {
            throw const ContractViolation(
              'Expected each ai_keys provider to be an object',
              endpoint: '/app/config',
            );
          }
          final wire = entry.cast<String, dynamic>();
          final value = wire['value'];
          final label = wire['label'];
          if (value is! String || value.isEmpty || label is! String || label.isEmpty) {
            throw const ContractViolation(
              'ai_keys provider needs non-empty string `value` and `label`',
              endpoint: '/app/config',
            );
          }
          parsed.add(
            AiProviderDescriptor(
              value: value,
              label: label,
              allowCustomEndpoint: wire['allow_custom_endpoint'] == true,
            ),
          );
        }
        aiProviders = List<AiProviderDescriptor>.unmodifiable(parsed);
      }
    }

    var countryPolicy = const CountryPolicyConfig();
    final countryRaw = json['country_policy'];
    if (countryRaw != null && countryRaw is! Map) {
      throw ContractViolation(
        'Expected `country_policy` to be an object, '
        'got ${countryRaw.runtimeType}',
        endpoint: '/app/config',
      );
    }
    if (countryRaw is Map) {
      final country = countryRaw.cast<String, dynamic>();
      final enabled = country['enabled'];
      final fxEnabled = country['fx_enabled'];
      final currency = country['default_currency'];
      if (enabled != null && enabled is! bool) {
        throw const ContractViolation(
          'country_policy.enabled must be a boolean',
          endpoint: '/app/config',
        );
      }
      if (fxEnabled != null && fxEnabled is! bool) {
        throw const ContractViolation(
          'country_policy.fx_enabled must be a boolean',
          endpoint: '/app/config',
        );
      }
      if (currency != null && currency is! String) {
        throw const ContractViolation(
          'country_policy.default_currency must be a string',
          endpoint: '/app/config',
        );
      }
      countryPolicy = CountryPolicyConfig(
        enabled: enabled == true,
        defaultCurrency: currency is String ? currency : 'USD',
        fxEnabled: fxEnabled == true,
      );
    }

    var vapidPublicKey = '';
    final pushRaw = json['push'];
    if (pushRaw != null && pushRaw is! Map) {
      throw ContractViolation(
        'Expected `push` to be an object, got ${pushRaw.runtimeType}',
        endpoint: '/app/config',
      );
    }
    if (pushRaw is Map) {
      final key = pushRaw.cast<String, dynamic>()['vapid_public_key'];
      if (key != null && key is! String) {
        throw const ContractViolation(
          'push.vapid_public_key must be a string',
          endpoint: '/app/config',
        );
      }
      vapidPublicKey = key is String ? key : '';
    }

    return AppConfig(
      minAndroidVersion: (minMap['android'] ?? '1.0.0').toString(),
      minIosVersion: (minMap['ios'] ?? '1.0.0').toString(),
      forceUpdate: json['force_update'] == true,
      maintenance: json['maintenance'] == true,
      features: features,
      aiKeysEnabled: aiKeysEnabled,
      aiProviders: aiProviders,
      countryPolicy: countryPolicy,
      vapidPublicKey: vapidPublicKey,
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

  /// Reads the operator config.
  ///
  /// A 2xx body that is not the canonical envelope is contract drift, so it
  /// throws [ContractViolation] instead of masquerading as "no config". The
  /// provider above catches that and treats it as unknown — but the failure is
  /// logged rather than silently turning every kill-switch off.
  Future<AppConfig> fetch() async {
    final res = await _dio.get<Map<String, dynamic>>('/app/config');
    return AppConfig.fromJson(
      requireDataMap(res.data, endpoint: '/app/config'),
    );
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
      message: appL10n().versionUnsupported,
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
