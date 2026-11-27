/// Riverpod seam for rewarded ads.
///
/// A feature screen asks for [adRewardFlowProvider], watches
/// [adRewardReadyProvider] to decide whether the entry point should exist at
/// all, and never constructs an SDK object itself. Overriding the service or
/// the gateway in a test is therefore a one-line provider override.
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import 'ad_config.dart';
import 'ad_reward_flow.dart';
import 'ad_reward_remote_data_source.dart';
import 'ad_reward_service.dart';

final adConfigProvider = Provider<AdConfig>((_) => AdConfig.fromEnvironment());

final adRewardServiceProvider = Provider<AdRewardService>((ref) {
  return createAdRewardService(config: ref.watch(adConfigProvider));
});

/// Initialises the SDK once and exposes availability.
///
/// `false` means "hide the watch-to-earn entry point", never "show an error":
/// web, desktop and builds without the four dart-defines all land here.
/// The operator's runtime gates. Both are published by `/api/v1/app/config`
/// and can be flipped in Filament without shipping a new build.
///
/// `ads_enabled` is the general ad switch; `ads_rewards_enabled` mirrors the
/// EconomySettings toggle that actually credits coins. A screen must require
/// both, plus SDK availability, before it offers "watch to earn".
final adEntryEnabledProvider = Provider<bool>((ref) {
  final app = ref.watch(appConfigValueProvider);
  if (app == null) return false;
  return app.adsEnabled && app.adsRewardsEnabled;
});

final adRewardReadyProvider = FutureProvider<bool>((ref) async {
  if (!ref.watch(adEntryEnabledProvider)) return false;
  final service = ref.watch(adRewardServiceProvider);
  await service.initialize();
  return service.isAvailable;
});

final adRewardRemoteProvider = Provider<AdRewardRemoteDataSource>((ref) {
  return AdRewardRemoteDataSource(ref.watch(dioProvider));
});

final adRewardFlowProvider = Provider<AdRewardFlow>((ref) {
  return AdRewardFlow(
    service: ref.watch(adRewardServiceProvider),
    remote: ref.watch(adRewardRemoteProvider),
  );
});
