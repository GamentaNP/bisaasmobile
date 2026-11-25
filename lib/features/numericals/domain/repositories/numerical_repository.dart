import '../entities/numerical.dart';

/// Server-solved numerical practice.
///
/// Every grading decision stays on the server. This repository only carries
/// requests and results: it never evaluates a formula and never fills in an
/// answer the server withheld.
abstract class NumericalRepository {
  /// `POST /numericals/{id}/randomizations` (idempotent)
  Future<Numerical?> randomize(int numericalId);

  /// `POST /numericals/{id}/answer-checks`
  Future<NumericalCheck?> checkAnswer(int numericalId, double answer);

  /// `POST /numericals/{id}/solve-attempts` (idempotent, logged attempt)
  Future<Numerical?> solve(int numericalId, {Map<String, double>? parameters});

  /// `GET /numericals/{id}/civilcal-link`
  Future<String?> getCivilCalLink(int numericalId,
      {Map<String, double>? parameters});
}
