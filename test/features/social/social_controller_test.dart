import 'package:bisaasmobile/features/social/data/datasources/social_remote_data_source.dart';
import 'package:bisaasmobile/features/social/data/repositories/social_repository_impl.dart';
import 'package:bisaasmobile/features/social/domain/entities/social.dart';
import 'package:bisaasmobile/features/social/presentation/controllers/social_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockSocialRemote extends Mock implements SocialRemoteDataSource {}

/// Controller-level tests for the referral loop.
///
/// The DTO tests pin the camelCase parsing, which is where the silent-zero
/// failure lived. These pin the *state* behaviour, which is where the user-facing
/// lies would be: a claim reported as successful when the server said nothing, a
/// dismissed prompt that reappears, or a stale "applied" banner sitting above a
/// later failure.
void main() {
  late MockSocialRemote remote;

  setUpAll(() => registerFallbackValue(''));

  setUp(() => remote = MockSocialRemote());

  ReferralDashboard dashboard({
    String code = 'BISA-1',
    int total = 2,
  }) {
    return ReferralDashboard(
      code: code,
      shareUrl: 'https://bisaas.com/register?ref=$code',
      referrerRewardCoins: 250,
      referredRewardCoins: 100,
      firstQuizRewardCoins: 50,
      stats: ReferralStats(totalReferrals: total, rewardedReferrals: 1, coinsEarned: 250),
    );
  }

  ProviderContainer containerWith({
    ReferralDashboard? dash,
    bool failDashboard = false,
    ReferralClaim? claim,
    bool failClaim = false,
    List<ShareMoment> moments = const [],
  }) {
    if (failDashboard) {
      when(remote.getReferralDashboard).thenThrow(StateError('boom'));
    } else if (dash != null) {
      when(remote.getReferralDashboard).thenAnswer((_) async => dash);
    } else {
      when(remote.getReferralDashboard).thenAnswer((_) async => null);
    }
    when(remote.getActiveMoments).thenAnswer((_) async => moments);
    if (failClaim) {
      when(() => remote.claimReferralCode(any())).thenThrow(StateError('boom'));
    } else {
      when(() => remote.claimReferralCode(any()))
          .thenAnswer((_) async => claim ??
              const ReferralClaim(claimed: false, status: 'unknown'));
    }
    when(() => remote.dismissMoment(any())).thenAnswer((_) async {});

    final c = ProviderContainer(
      overrides: [socialRemoteDataSourceProvider.overrideWithValue(remote)],
    );
    addTearDown(c.dispose);
    return c;
  }

  /// Builds the notifier and lets the `build()`-scheduled `load()` settle.
  ///
  /// The initial `read` is what triggers `build()`; without it the provider is
  /// never constructed and the load never runs.
  Future<void> settle(ProviderContainer c) async {
    c.read(socialControllerProvider);
    for (var i = 0; i < 8; i++) {
      await Future<void>.delayed(Duration.zero);
    }
  }

  group('loading', () {
    test('populates the dashboard from the server', () async {
      final c = containerWith(dash: dashboard());
      await settle(c);
      final s = c.read(socialControllerProvider);
      expect(s.hasLoaded, isTrue);
      expect(s.dashboard!.code, 'BISA-1');
      expect(s.dashboard!.stats.coinsEarned, 250);
      expect(s.error, isNull);
    });

    test('a null dashboard is not the same as an error, and not a fake zero state',
        () async {
      // The distinction matters: "unavailable" and "you have no referrals" are
      // different claims and must not collapse into one.
      final c = containerWith();
      await settle(c);
      final s = c.read(socialControllerProvider);
      expect(s.hasLoaded, isFalse);
      expect(s.dashboard, isNull);
      expect(s.error, isNull);
    });

    test('a failed load surfaces an error and leaves the dashboard null', () async {
      final c = containerWith(failDashboard: true);
      await settle(c);
      final s = c.read(socialControllerProvider);
      expect(s.error, isNotNull);
      expect(s.hasLoaded, isFalse);
    });

    test('a moments failure does not blank a loaded dashboard', () async {
      when(remote.getReferralDashboard).thenAnswer((_) async => dashboard());
      when(remote.getActiveMoments).thenThrow(StateError('moments down'));
      final c = ProviderContainer(
        overrides: [socialRemoteDataSourceProvider.overrideWithValue(remote)],
      );
      addTearDown(c.dispose);
      await settle(c);
      final s = c.read(socialControllerProvider);
      expect(s.dashboard, isNotNull,
          reason: 'the dashboard is the point of the screen');
      expect(s.moments, isEmpty);
    });
  });

  group('claiming a code', () {
    test('a successful claim reports it and re-reads the dashboard', () async {
      final c = containerWith(
        dash: dashboard(),
        claim: const ReferralClaim(
          claimed: true,
          status: 'rewarded',
          referrerRewardCoins: 250,
        ),
      );
      await settle(c);
      await c.read(socialControllerProvider.notifier).claimCode('bisa-1');
      final s = c.read(socialControllerProvider);
      expect(s.claimMessage, isNotNull);
      expect(s.claimMessage, contains('applied'));
      // The reward may have changed the wallet, so the dashboard is re-read.
      verify(remote.getReferralDashboard).called(greaterThanOrEqualTo(2));
    });

    test('the code is upper-cased before it is sent', () async {
      final c = containerWith(
        dash: dashboard(),
        claim: const ReferralClaim(claimed: true, status: 'rewarded'),
      );
      await settle(c);
      await c.read(socialControllerProvider.notifier).claimCode('  bisa-9  ');
      verify(() => remote.claimReferralCode('BISA-9')).called(1);
    });

    test('a refused claim is not reported as a success', () async {
      // The server returns claimed: false for a code that is invalid or already
      // attributed. Saying "applied" there would be the exact class of bug this
      // codebase has been removing.
      final c = containerWith(
        dash: dashboard(),
        claim: const ReferralClaim(claimed: false, status: 'unknown'),
      );
      await settle(c);
      await c.read(socialControllerProvider.notifier).claimCode('BOGUS');
      final s = c.read(socialControllerProvider);
      // Asserted on the success phrase specifically: the failure message does
      // contain the word "applied" (as in "could not be applied"), so a naive
      // `isNot(contains('applied'))` would pass for the wrong reason.
      expect(s.claimMessage, isNot(contains('Referral code applied')));
      expect(s.claimMessage, contains('could not be applied'));
    });

    test('a refused claim does not re-read the dashboard', () async {
      final c = containerWith(
        dash: dashboard(),
        claim: const ReferralClaim(claimed: false, status: 'unknown'),
      );
      await settle(c);
      final before = c.read(socialControllerProvider).dashboard;
      await c.read(socialControllerProvider.notifier).claimCode('BOGUS');
      expect(c.read(socialControllerProvider).dashboard, same(before));
    });

    test('a thrown claim surfaces a message rather than an unhandled error', () async {
      final c = containerWith(dash: dashboard(), failClaim: true);
      await settle(c);
      await c.read(socialControllerProvider.notifier).claimCode('BISA-2');
      final s = c.read(socialControllerProvider);
      expect(s.claimMessage, isNotNull);
      expect(s.claimInFlight, isFalse, reason: 'the spinner must not stick');
    });

    test('an empty code is not sent at all', () async {
      final c = containerWith(dash: dashboard());
      await settle(c);
      await c.read(socialControllerProvider.notifier).claimCode('   ');
      verifyNever(() => remote.claimReferralCode(any()));
    });

    test('clearClaimMessage removes the banner so it cannot linger', () async {
      final c = containerWith(
        dash: dashboard(),
        claim: const ReferralClaim(claimed: true, status: 'rewarded'),
      );
      await settle(c);
      await c.read(socialControllerProvider.notifier).claimCode('BISA-3');
      expect(c.read(socialControllerProvider).claimMessage, isNotNull);
      c.read(socialControllerProvider.notifier).clearClaimMessage();
      expect(c.read(socialControllerProvider).claimMessage, isNull);
    });
  });

  group('dismissing a moment', () {
    const moment = ShareMoment(id: 'streak-7', kind: 'streak', ctaLabel: 'Share');

    test('removes it locally so it does not reappear while in flight', () async {
      final c = containerWith(dash: dashboard(), moments: const [moment]);
      await settle(c);
      expect(c.read(socialControllerProvider).moments, hasLength(1));
      await c.read(socialControllerProvider.notifier).dismiss(moment);
      expect(c.read(socialControllerProvider).moments, isEmpty);
    });

    test('a dismissal that fails is not resurrected into an error', () async {
      when(remote.getReferralDashboard).thenAnswer((_) async => dashboard());
      when(remote.getActiveMoments).thenAnswer((_) async => [moment]);
      when(() => remote.dismissMoment(any())).thenThrow(StateError('down'));
      final c = ProviderContainer(
        overrides: [socialRemoteDataSourceProvider.overrideWithValue(remote)],
      );
      addTearDown(c.dispose);
      await settle(c);
      await c.read(socialControllerProvider.notifier).dismiss(moment);
      final s = c.read(socialControllerProvider);
      expect(s.moments, isEmpty);
      expect(s.error, isNull,
          reason: 'a failed dismissal is not a screen-level error');
    });
  });

  group('the repository is a transparent pass-through', () {
    test('it does not transform or invent values', () async {
      when(remote.getReferralDashboard).thenAnswer((_) async => dashboard());
      final repo = SocialRepositoryImpl(remote);
      final result = await repo.getReferralDashboard();
      expect(result!.code, 'BISA-1');
    });
  });
}
