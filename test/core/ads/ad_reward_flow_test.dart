import 'package:bisaasmobile/core/ads/ad_claim_session.dart';
import 'package:bisaasmobile/core/ads/ad_reward_flow.dart';
import 'package:bisaasmobile/core/ads/ad_reward_remote_data_source.dart';
import 'package:bisaasmobile/core/ads/ad_reward_result.dart';
import 'package:bisaasmobile/core/ads/ad_reward_service.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeService implements AdRewardService {
  _FakeService({
    this.available = true,
    this.result = const AdRewardResult.rewarded(),
  });

  final bool available;
  final AdRewardResult result;
  int showCalls = 0;

  @override
  Future<void> initialize() async {}

  @override
  bool get isAvailable => available;

  @override
  Future<AdRewardResult> showRewardedAd() async {
    showCalls++;
    return result;
  }
}

class _FakeRemote extends AdRewardRemoteDataSource {
  _FakeRemote() : super(Dio());

  final List<String> calls = <String>[];
  AdClaimSession session = const AdClaimSession(
    claimToken: 'server-token',
    requiredDurationSeconds: 10,
  );
  Error? initiateError;
  Error? claimError;
  String? claimedToken;
  String? claimKey;

  @override
  Future<AdClaimSession> initiate({
    String? rewardType,
    String? slotCode,
  }) async {
    calls.add('initiate');
    if (initiateError != null) throw initiateError!;
    return session;
  }

  @override
  Future<void> claim(
    String claimToken, {
    String? idempotencyKey,
    Map<String, dynamic>? telemetry,
  }) async {
    calls.add('claim');
    claimedToken = claimToken;
    claimKey = idempotencyKey;
    if (claimError != null) throw claimError!;
  }
}

void main() {
  test('unavailable ads never initiate or show', () async {
    final service = _FakeService(available: false);
    final remote = _FakeRemote();
    final result = await AdRewardFlow(service: service, remote: remote).run();

    expect(result.outcome, AdRewardOutcome.unavailable);
    expect(remote.calls, isEmpty);
    expect(service.showCalls, 0);
  });

  test('successful view claims the server token with the caller key', () async {
    final service = _FakeService();
    final remote = _FakeRemote();
    final result = await AdRewardFlow(service: service, remote: remote).run(
      rewardType: 'quiz_reward',
      claimIdempotencyKey: 'one-logical-operation',
    );

    expect(result.rewarded, isTrue);
    expect(remote.calls, ['initiate', 'claim']);
    expect(remote.claimedToken, 'server-token');
    expect(remote.claimKey, 'one-logical-operation');
  });

  test('dismissed or failed ad is never claimed', () async {
    for (final outcome in [
      AdRewardOutcome.dismissed,
      AdRewardOutcome.failed,
    ]) {
      final remote = _FakeRemote();
      final result = await AdRewardFlow(
        service: _FakeService(
          result: AdRewardResult(outcome, error: StateError('no reward')),
        ),
        remote: remote,
      ).run();

      expect(result.outcome, outcome);
      expect(remote.calls, ['initiate']);
    }
  });

  test(
    'claim failure is reported as failed even though the ad completed',
    () async {
      final remote = _FakeRemote()..claimError = StateError('server rejected');
      final result = await AdRewardFlow(
        service: _FakeService(),
        remote: remote,
      ).run();

      expect(result.outcome, AdRewardOutcome.failed);
      expect(result.claimError, isA<StateError>());
      expect(result.rewarded, isFalse);
    },
  );

  test('initiate failure never shows an ad', () async {
    final remote = _FakeRemote()
      ..initiateError = StateError('claim session refused');
    final service = _FakeService();
    final result = await AdRewardFlow(service: service, remote: remote).run();

    expect(result.outcome, AdRewardOutcome.failed);
    expect(remote.calls, ['initiate']);
    expect(service.showCalls, 0);
  });
}
