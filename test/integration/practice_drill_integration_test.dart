/// Cross-layer integration tests for the practice drill.
///
/// The drill is the one flow in this app where the client used to be
/// quietly wrong: it started a server attempt, ignored it, and drilled
/// whatever bookmarks happened to be in memory. These tests drive the real
/// chain — Dio → data source → DTO → domain → repository → controller — and
/// assert that the server's attempt, the server's questions and the server's
/// score are the ones the UI ends up showing.
library;

import 'package:bisaasmobile/features/practice/data/datasources/practice_remote_data_source.dart';
import 'package:bisaasmobile/features/practice/data/repositories/practice_repository_impl.dart';
import 'package:bisaasmobile/features/practice/domain/repositories/practice_repository.dart';

import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

void main() {
  late FakeApi api;
  late PracticeRepository repository;

  setUp(() {
    api = FakeApi(<String, FakeRoute>{});
    repository = PracticeRepositoryImpl(PracticeRemoteDataSource(dioFor(api)));
  });

  Map<String, dynamic> question(int id, {String text = 'Question'}) =>
      <String, dynamic>{
        'id': id,
        'question_text': '$text $id',
        'type': 'mcq',
        'difficulty': 'medium',
        'points': 4,
        'options': <Map<String, dynamic>>[
          <String, dynamic>{'key': 'A', 'text': 'First'},
          <String, dynamic>{'key': 'B', 'text': 'Second'},
        ],
      };

  group('the drill is a real server attempt', () {
    test('the questions shown are the ones the attempt is seeded with', () async {
      api.on(
        'GET',
        '/quiz/questions',
        FakeRoute.ok(<String, dynamic>{
          'items': <Map<String, dynamic>>[
            question(11),
            question(12),
            question(13),
          ],
        }),
      );
      api.on(
        'POST',
        '/quiz/attempts',
        FakeRoute.ok(<String, dynamic>{
          'attempt_id': 900,
          'mode': 'practice',
          'status': 'in_progress',
          'question_count': 3,
        }),
      );

      final drill = await repository.startDrill(title: 'Test', count: 3);

      expect(drill.attemptId, '900');
      expect(drill.questions.map((q) => q.id), <int>[11, 12, 13]);

      // The seed is the exact set of ids the user will be shown.
      final start = api.requests.last;
      final body = api.jsonBodyOf(api.requests.length - 1);

      expect(start.method, 'POST');
      expect(body['mode'], 'practice');
      expect(body['question_ids'], <int>[11, 12, 13]);
      expect(body.containsKey('topic_id'), isFalse,
          reason: 'question_ids prohibits topic_id/course_id/category_id');
    });

    test('the score comes from the server, never from the client', () async {
      api.on(
        'GET',
        '/quiz/questions',
        FakeRoute.ok(<String, dynamic>{
          'items': <Map<String, dynamic>>[question(11)],
        }),
      );
      api.on(
        'POST',
        '/quiz/attempts',
        FakeRoute.ok(<String, dynamic>{
          'attempt_id': 901,
          'mode': 'practice',
          'status': 'in_progress',
          'question_count': 1,
        }),
      );
      api.on(
        'POST',
        '/quiz/attempts/901/answers',
        FakeRoute.ok(<String, dynamic>{'saved': true}),
      );
      api.on(
        'PUT',
        '/quiz/attempts/901/completion',
        FakeRoute.ok(<String, dynamic>{
          'attempt_id': 901,
          'score': 8,
          'correct_count': 2,
          'wrong_count': 1,
          'skipped_count': 0,
        }),
      );

      final drill = await repository.startDrill(title: 'Test', count: 1);
      await repository.submitAnswer(
        attemptId: drill.attemptId,
        questionId: drill.questions.first.id,
        answer: 'A',
        timeTakenSeconds: 12,
      );
      final result = await repository.completeAttempt(attemptId: drill.attemptId);

      expect(result.score, 8);
      expect(result.correctCount, 2);
      expect(result.wrongCount, 1);
      expect(result.total, 3);

      // The answer carried the timing evidence the integrity engine consumes.
      final answerIndex = api.requests.indexWhere(
        (r) => r.method == 'POST' && r.path.endsWith('/answers'),
      );
      final answer = api.jsonBodyOf(answerIndex);
      expect(answer['question_id'], 11);
      expect(answer['answer'], 'A');
      expect(answer['time_taken_seconds'], 12);
    });
  });

  group('question loading honours the server filters', () {
    test('only the filters the server honours are sent', () async {
      api.on(
        'GET',
        '/quiz/questions',
        FakeRoute.ok(<String, dynamic>{
          'items': <Map<String, dynamic>>[question(21)],
        }),
      );

      await repository.getQuestions(search: 'Soil Mechanics', limit: 5);

      final query = api.queryOf(0);
      expect(query['search'], 'Soil Mechanics');
      expect(query['per_page'], 50);
      expect(query.containsKey('topic_id'), isFalse,
          reason: 'the questions endpoint has no topic_id filter');
      expect(query.containsKey('page'), isFalse,
          reason: 'the endpoint is cursor-paginated; page is ignored');
    });

    test('the cursor walk stops when the server says there is no more', () async {
      api.on(
        'GET',
        '/quiz/questions',
        FakeRoute.envelope(<String, dynamic>{
          'success': true,
          'data': <String, dynamic>{
            'items': <Map<String, dynamic>>[question(31)],
          },
          'pagination': <String, dynamic>{
            'type': 'cursor',
            'per_page': 50,
            'count': 1,
            'has_more': false,
            'next_cursor': null,
          },
        }),
      );

      final questions = await repository.getQuestions(limit: 10);
      expect(questions, hasLength(1));
      expect(api.requests, hasLength(1));
    });
  });

  group('bookmarks', () {
    test('removing a bookmark uses DELETE, not the POST alias', () async {
      // The POST alias converges to `bookmarked: true`; it cannot remove.
      api.on(
        'DELETE',
        '/quiz/bookmarks/42',
        FakeRoute.ok(<String, dynamic>{'bookmarked': false}),
      );

      final removed = await repository.removeBookmark(42);

      expect(removed, isTrue);
      expect(api.requests.single.method, 'DELETE');
    });

    test('adding a bookmark uses PUT with an idempotency key', () async {
      api.on(
        'PUT',
        '/quiz/bookmarks/42',
        FakeRoute.ok(<String, dynamic>{'bookmarked': true}),
      );

      final added = await repository.addBookmark(42, idempotencyKey: 'k1');

      expect(added, isTrue);
      expect(api.requests.single.method, 'PUT');
      expect(api.requests.single.headers['Idempotency-Key'], 'k1');
    });
  });

  group('attempt history is cursor-paginated', () {
    test('the client sends a cursor, never a page number', () async {
      api.on(
        'GET',
        '/quiz/attempts/history',
        FakeRoute.envelope(<String, dynamic>{
          'success': true,
          'data': <String, dynamic>{
            'items': <Map<String, dynamic>>[
              <String, dynamic>{
                'id': 7,
                'mode': 'practice',
                'status': 'completed',
                'score': 12,
                'correct_count': 3,
                'wrong_count': 1,
                'skipped_count': 0,
                'question_count': 4,
              },
            ],
          },
          'pagination': <String, dynamic>{
            'type': 'cursor',
            'per_page': 20,
            'count': 1,
            'has_more': true,
            'next_cursor': 'abc',
          },
        }),
      );

      final page = await repository.getAttemptHistory(cursor: 'abc');

      expect(page.items, hasLength(1));
      expect(page.items.first.score, 12);
      expect(page.hasMore, isTrue);
      expect(page.nextCursor, 'abc');

      final query = api.queryOf(0);
      expect(query['cursor'], 'abc');
      expect(query.containsKey('page'), isFalse);
    });
  });
}
