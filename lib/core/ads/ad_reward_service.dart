/// AdMob rewarded-video service.
///
/// The service is deliberately tiny: it initialises the SDK, loads one ad and
/// reports the SDK's own reward callback as a typed [AdRewardResult]. It never
/// mints coins, never writes to the wallet and never guesses that a view was
/// completed — the server's claim endpoint is the only ledger.
library;

import '../logging/app_logger.dart';
import 'ad_config.dart';
import 'ad_reward_result.dart';

/// The API feature screens consume. There is no `bool didWatchAd` shortcut:
/// a `dismissed`, `failed` or `unavailable` result must reach the UI unchanged.
abstract interface class AdRewardService {
  /// Initialises the SDK. Safe to call more than once. Never throws — a
  /// failure leaves [isAvailable] false so the entry point can be hidden.
  Future<void> initialize();

  /// True only after a successful initialisation on a supported platform with
  /// both IDs supplied via `--dart-define`.
  bool get isAvailable;

  /// Loads and shows one rewarded ad.
  Future<AdRewardResult> showRewardedAd();
}

/// Web, desktop, and builds without ad defines.
class NoOpAdRewardService implements AdRewardService {
  const NoOpAdRewardService();

  @override
  Future<void> initialize() async {}

  @override
  bool get isAvailable => false;

  @override
  Future<AdRewardResult> showRewardedAd() async =>
      const AdRewardResult.unavailable();
}

/// Android/iOS implementation.
class MobileAdRewardService implements AdRewardService {
  MobileAdRewardService({
    AdConfig? config,
    RewardedAdGateway? gateway,
    this.onError = _defaultOnError,
  }) : _config = config ?? AdConfig.fromEnvironment(),
       _gateway = gateway ?? PluginRewardedAdGateway();

  final AdConfig _config;
  final RewardedAdGateway _gateway;

  /// Injected so tests can stay quiet; production logs a warning.
  final void Function(String message, Object error) onError;

  static void _defaultOnError(String message, Object error) {
    AppLogger.w('$message: $error');
  }

  Future<void>? _initializing;
  bool _initialized = false;

  @override
  Future<void> initialize() {
    if (!_config.isConfigured) return Future<void>.value();

    // One init per service instance even when several screens ask at once.
    return _initializing ??= _doInitialize();
  }

  Future<void> _doInitialize() async {
    try {
      await _gateway.initialize();
      _initialized = true;
    } on Object catch (error) {
      onError('AdMob initialisation failed', error);
      _initialized = false;
    }
  }

  @override
  bool get isAvailable => _initialized && _config.isConfigured;

  @override
  Future<AdRewardResult> showRewardedAd() async {
    if (!isAvailable) return const AdRewardResult.unavailable();

    final AdLoadResult loaded;
    try {
      loaded = await _gateway.load(_config.rewardedUnitId);
    } on Object catch (error) {
      return AdRewardResult.failed(error);
    }
    if (loaded.handle == null) {
      return AdRewardResult.failed(
        loaded.error ?? StateError('Rewarded ad could not be loaded'),
      );
    }

    try {
      return AdRewardResult(await loaded.handle!());
    } on Object catch (error) {
      return AdRewardResult.failed(error);
    }
  }
}

/// Picks the implementation from compile-time configuration and platform.
///
/// [config] and [gateway] are injectable for tests; production uses the
/// environment config and the real plugin gateway.
AdRewardService createAdRewardService({
  AdConfig? config,
  RewardedAdGateway? gateway,
}) {
  final resolved = config ?? AdConfig.fromEnvironment();
  if (!resolved.isConfigured) return const NoOpAdRewardService();
  return MobileAdRewardService(config: resolved, gateway: gateway);
}
