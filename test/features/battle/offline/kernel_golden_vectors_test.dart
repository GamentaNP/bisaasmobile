import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:bisaasmobile/features/battle/domain/offline/bot_decision_kernel.dart';
import 'package:bisaasmobile/features/battle/domain/offline/deterministic_draw.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter_test/flutter_test.dart';

/// ## What this test is for
///
/// Offline play has the phone simulate bot opponents with no connection. The
/// server verifies those matches afterwards by replaying its own PHP copy of
/// this algorithm. A single disagreeing draw quarantines every honest offline
/// user as a fraudster — silently, and hardest on the people least able to
/// report it. So this test asserts the Dart port against the server's own
/// committed vectors, case by case.
///
/// ## Why the expected values are never written out by hand
///
/// The vectors are read from the server's golden-vector file, copied verbatim
/// into `fixtures/`. Transcribing 280 expected numbers by hand would recreate
/// exactly the class of error this test exists to catch: a plausible-looking
/// constant copied wrongly, or "adjusted" until the test went green. Every
/// expectation below is therefore derived from the file at runtime.
///
/// The fixture's SHA-256 is
/// `6b1b06dec4a987a5d657c3ce8616d25a9a3171d77b498643629c7a6ff696e8ff`.
///
/// ## Why the fixture is committed instead of read across repos
///
/// `test/app/corpus_entry_point_test.dart` reads from the sibling `bisaas`
/// checkout and *skips* the assertion when it is absent, which is right for a
/// reachability guard. It would be wrong here: a skipped parity test reports
/// green while checking nothing, which is the same silent-quarantine failure
/// wearing a different hat. So the vectors are vendored and always asserted, and
/// a separate drift guard fails if the vendored copy ever diverges from the
/// server's file when both are present.

const String _fixturePath =
    'test/features/battle/offline/fixtures/offline_kernel_golden_vectors.json';

const String _fixtureSha256 =
    '6b1b06dec4a987a5d657c3ce8616d25a9a3171d77b498643629c7a6ff696e8ff';

const String _serverRelativePath =
    'docs/mobileapp/offline_kernel_golden_vectors.json';

Map<String, Object?> _loadVectors() {
  final file = File(_fixturePath);
  if (!file.existsSync()) {
    throw StateError(
      'Golden vectors missing at ${file.absolute.path}. '
      'Copy $_serverRelativePath from the bisaas checkout into $_fixturePath. '
      'This test deliberately fails instead of skipping: a parity test that '
      'skips is a parity test that passes without checking anything.',
    );
  }
  return _requireMap(jsonDecode(file.readAsStringSync(encoding: utf8)), 'root');
}

Map<String, Object?> _requireMap(Object? value, String context) {
  if (value is Map<String, Object?>) return value;
  throw FormatException('$context must be a JSON object');
}

List<Object?> _requireList(Object? value, String context) {
  if (value is List<Object?>) return value;
  throw FormatException('$context must be a JSON array');
}

int _requireInt(Object? value, String context) {
  if (value is int) return value;
  throw FormatException('$context must be an integer, got ${value.runtimeType}');
}

String _requireString(Object? value, String context) {
  if (value is String) return value;
  throw FormatException('$context must be a string, got ${value.runtimeType}');
}

String? _requireNullableString(Object? value, String context) {
  if (value == null || value is String) return value as String?;
  throw FormatException('$context must be a string or null');
}

bool _requireBool(Object? value, String context) {
  if (value is bool) return value;
  throw FormatException('$context must be a boolean, got ${value.runtimeType}');
}

/// Same big-endian decode as [DeterministicDraw.value], written out again
/// independently via [ByteData] with an explicit [Endian.big].
///
/// If these two ever disagree the shortcut in [DeterministicDraw.value] is
/// wrong, and this is the cross-check that says so rather than the 280 vectors
/// quietly failing.
int _referenceValue(String drawSeed, String label) {
  final input = <int>[
    ...utf8.encode(drawSeed),
    0x00,
    ...utf8.encode(label),
  ];
  final bytes = sha256.convert(input).bytes;
  return ByteData.sublistView(Uint8List.fromList(bytes)).getUint32(
        0,
        Endian.big,
      );
}

/// The decode [DeterministicDraw.value] must **not** be doing: little-endian.
///
/// Used to prove the endianness trap cannot pass silently. [ByteData.getUint32]
/// defaults to [Endian.host], which is little-endian on every mainstream target,
/// and the result is still an in-range plausible number — so an accidental
/// endianness flip would not look like a bug at all.
int _littleEndianValue(String drawSeed, String label) {
  final input = <int>[
    ...utf8.encode(drawSeed),
    0x00,
    ...utf8.encode(label),
  ];
  final bytes = sha256.convert(input).bytes;
  return ByteData.sublistView(Uint8List.fromList(bytes)).getUint32(
        0,
        Endian.little,
      );
}

int _scale(int raw, int min, int max) => min + (raw * (max - min + 1) ~/ 0x100000000);

/// Exact floor of `raw * span / 2^32`, computed with [BigInt].
///
/// [BigInt] has arbitrary precision, so this is the same arithmetic PHP does
/// with its 64-bit ints and it shares no code path with [DeterministicDraw]'s
/// `~/`. Using it as an oracle removes the circularity of checking `~/` against
/// another `~/`.
///
/// This is the only assertion in the suite that can observe floor semantics.
/// The 280 golden vectors cannot: at every magnitude they exercise, the widest
/// product is about `4.8e13`, well inside the `2^53` a double holds exactly, so
/// `~/` and `/`+truncation return identical values and a float-division
/// regression would sail through the whole parity suite. Verified by mutation:
/// swapping `~/` for `/` leaves all 280 vectors passing.
int _exactFloor(int raw, int min, int max) {
  final span = BigInt.from(max - min + 1);
  return min + (BigInt.from(raw) * span ~/ BigInt.from(0x100000000)).toInt();
}

/// What a *rounding* division would return instead of flooring.
///
/// Only used to establish that floor semantics are actually observable in the
/// committed vectors. A draw in the upper half of its bucket rounds up, so a
/// regression to `round()` instead of floor changes the answer.
int _rounded(int raw, int min, int max) {
  final span = BigInt.from(max - min + 1);
  final scaled = BigInt.from(raw) * span;
  final modulus = BigInt.from(0x100000000);
  return min + ((scaled + (modulus >> 1)) ~/ modulus).toInt();
}

void main() {
  final vectors = _loadVectors();

  group('golden vector file contract', () {
    test('declares the kernel version this port implements', () {
      expect(
        _requireString(vectors['kernel_version'], 'kernel_version'),
        BotDecisionKernel.version,
        reason: 'Server bumped kernel_version; this port is still '
            '${BotDecisionKernel.version}. A v2 client must not silently '
            'play v3 rules.',
      );
    });

    test('carries 10 draw probes and 450 decisions', () {
      expect(_requireList(vectors['draws'], 'draws'), hasLength(10));
      expect(_requireList(vectors['decisions'], 'decisions'), hasLength(450));
    });

    test('covers the 750ms duration floor from the contract itself', () {
      // The contract now carries two sub-750 windows — (400,1200) and (200,600)
      // — so the server's MIN_DURATION_MS is pinned by the golden vectors and
      // not only by the hand-written cases further down this file. Those
      // sub-floor cases were added after a review found that a sweep of
      // realistic windows (all already at or above 750) left the clamp
      // completely untested: a kernel that deleted the floor reproduced all 270
      // original decisions perfectly.
      //
      // This assertion is what stops the coverage silently evaporating again if
      // the vectors are ever regenerated from a narrower sweep.
      final decisions = _requireList(vectors['decisions'], 'decisions');

      var subFloorCount = 0;
      int? collapsedIndex;

      for (var i = 0; i < decisions.length; i++) {
        final request =
            _requireMap(_requireMap(decisions[i], 'decision')['request'], 'request');
        final min = request['min_answer_ms']! as int;
        final max = request['max_answer_ms']! as int;

        if (min < 750 || max < 750) {
          subFloorCount++;
        }
        if (min < 750 && max < 750 && collapsedIndex == null) {
          collapsedIndex = i;
        }
      }

      expect(
        subFloorCount,
        greaterThan(0),
        reason: 'No vector exercises the 750ms floor. A kernel that dropped '
            'MIN_DURATION_MS would reproduce every vector in this file, and '
            'this suite would still report green.',
      );

      expect(
        collapsedIndex,
        isNotNull,
        reason: 'No wholly sub-750 window in the contract, so the case where '
            'both bounds clamp and the range collapses to exactly the floor is '
            'unpinned.',
      );

      final expected = _requireMap(
        _requireMap(decisions[collapsedIndex!], 'decision')['expected'],
        'expected',
      );
      expect(
        expected['duration_ms'],
        750,
        reason: 'A window entirely below the floor must collapse to exactly '
            'the floor, not to some other value.',
      );
    });

    test('vendored copy is byte-identical to the server file', () {
      final bytes = File(_fixturePath).readAsBytesSync();
      expect(
        sha256.convert(bytes).toString(),
        _fixtureSha256,
        reason: 'The vendored vectors were edited or re-saved. They are the '
            "server's contract and must be copied verbatim from "
            '$_serverRelativePath, never regenerated or reformatted.',
      );
    });

    test('has not drifted from the sibling server checkout', () {
      // Unlike the parity assertions above, this one may legitimately skip: on a
      // CI runner there is no sibling checkout to compare against. When the file
      // IS present, a mismatch is a hard failure.
      const roots = <String>[
        'C:/laragon/www/bisaas',
        '../bisaas',
      ];
      File? serverCopy;
      for (final root in roots) {
        final candidate = File('$root/$_serverRelativePath');
        if (candidate.existsSync()) {
          serverCopy = candidate;
          break;
        }
      }
      if (serverCopy == null) {
        // ignore: avoid_print
        print('skipping drift guard: sibling bisaas checkout not found');
        return;
      }
      expect(
        serverCopy.readAsBytesSync(),
        File(_fixturePath).readAsBytesSync(),
        reason: 'The server regenerated $_serverRelativePath. Re-copy it into '
            '$_fixturePath before trusting the parity results.',
      );
    });

    test('misconception pools are shaped pool > questionId > code > optionKey', () {
      // Not consumed by the decision kernel (consensus logic is server-authoritative
      // and out of scope here). Asserted only so the whole contract file is covered
      // and a schema change fails loudly instead of being silently ignored.
      //
      // Note the shape is THREE levels deep — pool name, then question id, then
      // misconception code — even though the port brief described it as two. The
      // file is the authority; the extra level is a named pool ("fixed_example").
      final pools = _requireMap(vectors['misconception_pools'], 'pools');
      expect(pools, isNotEmpty, reason: 'no misconception pools in the contract');
      var questionCount = 0;
      for (final pool in pools.entries) {
        expect(pool.key, isNotEmpty, reason: 'pool name must not be empty');
        final questions = _requireMap(pool.value, 'pool ${pool.key}');
        expect(questions, isNotEmpty, reason: 'pool ${pool.key} is empty');
        for (final question in questions.entries) {
          questionCount++;
          expect(
            int.tryParse(question.key),
            isNotNull,
            reason: 'question id ${question.key} is not numeric',
          );
          final codes = _requireMap(question.value, 'q ${question.key}');
          expect(codes, isNotEmpty, reason: 'q ${question.key} has no codes');
          for (final code in codes.entries) {
            expect(code.key, isNotEmpty, reason: 'misconception code is empty');
            expect(
              _requireString(code.value, 'option for ${code.key}'),
              isNotEmpty,
              reason: 'option key must not be empty',
            );
          }
        }
      }
      expect(questionCount, greaterThan(0));
    });
  });

  group('draw primitive vectors', () {
    final draws = _requireList(vectors['draws'], 'draws');

    for (var i = 0; i < draws.length; i++) {
      test('draws[$i]', () {
        final vector = _requireMap(draws[i], 'draws[$i]');
        final drawSeed = _requireString(vector['draw_seed'], 'draw_seed');
        final label = _requireString(vector['label'], 'label');
        final min = _requireInt(vector['min'], 'min');
        final max = _requireInt(vector['max'], 'max');
        final expected = _requireInt(vector['value'], 'value');

        expect(
          DeterministicDraw.draw(drawSeed, label, min: min, max: max),
          expected,
          reason: 'draws[$i] seed=$drawSeed label=$label range=$min..$max',
        );
      });
    }

    test('every vector agrees with an independent big-endian ByteData decode',
        () {
      for (var i = 0; i < draws.length; i++) {
        final vector = _requireMap(draws[i], 'draws[$i]');
        final drawSeed = _requireString(vector['draw_seed'], 'draw_seed');
        final label = _requireString(vector['label'], 'label');
        expect(
          DeterministicDraw.value(drawSeed, label),
          _referenceValue(drawSeed, label),
          reason: 'draws[$i]: shift-based decode must match ByteData big-endian',
        );
      }
    });

    test('every discriminating vector rules out a little-endian decode', () {
      // Guards the endianness trap directly: if a future refactor reached for
      // ByteData.getUint32 without Endian.big, this is what catches it.
      //
      // draws[8] is min==max (span 1), so it returns 1 under ANY byte order and
      // cannot discriminate. It is excluded rather than waived, because a
      // single-value range genuinely carries no endianness information.
      var checked = 0;
      var skipped = 0;
      for (var i = 0; i < draws.length; i++) {
        final vector = _requireMap(draws[i], 'draws[$i]');
        final drawSeed = _requireString(vector['draw_seed'], 'draw_seed');
        final label = _requireString(vector['label'], 'label');
        final min = _requireInt(vector['min'], 'min');
        final max = _requireInt(vector['max'], 'max');
        final expected = _requireInt(vector['value'], 'value');
        if (max == min) {
          skipped++;
          continue;
        }
        checked++;
        expect(
          DeterministicDraw.draw(drawSeed, label, min: min, max: max),
          isNot(_scale(_littleEndianValue(drawSeed, label), min, max)),
          reason: 'draws[$i] would also pass under a little-endian read, so it '
              'cannot discriminate endianness',
        );
        expect(
          DeterministicDraw.draw(drawSeed, label, min: min, max: max),
          expected,
          reason: 'draws[$i]',
        );
      }
      expect(
        checked,
        greaterThanOrEqualTo(draws.length - 1),
        reason: 'at most the single-value vectors may be skipped',
      );
      expect(skipped, lessThanOrEqualTo(1));
    });

    test('the NUL separator is load-bearing on every discriminating vector', () {
      // Substituting any other separator changes the digest input, so it must
      // not reproduce the expected value. Two honest limits of the vector set:
      //
      //  * draws[8] (span 1) returns 1 regardless of what is hashed, so it can
      //    never discriminate.
      //  * draws[5] (span 3, values 0..2) collides once by chance under a
      //    single-space separator. A 3-wide bucket has a 1-in-3 hit rate, so no
      //    test can rule that substitution out on that vector alone.
      //
      // Both are excluded rather than papered over. '|' is the realistic bug —
      // the seed itself is pipe-joined, so dropping the NUL for a '|' is exactly
      // what a careless port would do — and it is ruled out by every vector.
      var checked = 0;
      for (var i = 0; i < draws.length; i++) {
        final vector = _requireMap(draws[i], 'draws[$i]');
        final drawSeed = _requireString(vector['draw_seed'], 'draw_seed');
        final label = _requireString(vector['label'], 'label');
        final min = _requireInt(vector['min'], 'min');
        final max = _requireInt(vector['max'], 'max');
        final expected = _requireInt(vector['value'], 'value');
        if (max == min) {
          continue;
        }
        for (final separator in <String>['', '|', ':']) {
          final bytes = sha256.convert(<int>[
            ...utf8.encode(drawSeed),
            ...utf8.encode(separator),
            ...utf8.encode(label),
          ]).bytes;
          final raw = ByteData.sublistView(Uint8List.fromList(bytes))
              .getUint32(0, Endian.big);
          expect(
            _scale(raw, min, max),
            isNot(expected),
            reason: 'draws[$i] would also pass with "$separator" in place of the '
                'NUL separator',
          );
        }
        checked++;
      }
      expect(checked, greaterThanOrEqualTo(draws.length - 1));

      // The space probe is only reliable on wide ranges, so it is scoped there.
      for (var i = 0; i < draws.length; i++) {
        final vector = _requireMap(draws[i], 'draws[$i]');
        final min = _requireInt(vector['min'], 'min');
        final max = _requireInt(vector['max'], 'max');
        if (max - min + 1 < 100) continue;
        final drawSeed = _requireString(vector['draw_seed'], 'draw_seed');
        final label = _requireString(vector['label'], 'label');
        final expected = _requireInt(vector['value'], 'value');
        final bytes = sha256.convert(<int>[
          ...utf8.encode(drawSeed),
          ...utf8.encode(' '),
          ...utf8.encode(label),
        ]).bytes;
        final raw =
            ByteData.sublistView(Uint8List.fromList(bytes)).getUint32(0, Endian.big);
        expect(_scale(raw, min, max), isNot(expected), reason: 'draws[$i]');
      }
    });

    test('every draw agrees with an exact BigInt floor', () {
      // Checks the arithmetic against an oracle that shares no code path with
      // the implementation: [BigInt] has arbitrary precision, exactly like the
      // server's 64-bit ints, whereas `~/` and `/` both live in the machine
      // numeric tower.
      var roundingSensitive = 0;
      for (var i = 0; i < draws.length; i++) {
        final vector = _requireMap(draws[i], 'draws[$i]');
        final drawSeed = _requireString(vector['draw_seed'], 'draw_seed');
        final label = _requireString(vector['label'], 'label');
        final min = _requireInt(vector['min'], 'min');
        final max = _requireInt(vector['max'], 'max');
        final raw = DeterministicDraw.value(drawSeed, label);
        final exact = _exactFloor(raw, min, max);

        expect(
          DeterministicDraw.draw(drawSeed, label, min: min, max: max),
          exact,
          reason: 'draws[$i] must floor, not round or ceil',
        );

        if (exact != _rounded(raw, min, max)) {
          roundingSensitive++;
          expect(
            _rounded(raw, min, max),
            isNot(exact),
            reason: 'draws[$i] is rounding-sensitive: a rounding division here '
                'would have produced ${_rounded(raw, min, max)} instead of $exact',
          );
        }
      }
      // Guards the guard: if no vector were rounding-sensitive, this suite would
      // not actually pin floor semantics and the assertion above would be
      // vacuous. Four of the ten draw probes land in the upper half of a bucket.
      expect(
        roundingSensitive,
        greaterThanOrEqualTo(4),
        reason: 'the draw probes must include rounding-sensitive vectors or the '
            'floor semantics are untested',
      );
    });

    test('the span guard refuses ranges a web build cannot hold exactly', () {
      // On web, ints are doubles, so a product past 2^53 silently loses
      // precision and returns a plausible wrong answer. Failing loudly is the
      // only safe option, and this is the branch that does it.
      //
      // The boundary is 2^21, not 2^53: it is the *product* `value * span` that
      // must stay exact, and value can reach 2^32 - 1. Guarding the span against
      // 2^53 instead would be too permissive by a factor of ~4.3e9 and would let
      // exactly the silent-wrong-answer case through.
      expect(
        () => DeterministicDraw.draw('s', 'duration', min: 0, max: 0x1FFFFF),
        returnsNormally,
        reason: 'a span of 2^21 gives a worst-case product of 9007199252643840, '
            'which is within 2^53',
      );
      expect(
        () => DeterministicDraw.draw('s', 'duration', min: 0, max: 0x200000),
        throwsRangeError,
        reason: 'a span of 2^21 + 1 pushes the worst-case product past 2^53',
      );
      // The widest window the kernel actually uses, for scale.
      expect(
        () => DeterministicDraw.draw('s', 'duration', min: 750, max: 12000),
        returnsNormally,
      );
    });

    test('the accented seed only resolves under UTF-8', () {
      // draws[9] is a deliberately non-ASCII seed ("...séed|böt:5|1|9").
      // UTF-16, Latin-1 and code-unit truncation each produce a different digest,
      // so this pins the encoding without transcribing a constant.
      final vector = _requireMap(draws[9], 'draws[9]');
      final drawSeed = _requireString(vector['draw_seed'], 'draw_seed');
      final label = _requireString(vector['label'], 'label');
      final min = _requireInt(vector['min'], 'min');
      final max = _requireInt(vector['max'], 'max');
      final expected = _requireInt(vector['value'], 'value');
      expect(drawSeed.runes.any((r) => r > 0x7F), isTrue,
          reason: 'draws[9] must contain non-ASCII to be meaningful here');

      final utf16Raw = ByteData.sublistView(
        Uint8List.fromList(sha256.convert(<int>[
          ..._utf16CodeUnits(drawSeed),
          0x00,
          ..._utf16CodeUnits(label),
        ]).bytes),
      ).getUint32(0, Endian.big);
      expect(
        _scale(utf16Raw, min, max),
        isNot(expected),
        reason: 'UTF-16 encoding must not reproduce the vector',
      );
      expect(
        DeterministicDraw.draw(drawSeed, label, min: min, max: max),
        expected,
      );
    });

    test('utf16 code-unit expansion is what the UTF-8 path must not do', () {
      // Guards the helper itself, so the assertion above cannot pass for the
      // wrong reason (e.g. an encoder that silently returned UTF-8 bytes).
      final units = _utf16CodeUnits('é');
      expect(units.length, 2);
      expect(units, <int>[0xE9, 0x00]);
      expect(utf8.encode('é').length, 2);
      expect(utf8.encode('é'), isNot(<int>[0xE9, 0x00]));
    });
  });

  group('bot decision vectors', () {
    final decisions = _requireList(vectors['decisions'], 'decisions');

    for (var i = 0; i < decisions.length; i++) {
      test('decisions[$i]', () {
        final vector = _requireMap(decisions[i], 'decisions[$i]');
        final r = _requireMap(vector['request'], 'request');
        final e = _requireMap(vector['expected'], 'expected');

        final request = BotDecisionRequest(
          seed: _requireString(r['seed'], 'seed'),
          botKey: _requireString(r['bot_key'], 'bot_key'),
          questionIndex: _requireInt(r['question_index'], 'question_index'),
          questionId: _requireInt(r['question_id'], 'question_id'),
          accuracyPercent: _requireInt(r['accuracy_percent'], 'accuracy'),
          minAnswerMs: _requireInt(r['min_answer_ms'], 'min_answer_ms'),
          maxAnswerMs: _requireInt(r['max_answer_ms'], 'max_answer_ms'),
          preferredWrongAnswerKey:
              _requireNullableString(r['preferred_wrong_answer_key'], 'pref'),
        );
        final actual = BotDecisionKernel.decide(request);

        expect(
          actual.answeredCorrectly,
          _requireBool(e['answered_correctly'], 'answered_correctly'),
          reason: 'decisions[$i] accuracy=${request.accuracyPercent} '
              'seed=${request.seed} bot=${request.botKey} '
              'q=${request.questionIndex}/${request.questionId}',
        );
        expect(
          actual.durationMs,
          _requireInt(e['duration_ms'], 'duration_ms'),
          reason: 'decisions[$i] window=${request.minAnswerMs}..'
              '${request.maxAnswerMs}',
        );
        expect(
          actual.chosenAnswerKey,
          _requireNullableString(e['chosen_answer_key'], 'chosen_answer_key'),
          reason: 'decisions[$i]',
        );
      });
    }

    test('a correct answer never reports a chosen key, and vice versa', () {
      for (var i = 0; i < decisions.length; i++) {
        final vector = _requireMap(decisions[i], 'decisions[$i]');
        final e = _requireMap(vector['expected'], 'expected');
        final correct = _requireBool(e['answered_correctly'], 'correct');
        final chosen = _requireNullableString(e['chosen_answer_key'], 'chosen');
        if (correct) {
          expect(chosen, isNull, reason: 'decisions[$i] is correct but has a key');
        } else {
          expect(chosen, isNotNull,
              reason: 'decisions[$i] is wrong but has no key');
        }
      }
    });

    test('every vector stays inside its effective answer window', () {
      // The bound checked is the *floored* window, not the requested one. The
      // kernel clamps both ends up to MIN_DURATION_MS (750ms) precisely so no
      // bot can report an implausible latency, which means a profile asking for
      // a 200-600ms window legitimately gets 750ms — above its requested
      // ceiling. Asserting against the raw window here would forbid the floor
      // from ever binding, which is the opposite of what the kernel promises.
      for (var i = 0; i < decisions.length; i++) {
        final vector = _requireMap(decisions[i], 'decisions[$i]');
        final r = _requireMap(vector['request'], 'request');
        final e = _requireMap(vector['expected'], 'expected');
        final min = _requireInt(r['min_answer_ms'], 'min');
        final max = _requireInt(r['max_answer_ms'], 'max');
        final duration = _requireInt(e['duration_ms'], 'duration');
        const floor = BotDecisionKernel.minimumAnswerWindowMs;
        expect(
          duration,
          inInclusiveRange(
            floor < min ? floor : min,
            floor > max ? floor : max,
          ),
          reason: 'decisions[$i] window=($min,$max) duration=$duration',
        );
      }
    });

    test('is deterministic across repeated evaluation', () {
      // A stray global PRNG would pass 280 vectors once and then drift. Repeat
      // each vector and require bit-identical output.
      for (var i = 0; i < decisions.length; i++) {
        final vector = _requireMap(decisions[i], 'decisions[$i]');
        final r = _requireMap(vector['request'], 'request');
        final request = BotDecisionRequest(
          seed: _requireString(r['seed'], 'seed'),
          botKey: _requireString(r['bot_key'], 'bot_key'),
          questionIndex: _requireInt(r['question_index'], 'question_index'),
          questionId: _requireInt(r['question_id'], 'question_id'),
          accuracyPercent: _requireInt(r['accuracy_percent'], 'accuracy'),
          minAnswerMs: _requireInt(r['min_answer_ms'], 'min'),
          maxAnswerMs: _requireInt(r['max_answer_ms'], 'max'),
          preferredWrongAnswerKey:
              _requireNullableString(r['preferred_wrong_answer_key'], 'pref'),
        );
        final first = BotDecisionKernel.decide(request);
        final second = BotDecisionKernel.decide(request);
        expect(second.answeredCorrectly, first.answeredCorrectly);
        expect(second.durationMs, first.durationMs);
        expect(second.chosenAnswerKey, first.chosenAnswerKey);
      }
    });

    test('accuracy bounds are exact: 0 never hits, 100 always hits', () {
      // The roll is 1..100, so 0 is an unconditional miss and 100 an
      // unconditional hit. Shifting the range to 0..99 would give every
      // 0%-accuracy bot a 1% chance of being right.
      for (var i = 0; i < decisions.length; i++) {
        final vector = _requireMap(decisions[i], 'decisions[$i]');
        final r = _requireMap(vector['request'], 'request');
        final accuracy = _requireInt(r['accuracy_percent'], 'accuracy');
        final request = BotDecisionRequest(
          seed: _requireString(r['seed'], 'seed'),
          botKey: _requireString(r['bot_key'], 'bot_key'),
          questionIndex: _requireInt(r['question_index'], 'question_index'),
          questionId: _requireInt(r['question_id'], 'question_id'),
          accuracyPercent: accuracy,
          minAnswerMs: _requireInt(r['min_answer_ms'], 'min'),
          maxAnswerMs: _requireInt(r['max_answer_ms'], 'max'),
          preferredWrongAnswerKey:
              _requireNullableString(r['preferred_wrong_answer_key'], 'pref'),
        );
        final roll = DeterministicDraw.draw(
          DeterministicDraw.seedFor(
            seed: request.seed,
            botKey: request.botKey,
            questionIndex: request.questionIndex,
            questionId: request.questionId,
          ),
          BotDecisionKernel.correctnessLabel,
          min: 1,
          max: 100,
        );
        expect(roll, inInclusiveRange(1, 100), reason: 'decisions[$i]');
        expect(BotDecisionKernel.isCorrect(request), roll <= accuracy);
        if (accuracy == 0) expect(roll <= 0, isFalse, reason: 'decisions[$i]');
        if (accuracy == 100) expect(roll <= 100, isTrue, reason: 'decisions[$i]');
      }
    });
  });

  group('seed composition', () {
    test('matches the documented join exactly', () {
      expect(
        DeterministicDraw.seedFor(
          seed: 'lobby:1',
          botKey: 'bot_e65b4cbd',
          questionIndex: 3,
          questionId: 1003,
        ),
        'lobby:1|bot_e65b4cbd|3|1003',
      );
    });

    test('shuffle label shape is preserved', () {
      expect(DeterministicDraw.shuffleLabel(5), 'shuffle:5');
    });
  });

  group('750ms answer-window floor', () {
    // Not covered by any committed vector: every vector window is already at or
    // above 750ms, so the clamp is indistinguishable from no clamp in the
    // golden set. These cases pin the documented rule directly, derived from the
    // spec rather than from a golden vector.
    test('a wholly sub-750 window collapses to exactly 750', () {
      final request = BotDecisionRequest(
        seed: 'lobby:1',
        botKey: 'bot_e65b4cbd',
        questionIndex: 0,
        questionId: 1000,
        accuracyPercent: 50,
        minAnswerMs: 100,
        maxAnswerMs: 200,
      );
      expect(BotDecisionKernel.drawDurationMs(request), 750);
    });

    test('a sub-750 minimum is raised while the maximum is kept', () {
      final request = BotDecisionRequest(
        seed: 'lobby:1',
        botKey: 'bot_e65b4cbd',
        questionIndex: 0,
        questionId: 1000,
        accuracyPercent: 50,
        minAnswerMs: 100,
        maxAnswerMs: 5000,
      );
      final clamped = BotDecisionKernel.drawDurationMs(request);
      expect(clamped, inInclusiveRange(750, 5000));
      // Prove the clamp changed the draw rather than passing by luck.
      final unclamped = DeterministicDraw.draw(
        DeterministicDraw.seedFor(
          seed: request.seed,
          botKey: request.botKey,
          questionIndex: request.questionIndex,
          questionId: request.questionId,
        ),
        BotDecisionKernel.durationLabel,
        min: 100,
        max: 5000,
      );
      expect(clamped, isNot(unclamped));
    });

    test('a window already at 750 is untouched', () {
      final request = BotDecisionRequest(
        seed: 'lobby:1',
        botKey: 'bot_e65b4cbd',
        questionIndex: 0,
        questionId: 1000,
        accuracyPercent: 50,
        minAnswerMs: 750,
        maxAnswerMs: 12000,
      );
      expect(
        BotDecisionKernel.drawDurationMs(request),
        DeterministicDraw.draw(
          'lobby:1|bot_e65b4cbd|0|1000',
          BotDecisionKernel.durationLabel,
          min: 750,
          max: 12000,
        ),
      );
    });
  });

  group('draw guards', () {
    test('rejects an inverted range', () {
      expect(
        () => DeterministicDraw.draw('s', 'duration', min: 900, max: 100),
        throwsArgumentError,
      );
    });

    test('a single-value range always returns that value', () {
      // Vectors[8] exercises this on the server side; assert it generally.
      expect(
        DeterministicDraw.draw('seed|bot:0|0|0', 'duration', min: 1, max: 1),
        1,
      );
    });

    test('results never exceed the closed range', () {
      final decisions = _requireList(vectors['decisions'], 'decisions');
      for (var i = 0; i < decisions.length; i++) {
        final vector = _requireMap(decisions[i], 'decisions[$i]');
        final r = _requireMap(vector['request'], 'request');
        final min = _requireInt(r['min_answer_ms'], 'min');
        final max = _requireInt(r['max_answer_ms'], 'max');
        expect(
          DeterministicDraw.draw(
            DeterministicDraw.seedFor(
              seed: _requireString(r['seed'], 'seed'),
              botKey: _requireString(r['bot_key'], 'bot_key'),
              questionIndex: _requireInt(r['question_index'], 'qi'),
              questionId: _requireInt(r['question_id'], 'qid'),
            ),
            BotDecisionKernel.durationLabel,
            min: min,
            max: max,
          ),
          inInclusiveRange(min, max),
          reason: 'decisions[$i]',
        );
      }
    });
  });
}

/// UTF-16 code units as raw bytes, i.e. the encoding the kernel must NOT use.
///
/// Deliberately lossy on purpose: this is a probe for "what would happen if
/// someone reached for `utf16.encode` or `String.codeUnits`", not a real codec.
List<int> _utf16CodeUnits(String value) {
  final out = <int>[];
  for (final unit in value.codeUnits) {
    out.add(unit & 0xFF);
    out.add((unit >> 8) & 0xFF);
  }
  return out;
}
