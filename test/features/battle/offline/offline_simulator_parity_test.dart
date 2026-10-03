import 'dart:convert';
import 'dart:io';

import 'package:bisaasmobile/features/battle/domain/offline/offline_bot_models.dart';
import 'package:bisaasmobile/features/battle/domain/offline/offline_match_simulator.dart';
import 'package:flutter_test/flutter_test.dart';

/// Proves the *simulator's wiring* matches the server, not just the kernel.
///
/// The golden-vector suite already proves `BotDecisionKernel` agrees with PHP
/// draw for draw. That is not sufficient on its own: the simulator adds a layer
/// on top that the kernel tests never touch — it maps a roster into kernel
/// requests, derives the question position, and resolves the misconception
/// target into `preferredWrongAnswerKey`. A mistake in any of those (a swapped
/// pair in the seed, a zero-based position where the server used one-based, the
/// wrong target looked up) would produce a receipt the server rejects, and every
/// honest offline player would be quarantined as a forger.
///
/// So this replays every committed decision vector through the simulator. Each
/// vector's own request becomes a one-opponent roster; the simulator's output
/// must equal the server's recorded expectation exactly.
void main() {
  const fixturePath =
      'test/features/battle/offline/fixtures/offline_kernel_golden_vectors.json';

  Map<String, dynamic> loadVectors() {
    final file = File(fixturePath);
    expect(
      file.existsSync(),
      isTrue,
      reason: 'missing $fixturePath — copy it from the bisaas checkout at '
          'docs/mobileapp/offline_kernel_golden_vectors.json',
    );
    return jsonDecode(file.readAsStringSync(encoding: utf8))
        as Map<String, dynamic>;
  }

  test('every committed decision vector is reproduced by the simulator', () {
    final vectors = loadVectors();
    final decisions = vectors['decisions']! as List<dynamic>;

    expect(decisions, isNotEmpty);

    var checked = 0;
    var withChosenKey = 0;

    for (final raw in decisions) {
      final vector = raw as Map<String, dynamic>;
      final request = vector['request']! as Map<String, dynamic>;
      final expected = vector['expected']! as Map<String, dynamic>;

      // One roster, one opponent, built from the vector's own request. This is
      // the inverse of what the simulator does in production, so any mismatch in
      // how it maps fields surfaces here.
      final roster = OfflineBotRoster.fromJson(<String, dynamic>{
        'manifest_id': '3f2504e0-4f89-41d3-9a0c-0305e82c3301',
        'seed': request['seed'],
        'pack_day': '2026-10-04',
        'kernel_version': botDecisionKernelVersion,
        'size': 1,
        'opponents': <Map<String, dynamic>>[
          <String, dynamic>{
            'bot_key': request['bot_key'],
            'display_name': 'Probe',
            'difficulty': 'intermediate',
            'personality': 'balanced',
            'accuracy_rate': request['accuracy_percent'],
            'min_answer_ms': request['min_answer_ms'],
            'max_answer_ms': request['max_answer_ms'],
            'misconception_code': 'probe',
            'disclosed_as_ai': true,
          },
        ],
      })!;

      final questionId = request['question_id']! as int;
      final position = request['question_index']! as int;
      final preferred = request['preferred_wrong_answer_key'] as String?;

      final receipt = OfflineMatchSimulator.simulate(
        roster: roster,
        questions: <OfflineMatchQuestion>[
          OfflineMatchQuestion(id: questionId, position: position),
        ],
        misconceptionTargets: <int, Map<String, String>>{
          if (preferred != null) questionId: <String, String>{'probe': preferred},
        },
      );

      expect(receipt.decisions, hasLength(1));
      final got = receipt.decisions.single;

      final label = 'seed=${request['seed']} bot=${request['bot_key']} '
          'q=$questionId idx=$position acc=${request['accuracy_percent']}';

      expect(got.questionId, questionId, reason: label);
      expect(got.questionIndex, position, reason: label);
      expect(got.answeredCorrectly, expected['answered_correctly'], reason: label);
      expect(got.durationMs, expected['duration_ms'], reason: label);
      expect(got.chosenAnswerKey, expected['chosen_answer_key'], reason: label);

      if (expected['chosen_answer_key'] != null) {
        withChosenKey++;
      }
      checked++;
    }

    expect(checked, greaterThan(400));

    // Precondition, not decoration: if the fixture's preferred key never
    // reached the simulator, the chosen_answer_key assertions above would all be
    // comparing null to null and would prove nothing.
    expect(
      withChosenKey,
      greaterThan(0),
      reason: 'no vector exercised a misconception-targeted wrong answer, so the '
          'chosen_answer_key comparison was vacuous',
    );
  });
}

/// Pinned inline rather than imported so this test cannot drift from the
/// contract by following a constant that someone edited.
const String botDecisionKernelVersion = 'bot-decision/v2';
