import 'dart:convert';
import 'dart:typed_data';

import 'package:bisaasmobile/core/sync/daily_quiz_prefetcher.dart';
import 'package:bisaasmobile/features/quiz/data/datasources/quiz_local_data_source.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class MockLocal extends Mock implements QuizLocalDataSource {}

class _ScriptedAdapter implements HttpClientAdapter {
  _ScriptedAdapter(this.responses);
  final List<Object> responses;
  final List<RequestOptions> requests = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final entry = responses[requests.length - 1];
    if (entry is DioException) throw entry;
    return entry as ResponseBody;
  }
}

ResponseBody _json(Object body, [int code = 200]) => ResponseBody.fromString(
      jsonEncode(body),
      code,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );

/// `GET /api/v1/mobile/daily-quiz-pack` ships on the backend
/// (`Mobile\DailyQuizPackController`). The prefetcher previously called
/// `GET /quiz/daily`, guessed a course id from four possible keys and then
/// cached a whole course session — a different question set from the daily quiz.
/// These pin the new single-call path.
void main() {
  late MockLocal local;

  setUp(() {
    local = MockLocal();
    when(() => local.cacheDailyPack(
          quizId: any(named: 'quizId'),
          questions: any(named: 'questions'),
          subjectSlug: any(named: 'subjectSlug'),
        )).thenAnswer((_) async {});
  });

  DailyQuizPrefetcher build(Dio dio) => DailyQuizPrefetcher(dio: dio, local: local);

  Dio dioWith(_ScriptedAdapter adapter) =>
      Dio(BaseOptions(baseUrl: 'https://api.example.com'))
        ..httpClientAdapter = adapter;

  Map<String, dynamic> pack({
    int? quizId = 42,
    String date = '2026-09-28',
    List<Map<String, dynamic>>? questions,
  }) {
    return {
      'success': true,
      'data': {
        'quiz_id': quizId,
        'valid_for_date': date,
        'already_completed': false,
        'questions': questions ??
            [
              {'id': 1, 'body': 'Q1', 'options': <dynamic>[], 'image_url': null},
              {'id': 2, 'body': 'Q2', 'options': <dynamic>[], 'image_url': null},
            ],
        'question_image_urls': <String>[],
      },
    };
  }

  group('prefetchOnce', () {
    test('fetches the pack in one call and caches it', () async {
      final adapter = _ScriptedAdapter([_json(pack())]);

      final ok = await build(dioWith(adapter)).prefetchOnce();

      expect(ok, isTrue);
      // Exactly one request — no course-id resolution round-trip.
      expect(adapter.requests, hasLength(1));
      expect(adapter.requests.single.path, '/mobile/daily-quiz-pack');
      verify(() => local.cacheDailyPack(
            quizId: '42',
            questions: any(named: 'questions'),
            subjectSlug: any(named: 'subjectSlug'),
          )).called(1);
    });

    test('asks the server for a specific date', () async {
      final adapter = _ScriptedAdapter([_json(pack())]);

      await build(dioWith(adapter)).prefetchOnce();

      final q = adapter.requests.single.queryParameters;
      expect(q['date'], isNotNull);
      // Y-m-d, which is what the controller validates with date_format.
      expect('${q['date']}', matches(RegExp(r'^\d{4}-\d{2}-\d{2}$')));
    });

    test('no-ops when no daily quiz is published for the date', () async {
      // `quiz_id: null` + empty questions is the controller's documented
      // "no published daily quiz" response, not a fault.
      final adapter = _ScriptedAdapter([
        _json(pack(quizId: null, questions: const [])),
      ]);

      final ok = await build(dioWith(adapter)).prefetchOnce();

      expect(ok, isFalse);
      verifyNever(() => local.cacheDailyPack(
            quizId: any(named: 'quizId'),
            questions: any(named: 'questions'),
            subjectSlug: any(named: 'subjectSlug'),
          ));
    });

    test('no-ops on an unparseable payload instead of caching junk', () async {
      final adapter = _ScriptedAdapter([_json({'success': true})]);

      final ok = await build(dioWith(adapter)).prefetchOnce();

      expect(ok, isFalse);
      verifyNever(() => local.cacheDailyPack(
            quizId: any(named: 'quizId'),
            questions: any(named: 'questions'),
            subjectSlug: any(named: 'subjectSlug'),
          ));
    });

    test('stays quiet (returns false) when offline', () async {
      final adapter = _ScriptedAdapter([
        DioException(
          requestOptions: RequestOptions(path: '/mobile/daily-quiz-pack'),
          type: DioExceptionType.connectionError,
        ),
      ]);

      final ok = await build(dioWith(adapter)).prefetchOnce();

      expect(ok, isFalse);
      verifyNever(() => local.cacheDailyPack(
            quizId: any(named: 'quizId'),
            questions: any(named: 'questions'),
            subjectSlug: any(named: 'subjectSlug'),
          ));
    });

    test('does not re-prefetch the same calendar day', () async {
      final adapter = _ScriptedAdapter([_json(pack())]);

      final p = build(dioWith(adapter));
      expect(await p.prefetchOnce(), isTrue);
      // Second call short-circuits before touching the network.
      expect(await p.prefetchOnce(), isFalse);
      expect(adapter.requests, hasLength(1));
    });
  });
}
