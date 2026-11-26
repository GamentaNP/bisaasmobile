/// Cross-layer test for `GET /quiz/questions/{id}/hint`, one of the live
/// routes the audit found with no client caller (§2.3). The datasource is
/// exercised through a real Dio + envelope, so a wrong path, a shape drift or
/// a swallowed error fails here rather than in a stub.
library;

import 'package:bisaasmobile/core/network/api_failure.dart';
import 'package:bisaasmobile/features/quiz/data/datasources/quiz_hint_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

void main() {
  test('reads the hint and echoes the question id', () async {
    final api = FakeApi(<String, FakeRoute>{});
    api.on(
      'GET',
      '/quiz/questions/17/hint',
      FakeRoute.ok(<String, dynamic>{
        'hint': 'Think about the units before substituting values.',
        'question_id': 17,
      }),
    );
    final source = QuizHintRemoteDataSource(dioFor(api));

    final hint = await source.getHint(17);

    expect(api.requests.single.path, '/quiz/questions/17/hint');
    expect(hint.questionId, 17);
    expect(hint.hint, contains('units'));
  });

  test('a server error propagates instead of becoming an empty hint', () async {
    final api = FakeApi(<String, FakeRoute>{});
    api.on(
      'GET',
      '/quiz/questions/17/hint',
      FakeRoute.error(403, 'FORBIDDEN', 'Not your attempt'),
    );
    final source = QuizHintRemoteDataSource(dioFor(api));

    await expectLater(
      source.getHint(17),
      throwsA(isA<Exception>()),
    );
  });

  test('a 2xx body of the wrong shape is contract drift', () async {
    final api = FakeApi(<String, FakeRoute>{});
    api.on(
      'GET',
      '/quiz/questions/17/hint',
      // Old server leaked the whole AgentResponse here; the current contract
      // publishes a plain string.
      FakeRoute.ok(<String, dynamic>{
        'hint': {'text': 'answer is b', 'usage': {'tokens': 12}},
        'question_id': 17,
      }),
    );
    final source = QuizHintRemoteDataSource(dioFor(api));

    await expectLater(
      source.getHint(17),
      throwsA(isA<ContractViolation>()),
    );
  });

  test('a mismatched question id is rejected rather than shown on a wrong card', () async {
    final api = FakeApi(<String, FakeRoute>{});
    api.on(
      'GET',
      '/quiz/questions/17/hint',
      FakeRoute.ok(<String, dynamic>{
        'hint': 'Look at the denominator.',
        'question_id': 18,
      }),
    );
    final source = QuizHintRemoteDataSource(dioFor(api));

    await expectLater(
      source.getHint(17),
      throwsA(isA<ContractViolation>()),
    );
  });
}
