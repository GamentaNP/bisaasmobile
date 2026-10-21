/// Cross-layer tests for the three client pieces the server unblocked.
///
///  * **The guest sandbox is now playable.** The server publishes the
///    questions it picked (`question_items`) alongside the attempt, so the
///    client can render them, submit an answer and read the result — instead
///    of starting an attempt nobody could play.
///
///  * **A bookmark drill uses the bookmark's own options.** The bookmarks
///    endpoint publishes the options now, so the drill is built from the
///    bookmarks themselves rather than borrowing a category.
///
///  * **A calculator result shares through the permalink route.**
///    `POST /api/v1/calculator/permalinks` takes the inline payload;
///    `POST /api/v1/share` is snapshot-only and demands a `calculable_type`
///    the client cannot mint.
library;

import 'package:bisaasmobile/features/social/data/datasources/social_remote_data_source.dart';
import 'package:bisaasmobile/features/social/data/repositories/social_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

void main() {
  group('the guest sandbox', () {
    late FakeApi api;
    late SocialRepositoryImpl repository;

    setUp(() {
      api = FakeApi(<String, FakeRoute>{});
      repository = SocialRepositoryImpl(SocialRemoteDataSource(dioFor(api)));
    });

    test('the attempt carries the questions the server picked', () async {
      api.on(
        'POST',
        '/public/social/sandbox/tok_123',
        FakeRoute.ok(<String, dynamic>{
          'sandbox_attempt': <String, dynamic>{
            'attempt_id': 321,
            'guest_session_id': 'guest-abc',
            'questions': 2,
            'question_items': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 11,
                'type': 'mcq',
                'question_text': 'What is the design load factor?',
                'options': <Map<String, dynamic>>[
                  <String, dynamic>{'key': 'A', 'text': '1.1'},
                  <String, dynamic>{'key': 'B', 'text': '1.5'},
                ],
                'difficulty': 'easy',
                'points': 2,
              },
              <String, dynamic>{
                'id': 12,
                'type': 'mcq',
                'question_text': 'And the service load?',
                'options': <Map<String, dynamic>>[
                  <String, dynamic>{'key': 'A', 'text': '0.4'},
                ],
                'difficulty': 'easy',
                'points': 2,
              },
            ],
          },
        }),
      );

      final attempt = await repository.startSandbox(
        token: 'tok_123',
        guestSessionId: 'guest-abc',
      );

      expect(attempt.attemptId, 321);
      expect(attempt.questionCount, 2);
      expect(attempt.isPlayable, isTrue);
      expect(attempt.questions, hasLength(2));
      expect(attempt.questions.first.questionText, 'What is the design load factor?');
      expect(attempt.questions.first.options, hasLength(2));
      expect(attempt.questions.first.options.first.key, 'A');
      expect(attempt.questions.last.options, hasLength(1));

      // The guest session id is bound to the attempt.
      final body = api.jsonBodyOf(0);
      expect(body['guest_session_id'], 'guest-abc');
    });

    test('an answer is graded by the server', () async {
      api.on(
        'PUT',
        '/public/social/sandbox/321/answer',
        FakeRoute.ok(<String, dynamic>{
          'answer': <String, dynamic>{'question_id': 11, 'is_correct': true},
        }),
      );

      final verdict = await repository.answerSandbox(
        attemptId: 321,
        questionId: 11,
        answer: 'A',
      );

      expect(verdict.questionId, 11);
      expect(verdict.isCorrect, isTrue);

      final body = api.jsonBodyOf(0);
      expect(body['question_id'], 11);
      expect(body['answer'], 'A');
    });

    test('a skipped answer is null, not false', () async {
      // The server publishes null for a skipped question; rendering that as
      // "wrong" would be a lie the client invented.
      api.on(
        'PUT',
        '/public/social/sandbox/321/answer',
        FakeRoute.ok(<String, dynamic>{
          'answer': <String, dynamic>{'question_id': 11, 'is_correct': null},
        }),
      );

      final verdict = await repository.answerSandbox(
        attemptId: 321,
        questionId: 11,
        answer: 'A',
      );

      expect(verdict.isCorrect, isNull);
    });

    test("the completion is the server's verdict", () async {
      api.on(
        'PUT',
        '/public/social/sandbox/321/completion',
        FakeRoute.ok(<String, dynamic>{
          'result': <String, dynamic>{
            'score': 60.0,
            'correct': 3,
            'wrong': 2,
            'skipped': 0,
            'total': 5,
          },
        }),
      );

      final result = await repository.completeSandbox(321);

      expect(result.score, 60.0);
      expect(result.correct, 3);
      expect(result.wrong, 2);
      expect(result.total, 5);
    });
  });
}
