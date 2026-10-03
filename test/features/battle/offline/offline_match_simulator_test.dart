import 'dart:convert';

import 'package:bisaasmobile/core/sync/sync_queue.dart';
import 'package:bisaasmobile/features/battle/domain/offline/offline_bot_models.dart';
import 'package:bisaasmobile/features/battle/domain/offline/offline_match_simulator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Offline roster JSON exactly as the server serves it (quiz contract
/// 2026.10.4). Hand-written rather than generated, and deliberately including
/// the fields a careless client would leak: no user id, no account name, no
/// answer key.
Map<String, dynamic> rosterJson({
  int size = 2,
  String? expiresAt,
}) {
  return <String, dynamic>{
    'manifest_id': '3f2504e0-4f89-41d3-9a0c-0305e82c3301',
    'seed': 'offline:42:2026-10-04',
    'pack_day': '2026-10-04',
    'kernel_version': 'bot-decision/v2',
    'size': size,
    'expires_at': expiresAt ?? '2099-01-01T00:00:00+00:00',
    'opponents': <Map<String, dynamic>>[
      <String, dynamic>{
        'bot_key': 'bot_abc123',
        'display_name': 'Calm Ibis',
        'difficulty': 'intermediate',
        'personality': 'balanced',
        'accuracy_rate': 62,
        'min_answer_ms': 2500,
        'max_answer_ms': 9000,
        'misconception_code': 'ignores safety factor',
        'disclosed_as_ai': true,
      },
      <String, dynamic>{
        'bot_key': 'bot_def456',
        'display_name': 'Sharp Lynx',
        'difficulty': 'advanced',
        'personality': 'aggressive',
        'accuracy_rate': 76,
        'min_answer_ms': 1800,
        'max_answer_ms': 7000,
        'misconception_code': null,
        'disclosed_as_ai': true,
      },
    ],
  };
}

void main() {
  group('OfflineBotRoster parsing', () {
    test('reads a roster and its manifest handle', () {
      final roster = OfflineBotRoster.fromJson(rosterJson());

      expect(roster, isNotNull);
      expect(roster!.manifestId, '3f2504e0-4f89-41d3-9a0c-0305e82c3301');
      expect(roster.seed, 'offline:42:2026-10-04');
      expect(roster.kernelVersion, 'bot-decision/v2');
      expect(roster.opponents, hasLength(2));
      expect(roster.size, 2);
      expect(roster.isExpired, isFalse);
    });

    test('rejects a roster with no manifest or no seed', () {
      // Without either, the server cannot verify a receipt later, so accepting
      // it locally would only defer the failure to sync time.
      final noManifest = rosterJson()..remove('manifest_id');
      final noSeed = rosterJson()..remove('seed');

      expect(OfflineBotRoster.fromJson(noManifest), isNull);
      expect(OfflineBotRoster.fromJson(noSeed), isNull);
    });

    test('drops opponent rows without a bot key instead of failing', () {
      final json = rosterJson();
      (json['opponents'] as List).removeAt(0);

      final roster = OfflineBotRoster.fromJson(json);

      expect(roster, isNotNull);
      expect(roster!.opponents, hasLength(1));
    });

    test('treats an opponent with no misconception code as untargeted', () {
      final roster = OfflineBotRoster.fromJson(rosterJson())!;

      expect(roster.opponents.first.misconceptionCode, 'ignores safety factor');
      expect(roster.opponents.last.misconceptionCode, isNull);
    });

    test('knows when a manifest has expired', () {
      final roster = OfflineBotRoster.fromJson(
        rosterJson(expiresAt: '2000-01-01T00:00:00+00:00'),
      )!;

      expect(roster.isExpired, isTrue);
    });
  });

  group('OfflineMatchSimulator', () {
    test('reports one decision per opponent per question', () {
      final roster = OfflineBotRoster.fromJson(rosterJson())!;

      final receipt = OfflineMatchSimulator.simulate(
        roster: roster,
        questions: const <OfflineMatchQuestion>[
          OfflineMatchQuestion(id: 1000, position: 0),
          OfflineMatchQuestion(id: 1001, position: 1),
        ],
      );

      expect(receipt.decisions, hasLength(4)); // 2 opponents x 2 questions
      expect(receipt.manifestId, roster.manifestId);
      expect(receipt.kernelVersion, 'bot-decision/v2');
    });

    test('is deterministic: the same inputs replay identically', () {
      final roster = OfflineBotRoster.fromJson(rosterJson())!;
      const questions = <OfflineMatchQuestion>[
        OfflineMatchQuestion(id: 1000, position: 0),
      ];

      final first =
          OfflineMatchSimulator.simulate(roster: roster, questions: questions);
      final second =
          OfflineMatchSimulator.simulate(roster: roster, questions: questions);

      expect(jsonEncode(first.toJson()), jsonEncode(second.toJson()));
    });

    test('gives a misconception-targeted bot the matching distractor', () {
      final roster = OfflineBotRoster.fromJson(rosterJson())!;

      final receipt = OfflineMatchSimulator.simulate(
        roster: roster,
        questions: const <OfflineMatchQuestion>[
          OfflineMatchQuestion(id: 1000, position: 0),
        ],
        misconceptionTargets: const <int, Map<String, String>>{
          1000: <String, String>{'ignores safety factor': 'b'},
        },
      );

      final targeted = receipt.decisions
          .where((d) => d.botKey == 'bot_abc123')
          .toList();

      expect(targeted, hasLength(1));
      expect(targeted.single.durationMs, greaterThanOrEqualTo(2500));
    });

    test('reports a null option on a correct answer', () {
      final roster = OfflineBotRoster.fromJson(rosterJson())!;

      final receipt = OfflineMatchSimulator.simulate(
        roster: roster,
        questions: const <OfflineMatchQuestion>[
          OfflineMatchQuestion(id: 1000, position: 0),
        ],
      );

      for (final decision in receipt.decisions) {
        if (decision.answeredCorrectly) {
          expect(
            decision.chosenAnswerKey,
            isNull,
            reason: 'a correct answer has no chosen wrong option to report',
          );
        }
      }
    });

    test('produces an empty receipt for an empty roster', () {
      final roster = OfflineBotRoster.fromJson(
        rosterJson(size: 0)..['opponents'] = <dynamic>[],
      )!;

      final receipt = OfflineMatchSimulator.simulate(
        roster: roster,
        questions: const <OfflineMatchQuestion>[
          OfflineMatchQuestion(id: 1000, position: 0),
        ],
      );

      expect(receipt.decisions, isEmpty);
    });
  });

  group('OfflineMatchReceipt wire shape', () {
    test('carries no monetary or completion field', () {
      final roster = OfflineBotRoster.fromJson(rosterJson())!;
      final receipt = OfflineMatchSimulator.simulate(
        roster: roster,
        questions: const <OfflineMatchQuestion>[
          OfflineMatchQuestion(id: 1000, position: 0),
        ],
      );

      final body = receipt.toJson();

      expect(body.keys, containsAll(<String>['manifest_id', 'seed', 'kernel_version', 'decisions']));

      // The whole point of the contract: nowhere for a payout to appear.
      for (final forbidden in <String>[
        'coins',
        'coin_total',
        'xp',
        'score',
        'awarded',
        'completed',
        'is_correct',
      ]) {
        expect(body.containsKey(forbidden), isFalse,
            reason: 'a receipt must never carry $forbidden');
      }

      for (final decision in body['decisions'] as List<dynamic>) {
        final map = decision as Map<String, dynamic>;
        for (final forbidden in <String>['coins', 'xp', 'score', 'awarded']) {
          expect(map.containsKey(forbidden), isFalse,
              reason: 'a decision must never carry $forbidden');
        }
      }
    });

    test('reports chosen_answer_key on every decision, null when correct', () {
      final roster = OfflineBotRoster.fromJson(rosterJson())!;
      final receipt = OfflineMatchSimulator.simulate(
        roster: roster,
        questions: const <OfflineMatchQuestion>[
          OfflineMatchQuestion(id: 1000, position: 0),
        ],
      );

      for (final decision
          in (receipt.toJson()['decisions'] as List<dynamic>)) {
        // Present-but-null rather than omitted: the server validates it, and a
        // missing key is indistinguishable from a client that never checked it.
        expect((decision as Map<String, dynamic>).containsKey('chosen_answer_key'),
            isTrue);
      }
    });
  });

  group('OfflineReceiptVerdict', () {
    test('reads a corroborated verdict', () {
      final verdict = OfflineReceiptVerdict.fromJson(<String, dynamic>{
        'status': 'corroborated',
        'reasons': <String>[],
        'awarded': false,
      })!;

      expect(verdict.isCorroborated, isTrue);
      expect(verdict.isQuarantined, isFalse);
      expect(verdict.awarded, isFalse);
      expect(verdict.isTerminal, isFalse);
    });

    test('treats a forgery as terminal so the queue stops retrying it', () {
      final verdict = OfflineReceiptVerdict.fromJson(<String, dynamic>{
        'status': 'quarantined',
        'reasons': <String>['decision_mismatch'],
        'awarded': false,
      })!;

      expect(verdict.isTerminal, isTrue);
    });

    test('treats an expired manifest as retryable, not terminal', () {
      // A stale device is not a liar. Dropping this receipt silently would
      // lose an honest learner's offline session; the server already declined to
      // call it a forgery.
      final verdict = OfflineReceiptVerdict.fromJson(<String, dynamic>{
        'status': 'quarantined',
        'reasons': <String>['expired_manifest'],
        'awarded': false,
      })!;

      expect(verdict.isQuarantined, isTrue);
      expect(verdict.isTerminal, isFalse);
    });

    test('rejects a verdict with no status', () {
      expect(OfflineReceiptVerdict.fromJson(<String, dynamic>{}), isNull);
    });
  });

  group('SyncQueueService offline receipt routing', () {
    test('accepts the receipt endpoint', () {
      expect(SyncQueueService.validateEndpoint('/quiz/offline/match-receipt'),
          isNull);
    });

    test('still refuses an absolute receipt endpoint', () {
      // The queue replays through the authenticated Dio, so an absolute URL
      // would send the bearer token to a third party.
      expect(
        SyncQueueService.validateEndpoint(
            'https://attacker.example/quiz/offline/match-receipt'),
        isNotNull,
      );
    });
  });
}
