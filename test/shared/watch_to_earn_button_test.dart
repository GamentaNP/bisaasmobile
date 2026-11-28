/// The entry point follows the live admin switches, and a tap runs exactly
/// one server-verified claim with a replay-safe key.
library;

import 'package:bisaasmobile/app/config/app_config.dart';
import 'package:bisaasmobile/app/providers.dart';
import 'package:bisaasmobile/core/ads/ad_claim_session.dart';
import 'package:bisaasmobile/core/ads/ad_reward_flow.dart';
import 'package:bisaasmobile/core/ads/ad_reward_remote_data_source.dart';
import 'package:bisaasmobile/core/ads/ad_reward_result.dart';
import 'package:bisaasmobile/core/ads/ad_reward_service.dart';
import 'package:bisaasmobile/core/ads/ads_providers.dart';
import 'package:bisaasmobile/l10n/app_localizations.dart';
import 'package:bisaasmobile/shared/widgets/watch_to_earn_button.dart';
import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../support/localized_app.dart';

class _Service implements AdRewardService {
  @override
  bool get isAvailable => true;

  @override
  Future<void> initialize() async {}

  @override
  Future<AdRewardResult> showRewardedAd() async =>
      const AdRewardResult.rewarded();
}

class _Remote extends AdRewardRemoteDataSource {
  _Remote() : super(Dio());

  String? claimKey;

  @override
  Future<AdClaimSession> initiate({String? rewardType, String? slotCode}) async =>
      const AdClaimSession(claimToken: 'token', requiredDurationSeconds: 10);

  @override
  Future<void> claim(
    String claimToken, {
    String? idempotencyKey,
    Map<String, dynamic>? telemetry,
  }) async {
    claimKey = idempotencyKey;
  }
}

class _Flow extends AdRewardFlow {
  _Flow() : super(service: _Service(), remote: _Remote());

  int runs = 0;
  String? keyUsed;

  @override
  Future<AdRewardFlowResult> run({
    String? rewardType,
    String? slotCode,
    String? claimIdempotencyKey,
  }) async {
    runs++;
    keyUsed = claimIdempotencyKey;
    return AdRewardFlowResult.rewarded();
  }
}

void main() {
  Widget host({required bool ads, required bool rewards, _Flow? flow}) {
    return ProviderScope(
      overrides: [
        appConfigValueProvider.overrideWithValue(
          AppConfig(features: {
            'ads_enabled': ads,
            'ads_rewards_enabled': rewards,
          }),
        ),
        adRewardReadyProvider.overrideWith((ref) async => true),
        if (flow != null) adRewardFlowProvider.overrideWithValue(flow),
      ],
      child: localizedApp(child: const Scaffold(body: WatchToEarnButton())),
    );
  }

  testWidgets('hidden when the admin has ads disabled', (tester) async {
    await tester.pumpWidget(host(ads: false, rewards: true));
    await tester.pumpAndSettle();
    expect(find.byType(OutlinedButton), findsNothing);
  });

  testWidgets('hidden when coin rewards are disabled', (tester) async {
    await tester.pumpWidget(host(ads: true, rewards: false));
    await tester.pumpAndSettle();
    expect(find.byType(OutlinedButton), findsNothing);
  });

  testWidgets('a tap runs one flow with a stable claim key', (tester) async {
    final flow = _Flow();
    await tester.pumpWidget(host(ads: true, rewards: true, flow: flow));
    await tester.pumpAndSettle();

    final l10n = AppLocalizations.of(tester.element(find.byType(WatchToEarnButton)))!;
    expect(find.text(l10n.adsWatchToEarn), findsOneWidget);

    await tester.tap(find.byType(OutlinedButton));
    await tester.pumpAndSettle();

    expect(flow.runs, 1);
    expect(flow.keyUsed, isNotNull);
    expect(flow.keyUsed, isNotEmpty);
  });
}
