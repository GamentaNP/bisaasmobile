/// Numerical practice — server-solved, deterministic.
///
/// Routes verified against `routes/api/v1/numericals.php`:
///
/// - POST /numericals/{id}/randomizations   **Idempotency-Key** — a fresh set of
///   random parameters for the same problem
/// - POST /numericals/{id}/answer-checks    grade one answer. No key: it is a read
///   of a computation, not a mutation
/// - POST /numericals/{id}/solve-attempts   **Idempotency-Key** — full worked
///   solution, logged as an attempt
/// - GET  /numericals/{id}/civilcal-link    calculator deep link for this instance
///
/// All grading is server-side (`D-4/T-4`): the client never evaluates a formula.
/// Sending no key on answer-checks is deliberate — the server does not require
/// one, and adding one would make a retry look like a new attempt.
library;

import 'package:dio/dio.dart';
import 'package:uuid/uuid.dart';

import '../../domain/entities/numerical.dart';

class NumericalRemoteDataSource {
  const NumericalRemoteDataSource(this._dio);
  final Dio _dio;

  static const _uuid = Uuid();

  Map<String, dynamic>? _data(Map<String, dynamic>? body) {
    if (body == null) return null;
    final data = body['data'];
    if (data is Map<String, dynamic>) return data;
    return null;
  }

  Map<String, double> _parameters(Object? json) {
    if (json is! Map) return const {};
    final out = <String, double>{};
    for (final entry in json.entries) {
      final key = entry.key.toString();
      final v = entry.value;
      if (v is num) {
        out[key] = v.toDouble();
      } else {
        // The controller types parameters as `array<string, float|int|string>`,
        // so a string is possible and must not be dropped.
        final parsed = double.tryParse(v.toString());
        if (parsed != null) out[key] = parsed;
      }
    }
    return out;
  }

  List<String> _steps(Object? json) {
    if (json is! List) return const [];
    return json.map((e) => e.toString()).where((e) => e.trim().isNotEmpty).toList();
  }

  Numerical? _numerical(Map<String, dynamic>? data) {
    if (data == null) return null;
    final id = data['numerical_id'];
    final statement = data['statement']?.toString().trim();
    if (id is! int || statement == null || statement.isEmpty) return null;
    final answer = data['final_answer'];
    return Numerical(
      numericalId: id,
      statement: statement,
      parameters: _parameters(data['parameters'] as Map<String, dynamic>?),
      unit: data['unit']?.toString(),
      difficulty: data['difficulty'] is num ? (data['difficulty'] as num).toDouble() : null,
      steps: _steps(data['steps']),
      finalAnswer: answer is num ? answer.toDouble() : double.tryParse('$answer'),
      computedBy: data['computed_by']?.toString(),
      needsReview: data['needs_review'] == true,
      civilCalLink: data['civilcal_link']?.toString(),
    );
  }

  /// A new randomisation of the same problem.
  Future<Numerical?> randomize(int numericalId) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/numericals/$numericalId/randomizations',
      options: Options(headers: {'Idempotency-Key': _uuid.v4()}),
    );
    return _numerical(_data(res.data));
  }

  /// Grades an answer. The server withholds `final_answer` unless correct, and
  /// this does not fabricate a substitute.
  Future<NumericalCheck?> checkAnswer(int numericalId, double answer) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/numericals/$numericalId/answer-checks',
      data: {'answer': answer},
    );
    final data = _data(res.data);
    if (data == null) return null;
    final correct = data['correct'];
    if (correct is! bool) return null;
    final value = data['final_answer'];
    return NumericalCheck(
      correct: correct,
      // Only taken from the response. Never computed locally, never carried over
      // from a previous attempt.
      finalAnswer: correct && value is num ? value.toDouble() : null,
      unit: data['unit']?.toString(),
      computedBy: data['computed_by']?.toString(),
      needsReview: data['needs_review'] == true,
    );
  }

  /// The full worked solution. This is a logged attempt, so the client shows it
  /// as a solution the user has now consumed, not as an unanswered exercise.
  Future<Numerical?> solve(int numericalId, {Map<String, double>? parameters}) async {
    final res = await _dio.post<Map<String, dynamic>>(
      '/numericals/$numericalId/solve-attempts',
      data: {'parameters': ?parameters},
      options: Options(headers: {'Idempotency-Key': _uuid.v4()}),
    );
    return _numerical(_data(res.data));
  }

  Future<String?> getCivilCalLink(int numericalId, {Map<String, double>? parameters}) async {
    final res = await _dio.get<Map<String, dynamic>>(
      '/numericals/$numericalId/civilcal-link',
      queryParameters: parameters?.map((k, v) => MapEntry(k, v.toString())),
    );
    final data = _data(res.data);
    final link = data?['civilcal_link'] ?? data?['link'] ?? data?['url'];
    return link is String && link.trim().isNotEmpty ? link.trim() : null;
  }
}
