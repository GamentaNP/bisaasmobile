import 'package:bisaasmobile/features/numericals/domain/entities/numerical.dart';
import 'package:flutter_test/flutter_test.dart';

/// The behaviour that matters here is the one the server enforces by omission:
/// `POST /numericals/{id}/answer-checks` returns `final_answer` **only when the
/// answer was correct**. A client that kept, cached or recomputed that value
/// would turn the practice surface into an answer oracle, so these tests pin the
/// withholding rather than the arithmetic — the arithmetic is server-side and the
/// client never sees it.
void main() {
  group('NumericalCheck never leaks a withheld answer', () {
    test('a wrong attempt has no final answer', () {
      const check = NumericalCheck(correct: false, finalAnswer: null, unit: 'kN');
      expect(check.correct, isFalse);
      expect(check.finalAnswer, isNull);
      expect(check.revealsAnswer, isFalse);
    });

    test('the outcome label for a wrong attempt states no value', () {
      const check = NumericalCheck(correct: false, unit: 'kN');
      expect(check.outcomeLabel, isNot(contains('kN')));
      expect(check.outcomeLabel, contains('Not correct'));
    });

    test('a correct attempt reveals the answer and the unit', () {
      const check = NumericalCheck(correct: true, finalAnswer: 12.5, unit: 'kN');
      expect(check.revealsAnswer, isTrue);
      expect(check.outcomeLabel, contains('12.5'));
      expect(check.outcomeLabel, contains('kN'));
    });

    test('a correct attempt with no value still says Correct', () {
      // Defensive: a server change that omitted the number must not produce
      // "Correct · null".
      const check = NumericalCheck(correct: true, finalAnswer: null);
      expect(check.revealsAnswer, isFalse);
      expect(check.outcomeLabel, 'Correct');
    });

    test('a missing unit does not leave a dangling separator', () {
      const check = NumericalCheck(correct: true, finalAnswer: 3);
      expect(check.unitSuffix, isEmpty);
      expect(check.outcomeLabel.trim(), 'Correct · 3');
      expect(check.outcomeLabel, isNot(endsWith(' ')));
    });

    test('needsReview is surfaced so a flagged answer is not treated as verified', () {
      const flagged = NumericalCheck(correct: true, finalAnswer: 5, needsReview: true);
      expect(flagged.needsReview, isTrue);
    });
  });

  group('formatNumber reads like an engineering answer', () {
    test('a whole value loses the trailing .0 that Dart would print', () {
      expect(formatNumber(3), '3');
      expect(formatNumber(12), '12');
      expect(formatNumber(-4), '-4');
    });

    test('a genuine fraction keeps its digits', () {
      expect(formatNumber(12.5), '12.5');
    });

    test('a tiny non-integral value keeps its decimals', () {
      expect(formatNumber(0.125), '0.125');
    });

    test('a non-finite value is printed as-is rather than formatted', () {
      expect(formatNumber(double.nan), 'NaN');
      expect(formatNumber(double.infinity), 'Infinity');
    });
  });

  group('Numerical', () {
    test('a problem with no steps says so rather than showing an empty solution', () {
      const n = Numerical(numericalId: 1, statement: 'Find the reaction');
      expect(n.hasSteps, isFalse);
    });

    test('a problem with steps reports them', () {
      const n = Numerical(
        numericalId: 1,
        statement: 'x',
        steps: ['Take moments', 'Solve'],
      );
      expect(n.hasSteps, isTrue);
    });

    test('a blank calculator link is treated as no link', () {
      const n = Numerical(numericalId: 1, statement: 'x', civilCalLink: '   ');
      expect(n.hasLink, isFalse, reason: 'a whitespace URL would throw on parse');
    });

    test('a real calculator link is offered', () {
      const n = Numerical(
        numericalId: 1,
        statement: 'x',
        civilCalLink: 'civilcal://calculator?fn=beam',
      );
      expect(n.hasLink, isTrue);
    });

    test('an empty parameter set is valid', () {
      const n = Numerical(numericalId: 1, statement: 'x');
      expect(n.parameters, isEmpty);
    });
  });
}
