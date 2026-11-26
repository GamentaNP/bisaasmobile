/// Cross-layer proof for the unified quiz SRS queue.
///
/// The quiz queue is cursor-only and its grade transition is keyed. Both
/// facts are invisible when a single layer is mocked: a client that sends
/// `page=2` walks page one forever, and a retry that mints a fresh
/// Idempotency-Key applies SM-2 twice. This file drives real Dio → adapter →
/// envelope → DTO → domain → repository → controller.
library;

import 'package:bisaasmobile/app/providers.dart';
import 'package:bisaasmobile/core/network/api_failure.dart';
import 'package:bisaasmobile/features/quiz/data/datasources/quiz_srs_remote_data_source.dart';
import 'package:bisaasmobile/features/quiz/domain/entities/quiz_srs.dart';
import 'package:bisaasmobile/features/quiz/presentation/controllers/quiz_srs_controller.dart';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fake_api.dart';

Map<String, dynamic> _questionCard(int id) => <String, dynamic>{
      'type': 'question',
      'id': id,
      'question_id': id,
      'content': 'Question $id',
      'options': [
        {'key': 'A', 'text': 'Choice A'},
        {'key': 'B', 'text': 'Choice B'},
      ],
      'item_type': 'mcq',
      'difficulty': 'medium',
      'due_reason': 'overdue',
      'due_at': '2026-11-20T00:00:00+00:00',
      'overdue_days': 6,
      'interval_days': 4,
      'repetitions': 3,
      'easiness_factor': 2.5,
    };

Map<String, dynamic> _wordCard(int id) => <String, dynamic>{
      'type': 'word',
      'id': id,
      'word_id': id,
      'content': 'Term $id',
      'definition': 'Meaning $id',
      'example': 'Used in a sentence $id',
      'difficulty': 'medium',
      'due_reason': 'due',
      'due_at': '2026-11-26T00:00:00+00:00',
      'overdue_days': 0,
      'interval_days': 1,
      'repetitions': 1,
      'easiness_factor': 2.5,
    };

FakeRoute _page(
  List<Map<String, dynamic>> items, {
  required bool hasMore,
  String? nextCursor,
}) =>
    FakeRoute.envelope(<String, dynamic>{
      'success': true,
      'data': <String, dynamic>{'items': items},
      'pagination': <String, dynamic>{
        'type': 'cursor',
        'per_page': 50,
        'count': items.length,
        'has_more': hasMore,
        'next_cursor': nextCursor,
        'prev_cursor': null,
      },
      'message': 'Due reviews retrieved successfully',
    });

Map<String, dynamic> _gradeData(int id, {required String type}) =>
    <String, dynamic>{
      'id': id,
      'type': type,
      'quality': 4,
      'interval_days': 9,
      'repetitions': 4,
      'easiness_factor': 2.6,
      'due_at': '2026-12-05T00:00:00+00:00',
    };

void main() {
  late FakeApi api;
  late ProviderContainer container;

  ProviderContainer boot() => ProviderContainer(
        overrides: [dioProvider.overrideWithValue(dioFor(api))],
      );

  setUp(() => api = FakeApi(<String, FakeRoute>{}));

  tearDown(() => container.dispose());

  test('the due queue walks next_cursor and never sends page', () async {
    api.onSequence('GET', '/quiz/reviews/due', [
      _page([_questionCard(11)], hasMore: true, nextCursor: 'opaque-2'),
      _page([_wordCard(12)], hasMore: false),
    ]);
    container = boot();

    final cards = await container.read(quizSrsDueProvider.future);

    expect(cards, hasLength(2));
    expect(cards.first.id, '11');
    expect(cards.first.isQuestion, isTrue);
    expect(cards.first.content, 'Question 11');
    expect(cards.first.options.map((o) => o.label), ['A', 'B']);
    expect(cards.first.overdueDays, 6);
    expect(cards.first.easinessFactor, 2.5);
    expect(cards.last.isWord, isTrue);
    expect(cards.last.definition, 'Meaning 12');

    final gets = api.requests
        .where((r) => r.path == '/quiz/reviews/due')
        .toList();
    expect(gets, hasLength(2));
    final first = api.requests.indexOf(gets.first);
    final second = api.requests.indexOf(gets.last);
    expect(api.queryOf(first)['page'], isNull,
        reason: 'offset walking is rejected by this cursor-only endpoint');
    expect(api.queryOf(first)['cursor'], isNull);
    expect(api.queryOf(first)['per_page'], 50);
    expect(api.queryOf(second)['cursor'], 'opaque-2',
        reason: 'the opaque cursor must be round-tripped verbatim');
    expect(api.misses, isEmpty);
  });

  test('a published empty page is empty, but a failure is an error', () async {
    container = boot();
    api.on('GET', '/quiz/reviews/due', _page([], hasMore: false));
    final source = QuizSrsRemoteDataSource(dioFor(api));
    expect(await source.getDueCards(), isEmpty);

    api = FakeApi(<String, FakeRoute>{
      'GET /quiz/reviews/due': FakeRoute.error(500, 'INTERNAL_ERROR', 'boom'),
    });
    final failing = QuizSrsRemoteDataSource(dioFor(api));
    await expectLater(failing.getDueCards(), throwsA(isA<DioException>()));
  });

  test('an unreadable 2xx body is contract drift, not zero cards', () async {
    container = boot();
    api.on('GET', '/quiz/reviews/due', FakeRoute.ok(<String, dynamic>{
      'unexpected': <dynamic>[],
    }));
    final source = QuizSrsRemoteDataSource(dioFor(api));

    await expectLater(source.getDueCards(), throwsA(isA<ContractViolation>()));
  });

  test('a stalled cursor is contract drift', () async {
    container = boot();
    api.on(
      'GET',
      '/quiz/reviews/due',
      _page([_questionCard(11)], hasMore: true, nextCursor: null),
    );
    final source = QuizSrsRemoteDataSource(dioFor(api));

    await expectLater(source.getDueCards(), throwsA(isA<ContractViolation>()));
  });

  test('an unknown card family is contract drift', () async {
    container = boot();
    final unknown = _questionCard(11)..['type'] = 'learning-atom';
    api.on('GET', '/quiz/reviews/due', _page([unknown], hasMore: false));
    final source = QuizSrsRemoteDataSource(dioFor(api));

    await expectLater(source.getDueCards(), throwsA(isA<ContractViolation>()));
  });

  test('a grade sends the server quality and refreshes the queue', () async {
    api.on('GET', '/quiz/reviews/due', _page([_questionCard(41)], hasMore: false));
    api.on(
      'PUT',
      '/quiz/reviews/41/grade',
      FakeRoute.ok(_gradeData(41, type: 'question')),
    );
    container = boot();
    // A listener makes the invalidation rebuild immediately, so the second
    // GET is observable without pumping the event loop by hand.
    final subscription = container.listen(quizSrsDueProvider, (_, __) {});
    await container.read(quizSrsDueProvider.future);

    final result = await container.read(quizSrsControllerProvider.notifier).grade(
          '41',
          quality: QuizSrsQuality.good,
          type: 'question',
        );

    expect(result, isNotNull);
    expect(result!.quality, QuizSrsQuality.good);
    expect(result.intervalDays, 9);
    expect(container.read(quizSrsControllerProvider).gradeError, isNull);

    final put = api.indexOfRequest('PUT', '/quiz/reviews/41/grade');
    expect(api.headerOf(put, 'Idempotency-Key'), isNotNull);
    expect(api.jsonBodyOf(put)['quality'], QuizSrsQuality.good);
    expect(api.jsonBodyOf(put)['type'], 'question');
    expect(api.jsonBodyOf(put).containsKey('interval_days'), isFalse,
        reason: 'scheduling is server-authoritative');
    await container.read(quizSrsDueProvider.future);
    expect(api.countOf('GET', '/quiz/reviews/due'), 2,
        reason: 'a successful grade refreshes the due queue');
    subscription.close();
  });

  test('a failed grade keeps the key for the retry and does not refresh',
      () async {
    api.on('GET', '/quiz/reviews/due', _page([_wordCard(42)], hasMore: false));
    api.onSequence('PUT', '/quiz/reviews/42/grade', [
      FakeRoute.error(500, 'INTERNAL_ERROR', 'boom'),
      FakeRoute.ok(_gradeData(42, type: 'word')),
    ]);
    container = boot();
    final subscription = container.listen(quizSrsDueProvider, (_, __) {});
    await container.read(quizSrsDueProvider.future);

    final controller = container.read(quizSrsControllerProvider.notifier);
    final first = await controller.grade(
      '42',
      quality: QuizSrsQuality.easy,
      type: 'word',
    );
    expect(first, isNull);
    expect(container.read(quizSrsControllerProvider).gradeError, isNotNull);
    expect(api.countOf('GET', '/quiz/reviews/due'), 1,
        reason: 'a failed grade must not silently refresh away the error');

    final second = await controller.grade(
      '42',
      quality: QuizSrsQuality.easy,
      type: 'word',
    );
    expect(second, isNotNull);
    expect(container.read(quizSrsControllerProvider).gradeError, isNull);

    final puts = api.requests
        .where((r) => r.method == 'PUT' && r.path.endsWith('/grade'))
        .toList();
    expect(puts, hasLength(2));
    final firstPut = api.requests.indexOf(puts.first);
    final secondPut = api.requests.indexOf(puts.last);
    expect(
      api.headerOf(firstPut, 'Idempotency-Key'),
      api.headerOf(secondPut, 'Idempotency-Key'),
      reason: 'a fresh key on retry would grade the card twice',
    );
    expect(api.jsonBodyOf(secondPut)['quality'], QuizSrsQuality.easy);
    await container.read(quizSrsDueProvider.future);
    expect(api.countOf('GET', '/quiz/reviews/due'), 2);
    subscription.close();
  });
}
