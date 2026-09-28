/// Deterministic numericals — server-solved practice problems.
///
/// ## The one rule that matters
///
/// `POST /numericals/{id}/answer-checks` returns `final_answer` **only when the
/// answer was correct**. On a wrong attempt it is `null`, on purpose: a client
/// that cached or displayed the answer from a failed attempt would have turned
/// the practice surface into an answer oracle. [NumericalCheck.finalAnswer] is
/// therefore nullable and the UI must not substitute anything for it.
library;

import 'package:flutter/foundation.dart';

@immutable
class Numerical {
  const Numerical({
    required this.numericalId,
    required this.statement,
    this.parameters = const {},
    this.unit,
    this.difficulty,
    this.steps = const [],
    this.finalAnswer,
    this.computedBy,
    this.needsReview = false,
    this.civilCalLink,
  });

  final int numericalId;

  /// The problem text. Server-authored, and the most likely place in the app for
  /// mixed-script content, so the reader resolves its font from this string.
  final String statement;

  /// Randomised values for this instance, keyed by parameter name.
  final Map<String, double> parameters;
  final String? unit;
  final double? difficulty;

  /// Worked solution. Only present from a solve attempt, never from a check.
  final List<String> steps;
  final double? finalAnswer;

  /// How the server produced the solution. Surfaced verbatim, because a value
  /// computed by a model is not the same claim as one computed by a formula.
  final String? computedBy;

  /// The server's own flag that this problem's solution needs review. A
  /// needs-review result must not be presented as a verified worked answer.
  final bool needsReview;

  /// Deep link into the CivilCal calculator with these parameters prefilled.
  final String? civilCalLink;

  bool get hasSteps => steps.isNotEmpty;

  /// Trimmed, because a whitespace-only link is not a link and would throw when
  /// parsed. The datasource trims too; this is the second guard.
  bool get hasLink => (civilCalLink ?? '').trim().isNotEmpty;
}

/// The result of grading one answer.
@immutable
class NumericalCheck {
  const NumericalCheck({
    required this.correct,
    this.finalAnswer,
    this.unit,
    this.computedBy,
    this.needsReview = false,
  });

  final bool correct;

  /// **Null unless [correct].** This is the server refusing to leak the answer
  /// after a wrong attempt.
  final double? finalAnswer;
  final String? unit;
  final String? computedBy;
  final bool needsReview;

  /// The answer is available exactly when the attempt was correct.
  bool get revealsAnswer => correct && finalAnswer != null;

  /// A message that never states a value the server withheld.
  String get outcomeLabel => correct
      ? (finalAnswer == null
          ? 'Correct'
          : 'Correct · ${formatNumber(finalAnswer!)}$unitSuffix')
      : 'Not correct. Try again or view the worked solution.';

  String get unitSuffix => unit == null ? '' : ' $unit';
}

/// Renders a number the way an engineering answer should read.
///
/// Dart prints a whole-valued double as `3.0`, which reads like a bug in an
/// answer box, so an integral value loses the trailing `.0` while a genuinely
/// fractional one keeps its significant digits.
String formatNumber(double value) {
  if (!value.isFinite) return value.toString();
  if (value == value.roundToDouble() && value.abs() < 1e15) {
    return value.toStringAsFixed(0);
  }
  return value.toString();
}
