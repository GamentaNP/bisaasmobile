import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../app/providers.dart';
import '../../../../core/network/api_failure.dart';

/// Composition seam for the AI-hint endpoint. Presentation can watch this
/// provider without reaching into `quiz_remote_data_source.dart` (owned by a
/// separate work stream).
final quizHintRemoteDataSourceProvider = Provider<QuizHintRemoteDataSource>(
  (ref) => QuizHintRemoteDataSource(ref.watch(dioProvider)),
);

/// The server's hint payload, unchanged apart from unwrapping the envelope.
///
/// `QuizAiHintController` publishes exactly `{hint: string, question_id: int}`:
/// the hint is sanitised and answer-safe server-side, and the id is echoed so a
/// slow response cannot be shown against the wrong question. Nothing here
/// grades, generates or caches a hint.
class QuizHint {
  const QuizHint({required this.hint, required this.questionId});

  final String hint;
  final int questionId;
}

/// Client for `GET /api/v1/quiz/questions/{question}/hint` — verified at
/// `bisaas/routes/api/v1/quiz.php:465` (`->whereNumber('question')`, throttled).
///
/// The route is auth-scoped to the caller's own attempts, so a 403 is a real
/// answer from the server and propagates as an `ApiException`; a 2xx body with
/// a different shape is contract drift and throws `ContractViolation`. Neither
/// becomes an empty hint.
class QuizHintRemoteDataSource {
  const QuizHintRemoteDataSource(this._dio);

  final Dio _dio;

  Future<QuizHint> getHint(int questionId) async {
    final endpoint = '/quiz/questions/$questionId/hint';
    final res = await _dio.get<Map<String, dynamic>>(endpoint);
    final body = res.data;
    if (body == null) {
      throw ContractViolation('Empty response body', endpoint: endpoint);
    }
    final data = body['data'];
    if (data is! Map<String, dynamic>) {
      throw ContractViolation(
        'Expected `data` to be an object, got ${data.runtimeType}',
        endpoint: endpoint,
      );
    }
    final hint = data['hint'];
    final echoedId = data['question_id'];
    if (hint is! String || hint.isEmpty) {
      throw ContractViolation(
        'Expected `data.hint` to be a non-empty string',
        endpoint: endpoint,
      );
    }
    if (echoedId is! int || echoedId != questionId) {
      throw ContractViolation(
        '`data.question_id` must echo the requested question',
        endpoint: endpoint,
      );
    }
    return QuizHint(hint: hint, questionId: echoedId);
  }
}
