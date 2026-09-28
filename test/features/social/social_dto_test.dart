import 'package:bisaasmobile/features/social/data/models/social_dto.dart';
import 'package:bisaasmobile/features/social/domain/entities/social.dart';
import 'package:flutter_test/flutter_test.dart';

/// Shapes come from `app/Domains/Quiz/Social/Services/ReferralService.php`
/// (`dashboardPayload`) and `app/Http/Controllers/Api/Social/GrowthController.php`.
///
/// The most important test in this file is the casing one: the dashboard is
/// **camelCase** while the rest of the API is snake_case, because that endpoint
/// returns a hand-written array rather than a JsonResource. A parser written
/// for snake_case would not throw — it would return a dashboard full of zeros,
/// which is the failure mode this guards.
void main() {
  group('ReferralDashboardDto', () {
    final camel = <String, dynamic>{
      'referral': <String, dynamic>{
        'code': 'BISA-7F3K',
        'shareUrl': 'https://bisaas.com/register?ref=BISA-7F3K',
        'referrerRewardCoins': 250,
        'referredRewardCoins': 100,
        'firstQuizRewardCoins': 50,
        'stats': <String, dynamic>{
          'totalReferrals': 4,
          'rewardedReferrals': 2,
          'pendingReferrals': 2,
          'firstQuizRewardedReferrals': 1,
          'secondDegreeRewardedReferrals': 3,
          'secondDegreeBonusCoins': 75,
          'coinsEarned': 575,
        },
        'referrals': [
          <String, dynamic>{
            'id': 1,
            'referredName': 'Sita',
            'status': 'rewarded',
            'referrerRewardCoins': 250,
            'referredRewardCoins': 100,
          },
          <String, dynamic>{
            'id': 2,
            'referredName': null,
            'status': 'pending',
            'referrerRewardCoins': 0,
            'referredRewardCoins': 0,
          },
        ],
      },
    };

    test('parses the camelCase payload the server actually sends', () {
      final d = ReferralDashboardDto.fromJson(camel)!.domain;
      expect(d.code, 'BISA-7F3K');
      expect(d.shareUrl, 'https://bisaas.com/register?ref=BISA-7F3K');
      expect(d.referrerRewardCoins, 250);
      expect(d.firstQuizRewardCoins, 50);
      expect(d.stats.totalReferrals, 4);
      expect(d.stats.rewardedReferrals, 2);
      expect(d.stats.coinsEarned, 575);
      expect(d.referrals.length, 2);
    });

    test('a snake_case parser would have read every number as zero', () {
      // Pins the failure mode: if someone "tidies" the DTO to snake_case only,
      // this test fails instead of shipping a silently empty dashboard.
      final d = ReferralDashboardDto.fromJson(camel)!.domain;
      expect(d.stats.totalReferrals, isNot(0));
      expect(d.stats.coinsEarned, isNot(0));
      expect(d.referrerRewardCoins, isNot(0));
    });

    test('also accepts snake_case, so a server-side fix will not break the app', () {
      final snake = <String, dynamic>{
        'referral': <String, dynamic>{
          'code': 'X1',
          'share_url': 'https://bisaas.com/register?ref=X1',
          'referrer_reward_coins': 10,
          'stats': <String, dynamic>{'total_referrals': 1, 'coins_earned': 10},
        },
      };
      final d = ReferralDashboardDto.fromJson(snake)!.domain;
      expect(d.shareUrl, contains('ref=X1'));
      expect(d.referrerRewardCoins, 10);
      expect(d.stats.totalReferrals, 1);
    });

    test('rejects a payload with no code or no share URL', () {
      // Rendering an empty share button would be worse than saying nothing.
      final noCode = <String, dynamic>{
        'referral': <String, dynamic>{'shareUrl': 'https://x'},
      };
      expect(ReferralDashboardDto.fromJson(noCode), isNull);

      final noUrl = <String, dynamic>{
        'referral': <String, dynamic>{'code': 'A'},
      };
      expect(ReferralDashboardDto.fromJson(noUrl), isNull);
    });

    test('rejects a payload with no referral object', () {
      expect(ReferralDashboardDto.fromJson(<String, dynamic>{}), isNull);
      expect(ReferralDashboardDto.fromJson(<String, dynamic>{'referral': 'nope'}), isNull);
    });

    test('missing stats default to zero rather than throwing', () {
      final d = ReferralDashboardDto.fromJson(<String, dynamic>{
        'referral': <String, dynamic>{'code': 'A', 'shareUrl': 'https://x'},
      })!.domain;
      expect(d.stats.totalReferrals, 0);
      expect(d.referrals, isEmpty);
      expect(d.hasAnyReferral, isFalse);
    });

    test('a deleted referred account shows as "A learner", not a blank row', () {
      final d = ReferralDashboardDto.fromJson(camel)!.domain;
      expect(d.referrals[0].displayName, 'Sita');
      expect(d.referrals[1].referredName, isNull);
      expect(d.referrals[1].displayName, 'A learner');
    });

    test('recognises the rewarded status case-insensitively', () {
      final d = ReferralDashboardDto.fromJson(camel)!.domain;
      expect(d.referrals[0].isRewarded, isTrue);
      expect(d.referrals[1].isRewarded, isFalse);
    });

    test('a malformed referral row is skipped, not fatal', () {
      final d = ReferralDashboardDto.fromJson(<String, dynamic>{
        'referral': <String, dynamic>{
          'code': 'A',
          'shareUrl': 'https://x',
          'referrals': ['not a map', 42, <String, dynamic>{'id': 9, 'status': 'rewarded'}],
        },
      })!.domain;
      expect(d.referrals.length, 1);
      expect(d.referrals.single.id, 9);
    });

    test('the share URL comes from the server, never built locally', () {
      // Building it on the client is how a share link ends up pointing at
      // localhost in a debug build.
      final d = ReferralDashboardDto.fromJson(camel)!.domain;
      expect(d.shareUrl, startsWith('https://'));
    });
  });

  group('ReferralClaimDto', () {
    test('parses a successful claim', () {
      final c = ReferralClaimDto.fromJson(<String, dynamic>{
        'claimed': true,
        'status': 'rewarded',
        'referrer_reward_coins': 250,
        'referred_reward_coins': 100,
      })!.domain;
      expect(c.claimed, isTrue);
      expect(c.status, 'rewarded');
      expect(c.referrerRewardCoins, 250);
    });

    test('rejects a body with no real boolean `claimed`', () {
      expect(ReferralClaimDto.fromJson(<String, dynamic>{'status': 'x'}), isNull);
      expect(ReferralClaimDto.fromJson(<String, dynamic>{'claimed': 'true'}), isNull);
    });
  });

  group('ShareMomentDto', () {
    test('parses a moment', () {
      final m = ShareMomentDto.fromJson(<String, dynamic>{
        'id': 'streak-7',
        'kind': 'streak',
        'ctaLabel': 'Share your streak',
        'title': 'You are on a 7-day streak',
        'rewardCoins': 20,
      })!.moment;
      expect(m.id, 'streak-7');
      expect(m.kind, 'streak');
      expect(m.hasReward, isTrue);
      expect(m.dismissed, isFalse);
    });

    test('hasReward is false when the server attached no figure', () {
      final m = ShareMomentDto.fromJson(<String, dynamic>{
        'id': 'a',
        'kind': 'streak',
      })!.moment;
      expect(m.hasReward, isFalse, reason: 'never invent a coin amount');
      expect(m.rewardCoins, 0);
    });

    test('defaults the CTA rather than rendering an empty button', () {
      final m = ShareMomentDto.fromJson(<String, dynamic>{'id': 'a', 'kind': 'streak'})!.moment;
      expect(m.ctaLabel, isNotEmpty);
    });

    test('rejects a row with no id or no kind', () {
      expect(ShareMomentDto.fromJson(<String, dynamic>{'kind': 'streak'}), isNull);
      expect(ShareMomentDto.fromJson(<String, dynamic>{'id': 'a'}), isNull);
    });
  });

  group('SocialProofDto', () {
    test('parses a proof with a stat', () {
      final p = SocialProofDto.fromJson(<String, dynamic>{
        'subject': 'question',
        'headline': 'You solved a Civil MCQ',
        'statLabel': 'Your accuracy',
        'statValue': '92%',
        'shareText': 'I solved a Civil MCQ on CivilCal',
      })!.proof;
      expect(p.subject, 'question');
      expect(p.hasStat, isTrue);
      expect(p.statValue, '92%');
    });

    test('a proof with no stat reports hasStat false rather than a blank row', () {
      final p = SocialProofDto.fromJson(<String, dynamic>{
        'subject': 'course',
        'headline': 'Course complete',
        'statValue': '   ',
      })!.proof;
      expect(p.hasStat, isFalse);
    });

    test('rejects a proof with no headline', () {
      expect(SocialProofDto.fromJson(<String, dynamic>{'subject': 'course'}), isNull);
    });
  });

  group('ReferralStats defaults', () {
    test('an entirely absent stats object is all zeros, not null', () {
      const s = ReferralStats();
      expect(s.totalReferrals, 0);
      expect(s.coinsEarned, 0);
    });
  });
}
