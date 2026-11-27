import 'package:bisaasmobile/core/ads/ad_config.dart';
import 'package:bisaasmobile/core/ads/ad_reward_result.dart';
import 'package:bisaasmobile/core/ads/ad_reward_service.dart';
import 'package:flutter_test/flutter_test.dart';

const _config = AdConfig(
  appId: 'ca-app-pub-1111111111111111~2222222222',
  rewardedUnitId: 'ca-app-pub-1111111111111111/3333333333',
  supported: true,
);

/// A fake SDK view: the handle is a closure returning the SDK's own outcome.
RewardedAdHandle _fakeHandle(AdRewardOutcome outcome) =>
    () async => outcome;

class _FakeGateway implements RewardedAdGateway {
  _FakeGateway({this.initThrows = false, AdLoadResult? loadResult})
    : _loadResult =
          loadResult ??
          AdLoadResult.success(_fakeHandle(AdRewardOutcome.rewarded));

  final bool initThrows;
  final AdLoadResult _loadResult;
  int initCalls = 0;
  int loadCalls = 0;
  String? loadedUnitId;

  @override
  Future<void> initialize() async {
    initCalls++;
    if (initThrows) throw StateError('native init failed');
  }

  @override
  Future<AdLoadResult> load(String adUnitId) async {
    loadCalls++;
    loadedUnitId = adUnitId;
    return _loadResult;
  }
}

void main() {
  test('initialize is idempotent and enables the service on success', () async {
    final gateway = _FakeGateway();
    final service = MobileAdRewardService(
      config: _config,
      gateway: gateway,
      onError: (_, __) {},
    );

    expect(service.isAvailable, isFalse);
    await service.initialize();
    await service.initialize();
    expect(gateway.initCalls, 1);
    expect(service.isAvailable, isTrue);
  });

  test(
    'SDK reward callback maps to rewarded and uses the configured unit id',
    () async {
      final gateway = _FakeGateway();
      final service = MobileAdRewardService(
        config: _config,
        gateway: gateway,
        onError: (_, __) {},
      );
      await service.initialize();

      final result = await service.showRewardedAd();
      expect(result.outcome, AdRewardOutcome.rewarded);
      expect(result.isRewarded, isTrue);
      expect(gateway.loadedUnitId, _config.rewardedUnitId);
    },
  );

  test(
    'dismissal and load failure are distinct, neither is a reward',
    () async {
      final dismissed = _FakeGateway(
        loadResult: AdLoadResult.success(
          _fakeHandle(AdRewardOutcome.dismissed),
        ),
      );
      final dismissedService = MobileAdRewardService(
        config: _config,
        gateway: dismissed,
        onError: (_, __) {},
      );
      await dismissedService.initialize();
      expect(
        (await dismissedService.showRewardedAd()).outcome,
        AdRewardOutcome.dismissed,
      );

      final failing = _FakeGateway(
        loadResult: AdLoadResult.failure(StateError('no fill')),
      );
      final failingService = MobileAdRewardService(
        config: _config,
        gateway: failing,
        onError: (_, __) {},
      );
      await failingService.initialize();
      final failed = await failingService.showRewardedAd();
      expect(failed.outcome, AdRewardOutcome.failed);
      expect(failed.error, isA<StateError>());
    },
  );

  test('native init failure disables the service without throwing', () async {
    final errors = <String>[];
    final service = MobileAdRewardService(
      config: _config,
      gateway: _FakeGateway(initThrows: true),
      onError: (message, _) => errors.add(message),
    );

    await service.initialize();
    expect(service.isAvailable, isFalse);
    expect(errors, isNotEmpty);
    expect(
      (await service.showRewardedAd()).outcome,
      AdRewardOutcome.unavailable,
    );
  });

  test('showing before initialize is unavailable, not a crash', () async {
    final gateway = _FakeGateway();
    final service = MobileAdRewardService(
      config: _config,
      gateway: gateway,
      onError: (_, __) {},
    );

    expect(
      (await service.showRewardedAd()).outcome,
      AdRewardOutcome.unavailable,
    );
    expect(gateway.loadCalls, 0);
  });
}
