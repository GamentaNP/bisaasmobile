import 'package:bisaasmobile/core/ads/ad_config.dart';
import 'package:bisaasmobile/core/ads/ad_reward_result.dart';
import 'package:bisaasmobile/core/ads/ad_reward_service.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('AdConfig', () {
    test('isConfigured requires both IDs and a supported platform', () {
      expect(
        const AdConfig(appId: 'ca-app-pub-1~2', rewardedUnitId: 'ca-app-pub-1/2', supported: true).isConfigured,
        isTrue,
      );
      expect(
        const AdConfig(appId: '', rewardedUnitId: 'ca-app-pub-1/2', supported: true).isConfigured,
        isFalse,
      );
      expect(
        const AdConfig(appId: 'ca-app-pub-1~2', rewardedUnitId: '', supported: true).isConfigured,
        isFalse,
      );
      expect(
        const AdConfig(appId: 'ca-app-pub-1~2', rewardedUnitId: 'ca-app-pub-1/2', supported: false).isConfigured,
        isFalse,
      );
    });

    test('missing defines produce a no-op service that never requests an ad', () async {
      final service = createAdRewardService(
        config: const AdConfig(appId: '', rewardedUnitId: '', supported: true),
      );
      expect(service, isA<NoOpAdRewardService>());
      await service.initialize();
      expect(service.isAvailable, isFalse);
      final result = await service.showRewardedAd();
      expect(result.outcome, AdRewardOutcome.unavailable);
    });

    test('unsupported platforms produce a no-op service even with IDs', () async {
      final service = createAdRewardService(
        config: const AdConfig(
          appId: 'ca-app-pub-1~2',
          rewardedUnitId: 'ca-app-pub-1/2',
          supported: false,
        ),
      );
      expect(service, isA<NoOpAdRewardService>());
      expect(service.isAvailable, isFalse);
      expect((await service.showRewardedAd()).outcome, AdRewardOutcome.unavailable);
    });
  });
}
