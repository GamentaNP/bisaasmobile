/// Practice-drill correctness fixes proven through the real client stack.
///
/// Pins the missing failure propagation (a dropped answer must not be shown as
/// "sent"), stable completion keys, server-side topic filtering and the resume
/// read that was previously arcade-only.
library;

import 'package:bisaasmobile/app/providers.dart';
import 'package:bisaasmobile/features/practice/presentation/controllers/practice_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

Map<String, dynamic> _question(int id) => <String, dynamic>{
      'id': id,
      'question_text': 'Question $id',
      'options': [
        {'key': 'A', 'text': 'First'},
        {'key': 'B', 'text': 'Second'},
      ],
    };

Map<String, dynamic> _attempt(int id) => <String, dynamic>{
      'attempt_id': id,
      'mode': 'practice',
      'status': 'in_progress',
      'question_count': 2,
      'questions': [
        {
          'question_id': 11,
          'answered': true,
          'skipped': false,
          'given_answer': 'A',
          'time_taken_seconds': 5,
          'question': _question(11),
        },
        {
          'question_id': 12,
          'answered': false,
          'skipped': false,
          'given_answer': null,
          'time_taken_seconds': null,
          'question': _question(12),
        },
      ],
    };

void main() {
  late FakeApi api;
  late ProviderContainer container;

  ProviderContainer boot() {
    final dio = dioFor(api);
    return ProviderContainer(overrides: [dioProvider.overrideWithValue(dio)]);
  }

  PracticeController controller() =>
      container.read(practiceControllerProvider.notifier);

  void scriptHistory() {
    api.on('GET', '/quiz/attempts/history', FakeRoute.ok(<String, dynamic>{
      'items': <dynamic>[],
    }));
  }

  setUp(() => api = FakeApi(<String, FakeRoute>{}));
  tearDown(() => container.dispose());

  test('topic drills send topic_id, not a text search, and seed those ids',
      () async {
    api.on('GET', '/quiz/questions', FakeRoute.ok(<String, dynamic>{
      'items': [_question(11)],
    }));
    api.on('POST', '/quiz/attempts', FakeRoute.ok(<String, dynamic>{
      'attempt_id': 900,
      'mode': 'practice',
      'status': 'in_progress',
      'question_count': 1,
    }));

    container = boot();
    final drill = await controller().startDrill(
      title: 'Soil Mechanics',
      topicId: 42,
      count: 1,
    );

    expect(drill, isNotNull);
    expect(api.queryOf(0)['topic_id'], 42);
    expect(api.queryOf(0).containsKey('page'), isFalse);
    expect(api.jsonBodyOf(1)['question_ids'], [11]);
  });

  test('a failed answer throw is surfaced and the retry reuses the key',
      () async {
    api.onSequence('POST', '/quiz/attempts/900/answers', [
      FakeRoute.error(500, 'INTERNAL_ERROR', 'boom'),
      FakeRoute.ok(<String, dynamic>{'saved': true}),
    ]);

    container = boot();
    await expectLater(
      controller().submitAnswer(
        attemptId: '900',
        questionId: 11,
        answer: 'A',
      ),
      throwsA(isA<Exception>()),
    );
    expect(container.read(practiceControllerProvider).error, isNotNull);

    await controller().submitAnswer(
      attemptId: '900',
      questionId: 11,
      answer: 'A',
    );
    final writes = api.requests
        .indexed
        .where((e) => e.$2.path.endsWith('/answers'))
        .toList();
    expect(writes, hasLength(2));
    expect(api.headerOf(writes[0].$1, 'Idempotency-Key'),
        api.headerOf(writes[1].$1, 'Idempotency-Key'));
  });

  test('a 409 on an already-stored answer is not surfaced as a failure',
      () async {
    api.on('POST', '/quiz/attempts/900/answers',
        FakeRoute.error(409, 'IDEMPOTENCY_CONFLICT', 'replayed'));

    container = boot();
    await controller().submitAnswer(
      attemptId: '900',
      questionId: 11,
      answer: 'A',
    );
    expect(container.read(practiceControllerProvider).error, isNull,
        reason: 'a replayed write is a success, not "answer not sent"');
  });

  test('a completion retry keeps the attempt and replays the same key',
      () async {
    scriptHistory();
    api.onSequence('PUT', '/quiz/attempts/900/completion', [
      FakeRoute.error(500, 'INTERNAL_ERROR', 'boom'),
      FakeRoute.ok(<String, dynamic>{
        'attempt_id': 900,
        'score': 8,
        'correct_count': 2,
        'wrong_count': 0,
        'skipped_count': 0,
      }),
    ]);

    container = boot();
    expect(await controller().completeAttempt('900'), isNull);
    expect(container.read(practiceControllerProvider).startError, isNotNull);

    final result = await controller().completeAttempt('900');
    expect(result, isNotNull);
    expect(result!.score, 8);

    final completions = api.requests
        .where((r) => r.method == 'PUT' && r.path.endsWith('/completion'))
        .toList();
    expect(completions, hasLength(2));
    expect(completions.first.headers['Idempotency-Key'],
        completions.last.headers['Idempotency-Key']);
  });

  test('resume reads the attempt the server already seeded', () async {
    api.on('GET', '/quiz/attempts/900', FakeRoute.ok(_attempt(900)));

    container = boot();
    final drill = await controller().resumeDrill('900');

    expect(drill, isNotNull);
    expect(drill!.attemptId, '900');
    expect(drill.questions.map((q) => q.id), [11, 12]);
    expect(drill.questions.first.options.first.key, 'A');
    expect(api.countOf('GET', '/quiz/attempts/900'), 1);
  });
}
