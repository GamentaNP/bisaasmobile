import '../../../../core/network/api_failure.dart';
import '../../domain/entities/sandbox_attempt.dart';

/// Strict wire parser for the finished guest-sandbox result read (§9.5).
///
/// Only the published verdict fields are read. A future response that leaked
/// an answer key would be ignored here; a drift that removed a required field
/// throws instead of producing an empty score card.
abstract final class _Parse {
  static Map<String, dynamic> map(Object? value, String key, String endpoint) {
    if (value is Map<String, dynamic>) return value;
    throw ContractViolation('Expected $key to be an object', endpoint: endpoint);
  }

  static List<Object?> list(Object? value, String key, String endpoint) {
    if (value is List) return value;
    throw ContractViolation('Expected $key to be a list', endpoint: endpoint);
  }

  static List<Map<String, dynamic>> rows(
    Object? value,
    String key,
    String endpoint,
  ) {
    return list(value, key, endpoint)
        .map((row) => map(row, '$key row', endpoint))
        .toList();
  }

  static int intOf(Object? value, String key, String endpoint) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    throw ContractViolation('Expected $key to be an int', endpoint: endpoint);
  }

  static double doubleOf(Object? value, String key, String endpoint) {
    if (value is num) return value.toDouble();
    throw ContractViolation('Expected $key to be a number', endpoint: endpoint);
  }

  static String string(Object? value, String key, String endpoint) {
    if (value is String && value.isNotEmpty) return value;
    throw ContractViolation('Expected $key to be a string', endpoint: endpoint);
  }

  static String? optionalString(Object? value, String key, String endpoint) {
    if (value == null) return null;
    if (value is String) return value;
    throw ContractViolation(
      'Expected $key to be a string or null',
      endpoint: endpoint,
    );
  }

  static bool boolOf(Object? value, String key, String endpoint) {
    if (value is bool) return value;
    throw ContractViolation('Expected $key to be a bool', endpoint: endpoint);
  }

  static bool? optionalBool(Object? value, String key, String endpoint) {
    if (value == null) return null;
    if (value is bool) return value;
    throw ContractViolation(
      'Expected $key to be a bool or null',
      endpoint: endpoint,
    );
  }
}

class SandboxAttemptDto {
  const SandboxAttemptDto({required this.data});
  final Map<String, dynamic> data;

  factory SandboxAttemptDto.fromJson(
    Map<String, dynamic> data, {
    String endpoint = '/social/sandbox/attempts/{attempt}',
  }) {
    final summary = _Parse.map(data['summary'], 'summary', endpoint);
    for (final key in <String>['correct', 'wrong', 'skipped', 'total']) {
      _Parse.intOf(summary[key], key, endpoint);
    }
    _Parse.doubleOf(summary['score'], 'score', endpoint);
    _Parse.rows(data['items'], 'items', endpoint);
    return SandboxAttemptDto(data: data);
  }

  SandboxAttemptResults toDomain({
    String endpoint = '/social/sandbox/attempts/{attempt}',
  }) {
    final summary = _Parse.map(data['summary'], 'summary', endpoint);

    return SandboxAttemptResults(
      summary: SandboxScoreSummary(
        score: _Parse.doubleOf(summary['score'], 'score', endpoint),
        correct: _Parse.intOf(summary['correct'], 'correct', endpoint),
        wrong: _Parse.intOf(summary['wrong'], 'wrong', endpoint),
        skipped: _Parse.intOf(summary['skipped'], 'skipped', endpoint),
        total: _Parse.intOf(summary['total'], 'total', endpoint),
      ),
      items: _Parse.rows(data['items'], 'items', endpoint)
          .map((row) => SandboxAttemptItem(
                questionId: _Parse.intOf(row['question_id'], 'question_id', endpoint),
                questionText: _Parse.string(row['question_text'], 'question_text', endpoint),
                isSkipped: _Parse.boolOf(row['is_skipped'], 'is_skipped', endpoint),
                type: _Parse.optionalString(row['type'], 'type', endpoint),
                options: row['options'] == null
                    ? const <Object?>[]
                    : _Parse.list(row['options'], 'options', endpoint),
                givenAnswer: row['given_answer'],
                isCorrect: _Parse.optionalBool(row['is_correct'], 'is_correct', endpoint),
                explanation: _Parse.optionalString(
                  row['explanation'],
                  'explanation',
                  endpoint,
                ),
              ))
          .toList(),
    );
  }
}
