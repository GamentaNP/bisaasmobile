import 'package:bisaasmobile/features/game/data/models/mission_dto.dart';
import 'package:flutter_test/flutter_test.dart';

/// Pinned to the live `GET /api/v1/quiz/game/missions/dashboard` payload
/// (bisaas, probed 2026-09-27 — 49 missions, camelCase, `data` is a BARE ARRAY).
void main() {
  // Verbatim first row from the live response.
  final live = <String, dynamic>{
    'id': 7,
    'progressId': null,
    'key': 'world_provident-ut-et_daily_complete_levels',
    'title': 'Realm of Provident Ut Et Pathfinder',
    'description': 'Complete 3 levels in Realm of Provident Ut Et.',
    'cadence': 'daily',
    'objectiveJson': {'action': 'complete_level', 'world_id': 1},
    'gameWorldId': 1,
    'quizPortalLevelId': null,
    'targetAction': 'complete_level',
    'targetCount': 3,
    'currentCount': 0,
    'progressData': null,
    'progressPercent': 0,
    'completed': false,
    'claimed': false,
    'rewardCoins': 30,
    'rewardXp': 50,
    'tier': 'bronze',
    'autoClaim': false,
    'scope': 'world',
    'communityProgress': null,
    'expiresAt': null,
  };

  group('MissionDto', () {
    test('parses the real payload', () {
      final m = MissionDto.fromJson(live);
      expect(m.id, 7);
      expect(m.title, 'Realm of Provident Ut Et Pathfinder');
      expect(m.description, 'Complete 3 levels in Realm of Provident Ut Et.');
      expect(m.cadence, 'daily');
      expect(m.targetAction, 'complete_level');
      expect(m.targetCount, 3);
      expect(m.currentCount, 0);
      expect(m.rewardCoins, 30);
      expect(m.rewardXp, 50);
      expect(m.tier, 'bronze');
      expect(m.gameWorldId, 1);
      expect(m.autoClaim, isFalse);
    });

    test('an incomplete mission is not claimable', () {
      expect(MissionDto.fromJson(live).isClaimable, isFalse);
      expect(MissionDto.fromJson(live).progressFraction, 0);
    });

    test('completed + unclaimed + not autoClaim is claimable', () {
      final m = MissionDto.fromJson({
        ...live,
        'completed': true,
        'claimed': false,
        'currentCount': 3,
        'progressPercent': 100,
      });
      expect(m.isClaimable, isTrue);
      expect(m.progressFraction, 1.0);
    });

    test('a claimed mission is not claimable again', () {
      final m = MissionDto.fromJson({...live, 'completed': true, 'claimed': true});
      expect(m.isClaimable, isFalse);
    });

    test('an auto-claim mission is never shown a claim button', () {
      final m = MissionDto.fromJson({...live, 'completed': true, 'claimed': false, 'autoClaim': true});
      expect(m.isClaimable, isFalse);
    });

    test('progress is clamped to the target', () {
      final m = MissionDto.fromJson({...live, 'targetCount': 3, 'currentCount': 10});
      expect(m.progressFraction, 1.0);
    });

    test('a zero target does not divide by zero', () {
      final m = MissionDto.fromJson({...live, 'targetCount': 0, 'currentCount': 0, 'progressPercent': 40});
      expect(m.progressFraction, closeTo(0.4, 0.001));
    });

    test('tolerates the snake_case spelling', () {
      final m = MissionDto.fromJson(const {
        'id': 1,
        'title': 'T',
        'cadence': 'weekly',
        'target_count': 5,
        'current_count': 2,
        'progress_percent': 40,
        'reward_coins': 10,
        'reward_xp': 20,
      });
      expect(m.targetCount, 5);
      expect(m.currentCount, 2);
      expect(m.rewardCoins, 10);
    });

    test('an empty object does not throw', () {
      final m = MissionDto.fromJson(const {});
      expect(m.id, 0);
      expect(m.title, '');
      expect(m.rewardCoins, 0);
      expect(m.isClaimable, isFalse);
    });
  });

  group('MissionClaimDto', () {
    test('parses a successful claim', () {
      final r = MissionClaimDto.fromJson(const {
        'claimed': true,
        'coins': 30,
        'tier': 'bronze',
        'extras': {'lifelines': 1, 'cityResources': 0, 'exclusiveBadges': 0},
      });
      expect(r.claimed, isTrue);
      expect(r.coins, 30);
      expect(r.tier, 'bronze');
      expect(r.lifelines, 1);
    });

    test('a refusal carries the reason and is not a success', () {
      final r = MissionClaimDto.fromJson(const {
        'claimed': false,
        'coins': 0,
        'reason': 'MISSION_NOT_CLAIMABLE',
      });
      expect(r.claimed, isFalse);
      expect(r.reason, 'MISSION_NOT_CLAIMABLE');
    });
  });

  group('MissionBulkClaimDto', () {
    test('parses the claim-all result', () {
      final r = MissionBulkClaimDto.fromJson(const {
        'claimedCount': 3,
        'coins': 90,
        'failedCount': 1,
        'failures': [
          {'progressId': 5, 'reason': 'MISSION_NOT_CLAIMABLE'},
        ],
      });
      expect(r.claimedCount, 3);
      expect(r.coins, 90);
      expect(r.failedCount, 1);
      expect(r.failures, ['MISSION_NOT_CLAIMABLE']);
    });
  });
}
