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
final adRewardReadyProvider = FutureProvider<bool>((ref) async {
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
