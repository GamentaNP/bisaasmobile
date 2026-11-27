import 'package:bisaasmobile/core/ads/ad_reward_remote_data_source.dart';
import 'package:bisaasmobile/core/network/api_failure.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration/support/fake_api.dart';

void main() {
  late FakeApi api;
  late AdRewardRemoteDataSource remote;

  setUp(() {
    api = FakeApi({});
    remote = AdRewardRemoteDataSource(dioFor(api));
  });

  test('initiate POSTs optional fields and unwraps data.claimToken', () async {
    api.on(
      'POST',
      '/ads/reward/initiate',
      FakeRoute.ok(<String, dynamic>{
        'claimToken': 'server-token',
        'requiredDurationSeconds': 12,
      }),
    );

    final session = await remote.initiate(
      rewardType: 'quiz_reward',
      slotCode: 'daily_quiz',
    );

    expect(session.claimToken, 'server-token');
    expect(session.requiredDurationSeconds, 12);
    final body = api.jsonBodyOf(0);
    expect(body['reward_type'], 'quiz_reward');
    expect(body['slot_code'], 'daily_quiz');
  });

  test('claim PUTs claim_token and a supplied Idempotency-Key', () async {
    api.on('PUT', '/ads/reward/claim', FakeRoute.ok(<String, dynamic>{}));

    await remote.claim('server-token', idempotencyKey: 'fixed-key');

    expect(api.requests.single.method, 'PUT');
    expect(api.jsonBodyOf(0)['claim_token'], 'server-token');
    expect(api.headerOf(0, 'Idempotency-Key'), 'fixed-key');
  });

  test('claim mints an idempotency key when the caller does not', () async {
    api.on('PUT', '/ads/reward/claim', FakeRoute.ok(<String, dynamic>{}));

    await remote.claim('server-token');

    expect(api.headerOf(0, 'Idempotency-Key'), isNotEmpty);
  });

  test('a 200 without data.claimToken throws ContractViolation', () async {
    api.on(
      'POST',
      '/ads/reward/initiate',
      FakeRoute.ok(<String, dynamic>{'coinsExpected': 5}),
    );

    expect(
      remote.initiate(),
      throwsA(isA<ContractViolation>()),
    );
  });

  test('a failed claim propagates as a DioException, not a silent success', () async {
    api.on(
      'PUT',
      '/ads/reward/claim',
      FakeRoute.error(422, 'REWARD_VERIFICATION_FAILED', 'too early'),
    );

    expect(
      remote.claim('server-token'),
      throwsA(isA<DioException>()),
    );
  });
}
