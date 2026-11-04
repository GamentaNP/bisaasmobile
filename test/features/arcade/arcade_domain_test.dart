/// The arcade's rules are a copy of the server's, and a copy can drift.
///
/// These tests pin the half that must not drift quietly: the wire value used
/// to parse a response, and the start path — which does *not* follow the wire
/// value (`true_false` starts at `/quiz/true-false/start`). Getting that wrong
/// 404s the only True/False button in the app.
library;

import 'package:bisaasmobile/features/arcade/domain/entities/arcade_mode.dart';
import 'package:bisaasmobile/features/arcade/domain/entities/arcade_result.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('ArcadeMode', () {
    test('every mode maps to the server start route that exists', () {
      expect(ArcadeMode.survival.startPath, '/quiz/survival/start');
      expect(ArcadeMode.lightning.startPath, '/quiz/lightning/start');
      expect(ArcadeMode.trueFalse.startPath, '/quiz/true-false/start');
    });

    test('the wire value is the enum value, not the route segment', () {
      expect(ArcadeMode.trueFalse.wire, 'true_false');
      expect(ArcadeMode.trueFalse.startPath, contains('true-false'));
    });

    test('fromWire round-trips and rejects an unknown mode', () {
      for (final mode in ArcadeMode.values) {
        expect(ArcadeMode.fromWire(mode.wire), mode);
      }
      expect(ArcadeMode.fromWire('guess_the_word'), isNull);
      expect(ArcadeMode.fromWire(null), isNull);
    });

    test('timed modes carry a per-question limit; survival does not', () {
      expect(ArcadeMode.survival.isTimed, isFalse);
      expect(ArcadeMode.lightning.secondsPerQuestion, 5);
      expect(ArcadeMode.trueFalse.secondsPerQuestion, 5);
    });

    test('only survival ends on a wrong answer', () {
      expect(ArcadeMode.survival.endsOnWrongAnswer, isTrue);
      expect(ArcadeMode.lightning.endsOnWrongAnswer, isFalse);
      expect(ArcadeMode.trueFalse.endsOnWrongAnswer, isFalse);
    });
  });

  group('ArcadeResult', () {
    test('accuracy is the server tally, and zero questions is not NaN', () {
      const empty = ArcadeResult(
        attemptId: 1,
        mode: 'survival',
        status: 'completed',
        score: 0,
        correctCount: 0,
        wrongCount: 0,
        skippedCount: 0,
      );
      expect(empty.accuracy, 0);

      const half = ArcadeResult(
        attemptId: 2,
        mode: 'lightning',
        status: 'completed',
        score: 40,
        correctCount: 5,
        wrongCount: 4,
        skippedCount: 1,
      );
      expect(half.answeredCount, 9);
      expect(half.totalCount, 10);
      expect(half.accuracy, 0.5);
    });
  });
}
