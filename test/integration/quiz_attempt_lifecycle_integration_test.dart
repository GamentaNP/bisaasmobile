/// C1–C4, C6, C7 and A1 proven through the whole client stack.
///
/// The surfaced bugs this file pins are all invisible when one layer is
/// mocked: a retry that mints a fresh Idempotency-Key, a completion retry that
/// starts a new quiz, an exit that never abandons, an option `id` sent where
/// the grader expects the `key`, and a lifeline whose time effect is narrated
/// but never applied to the deadline.
library;

import 'package:bisaasmobile/app/providers.dart';
import 'package:bisaasmobile/core/storage/database/app_database.dart';
import 'package:bisaasmobile/features/quiz/presentation/controllers/quiz_controller.dart';
import 'package:bisaasmobile/features/quiz/presentation/state/quiz_state.dart';
import 'package:drift/native.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

Map<String, dynamic> _question(int id, {required String key}) => <String, dynamic>{
      'id': id,
      'question_text': 'Question $id',
      // A numeric id alongside the key is the exact trap: the grader matches
      // the key, so the client must submit 'B', never '20'.
      'options': [
        {'key': key, 'id': id * 10, 'text': 'Choice $key'},
        {'key': 'C', 'id': id * 10 + 1, 'text': 'Other'},
      ],
      'difficulty': 'medium',
      'points': 4,
    };

Map<String, dynamic> _start(int id) => <String, dynamic>{
      'attempt_id': id,
      'mode': 'standard',
      'status': 'in_progress',
      'question_count': 2,
    };

Map<String, dynamic> _attempt(int id, {bool answered = false}) => <String, dynamic>{
      'attempt_id': id,
      'mode': 'standard',
      'status': 'in_progress',
      'question_count': 2,
      'questions': [
        {
          'question_id': 11,
          'answered': answered,
          'skipped': false,
          'given_answer': answered ? 'B' : null,
          'time_taken_seconds': answered ? 7 : null,
          'question': _question(11, key: 'B'),
        },
        {
          'question_id': 12,
          'answered': false,
          'skipped': false,
          'given_answer': null,
          'time_taken_seconds': null,
          'question': _question(12, key: 'A'),
        },
      ],
    };

void main() {
  late FakeApi api;
  late AppDatabase db;
  late ProviderContainer container;

  ProviderContainer boot() {
    final dio = dioFor(api);
    return ProviderContainer(
      overrides: [
        dioProvider.overrideWithValue(dio),
        appDatabaseProvider.overrideWithValue(db),
      ],
    );
  }

  QuizController controller() => container.read(quizControllerProvider.notifier);
  QuizState state() => container.read(quizControllerProvider);

  void scriptStart(int attemptId) {
    api.on('GET', '/quiz/courses',
        FakeRoute.ok(<String, dynamic>{'data': <dynamic>[
          {'id': 5, 'name': 'Course'}
        ]}));
    api.on('GET', '/quiz/courses/5/questions', FakeRoute.ok(<String, dynamic>{
      'items': [_question(11, key: 'B'), _question(12, key: 'A')],
    }));
    api.on('POST', '/quiz/attempts', FakeRoute.ok(_start(attemptId)));
    api.on('GET', '/quiz/attempts/$attemptId/lifelines',
        FakeRoute.ok(<String, dynamic>{'enabled': false, 'lifelines': <dynamic>[]}));
  }

  setUp(() {
    api = FakeApi(<String, FakeRoute>{});
    db = AppDatabase(NativeDatabase.memory());
  });

  tearDown(() async {
    container.dispose();
    await db.close();
  });

  test('a failed start is retried with the SAME key and submits option keys',
      () async {
    scriptStart(700);
    api.onSequence('POST', '/quiz/attempts', [
      FakeRoute.error(500, 'INTERNAL_ERROR', 'boom'),
      FakeRoute.ok(_start(700)),
    ]);

    container = boot();
    await controller().startSession('5');
    expect(state().phase, QuizPhase.error);

    await controller().startSession('5');
    expect(state().phase, QuizPhase.answering);
    expect(state().attemptId, '700');

    final starts = api.requests
        .indexed
        .where((e) => e.$2.path.endsWith('/quiz/attempts') && e.$2.method == 'POST')
        .toList();
    expect(starts, hasLength(2));
    expect(api.headerOf(starts[0].$1, 'Idempotency-Key'),
        api.headerOf(starts[1].$1, 'Idempotency-Key'),
        reason: 'a fresh key on retry seeds a second attempt');
    // The grader matches option keys, even when the payload carries an id.
    expect(state().currentQuestion!.options.first.id, 'B');
  });

  test('an answer retry reuses its key and a 409 replays the original result',
      () async {
    scriptStart(701);
    api.onSequence('POST', '/quiz/attempts/701/answers', [
      FakeRoute.ok(<String, dynamic>{'saved': true}),
      FakeRoute.error(409, 'IDEMPOTENCY_CONFLICT', 'replayed'),
    ]);
    // The server has not yet recorded the answer: a resume lands back on the
    // same question, whose write was stored but whose response was lost.
    api.on('GET', '/quiz/attempts/701', FakeRoute.ok(_attempt(701)));

    container = boot();
    await controller().startSession('5');
    await controller().selectAnswer('B');
    expect(state().phase, QuizPhase.feedback);
    expect(state().errorMessage, isNull);

    await controller().resumeSession('701');
    expect(state().phase, QuizPhase.answering);
    expect(state().currentIndex, 0);

    await controller().selectAnswer('B');
    expect(state().phase, QuizPhase.feedback);
    expect(state().errorMessage, isNull,
        reason: 'an idempotent replay is not a failed answer');

    final writes = api.requests
        .indexed
        .where((e) => e.$2.path.endsWith('/answers'))
        .toList();
    expect(writes, hasLength(2));
    expect(api.headerOf(writes[0].$1, 'Idempotency-Key'),
        api.headerOf(writes[1].$1, 'Idempotency-Key'));
    expect(api.jsonBodyOf(writes[0].$1)['answer'], 'B');
  });

  test('a failed answer stays unsent and the retry reuses its key', () async {
    scriptStart(702);
    api.onSequence('POST', '/quiz/attempts/702/answers', [
      FakeRoute.error(500, 'INTERNAL_ERROR', 'boom'),
      FakeRoute.ok(<String, dynamic>{'saved': true}),
    ]);

    container = boot();
    await controller().startSession('5');
    await controller().selectAnswer('B');
    expect(state().phase, QuizPhase.answering);
    expect(state().errorMessage, isNotNull);

    await controller().selectAnswer('B');
    expect(state().phase, QuizPhase.feedback);
    final writes = api.requests
        .indexed
        .where((e) => e.$2.path.endsWith('/answers'))
        .toList();
    expect(writes, hasLength(2));
    expect(api.headerOf(writes[0].$1, 'Idempotency-Key'),
        api.headerOf(writes[1].$1, 'Idempotency-Key'));
  });

  test('a completion failure retries the SAME attempt, never a new quiz',
      () async {
    scriptStart(703);
    api.onSequence('PUT', '/quiz/attempts/703/completion', [
      FakeRoute.error(500, 'INTERNAL_ERROR', 'boom'),
      FakeRoute.ok(<String, dynamic>{
        'attempt_id': 703,
        'correct_count': 2,
        'wrong_count': 0,
        'skipped_count': 0,
      }),
    ]);

    container = boot();
    await controller().startSession('5');
    await controller().finishSession();

    expect(state().phase, QuizPhase.error);
    expect(controller().hasFailedCompletion, isTrue);
    expect(api.countOf('POST', '/quiz/attempts'), 1);

    await controller().retryCompletion();
    expect(state().phase, QuizPhase.finished);
    expect(controller().hasFailedCompletion, isFalse);
    expect(api.countOf('POST', '/quiz/attempts'), 1,
        reason: 'retrying completion must not seed a brand-new attempt');

    final completions = api.requests
        .where((r) => r.method == 'PUT' && r.path.endsWith('/completion'))
        .toList();
    expect(completions, hasLength(2));
    expect(completions.first.headers['Idempotency-Key'],
        completions.last.headers['Idempotency-Key']);
  });

  test('exiting a standard attempt abandons it with a keyed PUT', () async {
    scriptStart(704);
    api.on('PUT', '/quiz/attempts/704/abandonment',
        FakeRoute.ok(<String, dynamic>{'abandoned': true}));

    container = boot();
    await controller().startSession('5');
    await controller().abandonSession();

    final abandon = api.indexOfRequest('PUT', '/abandonment');
    expect(abandon, isNot(-1));
    expect(api.headerOf(abandon, 'Idempotency-Key'), 'quiz-abandon-704');
  });

  test('a lifeline time effect extends the attempt deadline', () async {
    scriptStart(705);
    api.on('GET', '/quiz/attempts/705/lifelines',
        FakeRoute.ok(<String, dynamic>{
      'enabled': true,
      'wallet_balance': 100,
      'lifelines': [
        {
          'slug': 'extra_time',
          'name': 'Extra time',
          'effectType': 'extra_time',
          'canUse': true,
          'canPurchase': false,
        }
      ],
    }));
    // The catalogue says a token is banked (canUse), so the controller takes
    // the /use path; script both routes so the assertion is about the effect,
    // not about which branch the server catalogue chose.
    for (final path in [
      '/quiz/attempts/705/lifelines/extra_time/use',
      '/quiz/attempts/705/lifelines/extra_time/purchase-and-use',
    ]) {
      api.on('POST', path, FakeRoute.ok(<String, dynamic>{
        'slug': 'extra_time',
        'remaining_uses': 0,
        'effect': {'effect_type': 'extra_time', 'extra_seconds': 60},
      }));
    }

    container = boot();
    await controller().startSession('5');
    await controller().loadLifelines();
    final before = state().remainingSeconds;
    final effect = await controller().useLifeline('extra_time');

    expect(effect, isNotNull);
    expect(state().session!.durationSeconds, 180 + 60);
    expect(state().remainingSeconds, before + 60,
        reason: 'the server time bonus must change the timer, not just the toast');
  });

  test('a hint comes from the server, retries on failure and never grades',
      () async {
    scriptStart(707);
    api.onSequence('GET', '/quiz/questions/11/hint', [
      FakeRoute.error(500, 'INTERNAL_ERROR', 'boom'),
      FakeRoute.ok(<String, dynamic>{
        'hint': 'Check the unit conversion first.',
        'question_id': 11,
      }),
    ]);

    container = boot();
    await controller().startSession('5');
    await controller().loadHint();
    expect(container.read(quizHintViewProvider).error, isNotNull);
    expect(container.read(quizHintViewProvider).hint, isNull);

    await controller().loadHint();
    final view = container.read(quizHintViewProvider);
    expect(view.hint, 'Check the unit conversion first.');
    expect(view.error, isNull);
    expect(view.busy, isFalse);
    expect(view.questionId, 11);
    expect(api.countOf('GET', '/hint'), 2);

    // The hint is prose from the server. Nothing here became a verdict.
    expect(state().lastResult, isNull);
    expect(state().answers, isEmpty);
    expect(api.countOf('POST', '/answers'), 0);
  });

  test('resume reads the server attempt and keeps server-only answers pending',
      () async {
    api.on('GET', '/quiz/attempts/706', FakeRoute.ok(_attempt(706, answered: true)));
    api.on('GET', '/quiz/attempts/706/lifelines',
        FakeRoute.ok(<String, dynamic>{'enabled': false, 'lifelines': <dynamic>[]}));

    container = boot();
    await controller().startSession('5', attemptId: '706');

    expect(state().phase, QuizPhase.answering);
    expect(state().attemptId, '706');
    expect(state().currentIndex, 1, reason: 'resume lands on the first unanswered question');
    expect(state().answers['11']!.correctOptionId, isEmpty,
        reason: 'the resume endpoint never publishes a verdict');
    expect(api.countOf('GET', '/quiz/attempts/706'), 1);
  });
}
