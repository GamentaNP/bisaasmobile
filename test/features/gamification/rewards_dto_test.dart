import 'package:bisaasmobile/features/gamification/data/models/rewards_dto.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pinned to live payloads from 2026-09-27.
///
/// The important thing these lock in is the **envelope inconsistency**:
/// `daily-checkin/status` is enveloped, while the whole `spin` pair answers raw
/// JSON outside `{success, data}`. A parser written for one shape silently
/// returns nothing for the other.
void main() {
  group('CheckInStatusDto', () {
    test('parses the enveloped status (camelCase)', () {
      // GET /api/v1/rewards/daily-checkin/status ->
      // {"data":{"claimedToday":false,"streakDay":0,"todayReward":10,"nextReward":15}}
      final d = CheckInStatusDto.fromJson(const {
        'claimedToday': false,
        'streakDay': 0,
        'todayReward': 10,
        'nextReward': 15,
      });
      expect(d.claimedToday, isFalse);
      expect(d.streakDay, 0);
      expect(d.todayReward, 10);
      expect(d.nextReward, 15);
      expect(d.canClaim, isTrue);
    });

    test('after claiming, the ladder is no longer claimable', () {
      final d = CheckInStatusDto.fromJson(const {
        'claimedToday': true,
        'streakDay': 1,
        'todayReward': 10,
        'nextReward': 15,
      });
      expect(d.canClaim, isFalse);
      expect(d.streakDay, 1);
    });

    test('a zero reward is not claimable', () {
      final d = CheckInStatusDto.fromJson(const {
        'claimedToday': false,
        'todayReward': 0,
        'nextReward': 0,
      });
      expect(d.canClaim, isFalse);
    });

    test('tolerates the snake_case spelling', () {
      final d = CheckInStatusDto.fromJson(const {
        'claimed_today': true,
        'streak_day': 4,
        'today_reward': 20,
        'next_reward': 25,
      });
      expect(d.claimedToday, isTrue);
      expect(d.streakDay, 4);
      expect(d.todayReward, 20);
    });
  });

  group('CheckInResultDto', () {
    test('parses a credited claim', () {
      final r = CheckInResultDto.fromJson(const {
        'credited': true,
        'amount': 10,
        'newBalance': 140,
        'streakDay': 1,
        'nextReward': 15,
        'reason': null,
      });
      expect(r.credited, isTrue);
      expect(r.amount, 10);
      expect(r.newBalance, 140);
      expect(r.streakDay, 1);
    });

    test('a 409 repeat claim reports credited:false with a reason', () {
      final r = CheckInResultDto.fromJson(const {
        'credited': false,
        'amount': 0,
        'newBalance': 140,
        'streakDay': 1,
        'reason': 'ALREADY_CLAIMED',
      });
      expect(r.credited, isFalse);
      expect(r.reason, 'ALREADY_CLAIMED');
    });
  });

  group('SpinStatusDto', () {
    // GET /api/v1/rewards/spin/status — RAW, no envelope.
    final raw = <String, dynamic>{
      'canSpin': true,
      'prizes': [
        {
          'type': 'coins',
          'coins': 10,
          'xp': 10,
          'lifelineSlug': null,
          'lifelineQuantity': 0,
          'label': '10 Coins + 10 XP',
          'colorHex': '#94A3B8',
          'rarity': 'common',
        },
        {
          'type': 'lifeline',
          'coins': 0,
          'xp': 15,
          'lifelineSlug': 'fifty_fifty',
          'lifelineQuantity': 1,
          'label': '1x 50/50 Lifeline',
          'colorHex': '#A855F7',
          'rarity': 'uncommon',
        },
      ],
      'nextSpinAt': null,
    };

    test('parses the raw status body', () {
      final s = SpinStatusDto.fromJson(raw);
      expect(s.canSpin, isTrue);
      expect(s.prizes, hasLength(2));
      expect(s.prizes.first.label, '10 Coins + 10 XP');
      expect(s.prizes.first.coins, 10);
      expect(s.prizes.last.lifelineSlug, 'fifty_fifty');
      expect(s.prizes.last.lifelineQuantity, 1);
    });

    test('parses the server colour hex', () {
      final s = SpinStatusDto.fromJson(raw);
      // #A855F7 -> 0xFFA855F7
      expect(s.prizes.last.color.toARGB32(), 0xFFA855F7);
    });

    test('an unparseable colour falls back rather than throwing', () {
      final s = SpinStatusDto.fromJson({
        'canSpin': true,
        'prizes': [
          {'type': 'coins', 'coins': 1, 'label': 'x', 'colorHex': 'not-a-colour'},
        ],
      });
      expect(s.prizes.first.color.toARGB32(), 0xFF94A3B8);
    });

    test('a used wheel reports canSpin:false with a next time', () {
      final s = SpinStatusDto.fromJson(const {
        'canSpin': false,
        'prizes': <dynamic>[],
        'nextSpinAt': '2026-09-28T23:59:59+05:45',
      });
      expect(s.canSpin, isFalse);
      expect(s.nextSpinAt, isNotNull);
    });
  });

  group('SpinResultDto', () {
    // POST /api/v1/rewards/spin — RAW, no envelope.
    test('parses a successful spin', () {
      final r = SpinResultDto.fromJson(const {
        'spun': true,
        'type': 'coins',
        'coins': 10,
        'xp': 10,
        'lifelineSlug': null,
        'lifelineQuantity': 0,
        'label': '10 Coins + 10 XP',
        'prizeIndex': 0,
        'newBalance': 102,
        'nextSpinAt': '2026-09-28T23:59:59+05:45',
        'signature': '2bb40a38...',
        'reason': null,
      });
      expect(r.spun, isTrue);
      expect(r.coins, 10);
      expect(r.prizeIndex, 0);
      expect(r.newBalance, 102);
    });

    test('spun:false with a reason is a normal refusal, not an error', () {
      // "Come back tomorrow" arrives as a 422 with this body.
      final r = SpinResultDto.fromJson(const {
        'spun': false,
        'coins': 0,
        'reason': 'SPIN_NOT_AVAILABLE',
      });
      expect(r.spun, isFalse);
      expect(r.reason, 'SPIN_NOT_AVAILABLE');
    });
  });
}
