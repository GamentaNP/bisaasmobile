/// End-to-end proof of the explanations loop: a real Dio walks the full
/// interceptor/envelope/DTO/domain chain against a scripted transport. The
/// results endpoint is the only surface allowed to publish an explanation, so
/// this test also pins the "absent stays absent" edge — no invented feedback.
library;

import 'package:bisaasmobile/features/quiz/data/datasources/quiz_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

/// Sentinel for "the server did not send this key at all".
const Object _absent = Object();

void main() {
  late FakeApi api;
  late QuizRemoteDataSource remote;

  Map<String, dynamic> resultsPayload({Object? explanation, Object? source}) =>
      <String, dynamic>{
        'attempt_id': 7,
        'mode': 'standard',
        'status': 'completed',
        'review_policy': <String, dynamic>{'answersVisible': true},
        'answers': <dynamic>[
          <String, dynamic>{
            'question_id': 11,
            'question_text': 'Which law explains this?',
            'given_answer': 'a',
            'is_correct': true,
            'is_skipped': false,
            if (explanation != _absent) 'explanation': explanation,
            if (source != _absent) 'explanation_source': source,
          },
        ],
      };

  setUp(() {
    api = FakeApi(<String, FakeRoute>{});
    remote = QuizRemoteDataSource(dioFor(api));
  });

  test('the parsed review row carries the explanation from the envelope',
      () async {
    api.on('GET', '/quiz/attempts/7/results',
        FakeRoute.ok(resultsPayload(explanation: 'Because gravity.')));

    final rows = await remote.getAttemptReviewEntries('7');

    expect(rows, hasLength(1));
    expect(rows.single.explanation, 'Because gravity.');
    expect(rows.single.explanationSource, isNull);
    expect(api.requests.single.path, '/quiz/attempts/7/results');
  });

  test('a null explanation under a locked policy stays null', () async {
    api.on('GET', '/quiz/attempts/7/results',
        FakeRoute.ok(resultsPayload(explanation: null, source: null)));

    final rows = await remote.getAttemptReviewEntries('7');

    expect(rows.single.explanation, isNull);
    expect(rows.single.explanationSource, isNull);
  });

  test('an omitted explanation stays null — no placeholder is invented',
      () async {
    api.on(
      'GET',
      '/quiz/attempts/7/results',
      FakeRoute.ok(resultsPayload(
        explanation: _absent,
        source: _absent,
      )),
    );

    final rows = await remote.getAttemptReviewEntries('7');

    expect(rows.single.explanation, isNull);
    expect(rows.single.explanationSource, isNull);
  });
}
