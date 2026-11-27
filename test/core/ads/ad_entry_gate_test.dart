/// The admin can switch rewarded ads off without shipping a new build.
///
/// Two server flags are required: the general ad switch and the EconomySettings
/// toggle that actually credits coins. SDK availability is a third, independent
/// gate handled by `adRewardReadyProvider`.
library;

import 'package:bisaasmobile/app/config/app_config.dart';
import 'package:bisaasmobile/app/providers.dart';
import 'package:bisaasmobile/core/ads/ads_providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  bool gated(Map<String, bool> features) {
    final container = ProviderContainer(overrides: [
      appConfigValueProvider.overrideWithValue(AppConfig(features: features)),
    ]);
    addTearDown(container.dispose);
    return container.read(adEntryEnabledProvider);
  }

  test('both server switches on', () {
    expect(
      gated(<String, bool>{'ads_enabled': true, 'ads_rewards_enabled': true}),
      isTrue,
    );
  });

  test('general ads on but coin rewards off', () {
    expect(
      gated(<String, bool>{'ads_enabled': true, 'ads_rewards_enabled': false}),
      isFalse,
    );
  });

  test('coin rewards on but general ads off', () {
    expect(
      gated(<String, bool>{'ads_enabled': false, 'ads_rewards_enabled': true}),
      isFalse,
    );
  });

  test('no config yet means no ads', () {
    final container = ProviderContainer(overrides: [
      appConfigValueProvider.overrideWithValue(null),
    ]);
    addTearDown(container.dispose);
    expect(container.read(adEntryEnabledProvider), isFalse);
  });
}
