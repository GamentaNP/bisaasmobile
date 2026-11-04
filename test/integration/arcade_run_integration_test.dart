/// The arcade proven through the whole client stack.
///
/// These tests drive the real controller → repository → data source → Dio →
/// scripted transport. What they pin is the part that cannot be checked by
/// reading a response shape:
///
///  * a run's questions come from `GET /quiz/attempts/{id}`, because the start
///    route returns only an id;
///  * every write carries a stable `Idempotency-Key`, and a retried *start*
///    reuses its key so the server resumes instead of seeding a second attempt;
///  * Survival ends because the server says so — the client re-reads the
///    attempt and never grades;
///  * a timed-out question submits nothing. The API has no "timed out" answer,
///    and inventing one would send the grader a value it cannot score.
library;

import 'package:bisaasmobile/app/providers.dart';
import 'package:bisaasmobile/features/arcade/domain/entities/arcade_mode.dart';
import 'package:bisaasmobile/features/arcade/presentation/controllers/arcade_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

/// Two questions, as `GET /quiz/attempts/{id}` serialises them.
Map<String, dynamic> _attemptBody({
  required int attemptId,
  required String status,
  String mode = 'lightning',
}) =>
    <String, dynamic>{
      'attempt_id': attemptId,
      'mode': mode,
      'status': status,
      'question_count': 2,
      'questions': [
        {
          'question_id': 11,
          'answered': false,
          'skipped': false,
          'given_answer': null,
          'time_taken_seconds': null,
          'question': {
            'id': 11,
            'type': 'mcq',
            'question_text': 'What is 2 + 2?',
            'options': [
              {'key': 'a', 'text': '3'},
              {'key': 'b', 'text': '4'},
            ],
            'image_url': null,
            'metadata': <String, dynamic>{},
          },
        },
        {
          'question_id': 12,
          'answered': false,
          'skipped': false,
          'given_answer': null,
          'time_taken_seconds': null,
          'question': {
            'id': 12,
            'type': 'mcq',
            'question_text': 'What is 3 + 3?',
            'options': [
              {'key': 'c', 'text': '6'},
              {'key': 'd', 'text': '7'},
            ],
            'image_url': null,
            'metadata': <String, dynamic>{},
          },
        },
      ],
    };

Map<String, dynamic> _startBody({
  required int attemptId,
  required String mode,
}) =>
    <String, dynamic>{
      'attempt_id': attemptId,
      'mode': mode,
      'status': 'in_progress',
      'question_count': 2,
    };

Map<String, dynamic> _completionBody(int attemptId) => <String, dynamic>{
      'attempt_id': attemptId,
      'score': 80,
      'correct_count': 2,
      'wrong_count': 0,
      'skipped_count': 0,
      'completed_at': '2026-11-05T09:00:00+00:00',
    };

void main() {
  late FakeApi api;
  late ProviderContainer container;

  ProviderContainer boot(FakeApi fake) {
    final dio = Dio(BaseOptions(baseUrl: 'https://bisaas.test/api/v1'));
    dio.httpClientAdapter = fake;
    return ProviderContainer(
      overrides: [
        dioProvider.overrideWithValue(dio),
        // The pause between questions exists for the eye, not the test.
        arcadeAnswerPauseProvider.overrideWithValue(Duration.zero),
      ],
    );
  }

  ArcadeController controller() =>
      container.read(arcadeControllerProvider.notifier);
  ArcadeState state() => container.read(arcadeControllerProvider);

  setUp(() {
    api = FakeApi({});
  });

  tearDown(() => container.dispose());

  test('a lightning run: start, load, answer twice, complete', () async {
    api.on('POST', '/quiz/lightning/start',
        FakeRoute.ok(_startBody(attemptId: 77, mode: 'lightning')));
    api.on('GET', '/quiz/attempts/77',
        FakeRoute.ok(_attemptBody(attemptId: 77, status: 'in_progress')));
    api.on('POST', '/quiz/attempts/77/answers', FakeRoute.ok({}));
    api.on('PUT', '/quiz/attempts/77/completion',
        FakeRoute.ok(_completionBody(77)));

    container = boot(api);
    await controller().start(ArcadeMode.lightning);

    expect(state().phase, ArcadePhase.playing);
    expect(state().questions, hasLength(2));
    expect(state().current!.body, 'What is 2 + 2?');
    expect(state().current!.options.map((o) => o.id), ['a', 'b']);

    await controller().answer('b');
    expect(state().index, 1);
    expect(state().current!.id, 12);

    await controller().answer('c');

    expect(state().phase, ArcadePhase.finished);
    expect(state().result!.score, 80);
    expect(state().result!.correctCount, 2);

    // Two answers, each keyed to its own question, so a retry of one cannot
    // be mistaken for a retry of the other.
    final answerIndices =
        api.requests.indexed.where((e) => e.$2.path.endsWith('/answers'));
    expect(answerIndices, hasLength(2));
    expect(api.headerOf(answerIndices.first.$1, 'Idempotency-Key'),
        'arcade-answer-77-11');
    expect(api.headerOf(answerIndices.last.$1, 'Idempotency-Key'),
        'arcade-answer-77-12');
    expect(api.jsonBodyOf(answerIndices.first.$1)['question_id'], 11);
    expect(api.jsonBodyOf(answerIndices.first.$1)['answer'], 'b');

    // The completion is keyed to the attempt, not minted fresh.
    final completion = api.indexOfRequest('PUT', '/completion');
    expect(api.headerOf(completion, 'Idempotency-Key'), 'arcade-complete-77');
  });

  test('a retried start reuses its key instead of seeding a second attempt',
      () async {
    api.onSequence('POST', '/quiz/lightning/start', [
      FakeRoute.error(500, 'SERVER_ERROR', 'boom'),
      FakeRoute.ok(_startBody(attemptId: 78, mode: 'lightning')),
    ]);
    api.on('GET', '/quiz/attempts/78',
        FakeRoute.ok(_attemptBody(attemptId: 78, status: 'in_progress')));

    container = boot(api);
    await controller().start(ArcadeMode.lightning);

    expect(state().phase, ArcadePhase.failed);
    expect(state().error, isNotNull);

    await controller().retryLastStart();

    expect(state().phase, ArcadePhase.playing);
    final first = api.indexOfRequest('POST', '/quiz/lightning/start');
    final second = api.requests.indexed
        .where((e) => e.$2.path.endsWith('/quiz/lightning/start'))
        .last
        .$1;
    expect(
      api.headerOf(second, 'Idempotency-Key'),
      api.headerOf(first, 'Idempotency-Key'),
      reason: 'a retry with a new key is how a double attempt is created',
    );
  });

  test('survival ends when the server completes the attempt, not before',
      () async {
    api.on('POST', '/quiz/survival/start',
        FakeRoute.ok(_startBody(attemptId: 88, mode: 'survival')));
    api.onSequence('GET', '/quiz/attempts/88', [
      FakeRoute.ok(_attemptBody(
          attemptId: 88, status: 'in_progress', mode: 'survival')),
      FakeRoute.ok(
          _attemptBody(attemptId: 88, status: 'completed', mode: 'survival')),
    ]);
    api.on('POST', '/quiz/attempts/88/answers', FakeRoute.ok({}));
    api.on('GET', '/quiz/attempts/88/results', FakeRoute.ok(<String, dynamic>{
      'attempt_id': 88,
      'mode': 'survival',
      'status': 'completed',
      'score': 10,
      'correct_count': 1,
      'wrong_count': 1,
      'skipped_count': 0,
      'completed_at': '2026-11-05T09:00:00+00:00',
    }));

    container = boot(api);
    await controller().start(ArcadeMode.survival);
    await controller().answer('a');

    expect(state().phase, ArcadePhase.finished);
    expect(state().gameOver, isTrue,
        reason: 'the run ended because a wrong answer completed it');
    expect(state().result!.wrongCount, 1);

    // The server already completed it; a second completion would be a
    // conflicting write.
    expect(api.countOf('PUT', '/completion'), 0);
  });

  test('a timed-out question submits nothing and advances', () async {
    api.on('POST', '/quiz/lightning/start',
        FakeRoute.ok(_startBody(attemptId: 90, mode: 'lightning')));
    api.on('GET', '/quiz/attempts/90',
        FakeRoute.ok(_attemptBody(attemptId: 90, status: 'in_progress')));
    api.on('PUT', '/quiz/attempts/90/completion',
        FakeRoute.ok(<String, dynamic>{
      'attempt_id': 90,
      'score': 0,
      'correct_count': 0,
      'wrong_count': 0,
      'skipped_count': 2,
      'completed_at': '2026-11-05T09:00:00+00:00',
    }));

    container = boot(api);
    await controller().start(ArcadeMode.lightning);
    await controller().timeOut();

    expect(state().index, 1);
    expect(state().timedOut, 1);
    expect(api.countOf('POST', '/answers'), 0,
        reason: 'there is no "timed out" answer the grader could score');

    await controller().timeOut();
    expect(state().phase, ArcadePhase.finished);
    expect(state().result!.skippedCount, 2);
  });

  test('an attempt with no questions fails loudly instead of rendering empty',
      () async {
    api.on('POST', '/quiz/true-false/start',
        FakeRoute.ok(_startBody(attemptId: 91, mode: 'true_false')));
    api.on('GET', '/quiz/attempts/91', FakeRoute.ok(<String, dynamic>{
      'attempt_id': 91,
      'status': 'in_progress',
      // No `questions` key at all: drift, not an empty run.
    }));

    container = boot(api);
    await controller().start(ArcadeMode.trueFalse);

    expect(state().phase, ArcadePhase.failed);
    expect(state().error, isNotNull);
    expect(state().questions, isEmpty);
  });
}
