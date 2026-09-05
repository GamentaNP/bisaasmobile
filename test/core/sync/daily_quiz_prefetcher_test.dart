import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:bisaasmobile/core/sync/daily_quiz_prefetcher.dart';
import 'package:bisaasmobile/features/quiz/data/datasources/quiz_local_data_source.dart';
import 'package:bisaasmobile/features/quiz/data/datasources/quiz_remote_data_source.dart';
import 'package:bisaasmobile/features/quiz/data/models/quiz_dto.dart';

class MockRemote extends Mock implements QuizRemoteDataSource {}

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

void main() {
  late MockRemote remote;
  late MockLocal local;

  setUp(() {
    remote = MockRemote();
    local = MockLocal();
    registerFallbackValue(const QuizSessionDto(
      id: '',
      title: '',
      questions: [],
      durationSeconds: 0,
    ));
  });

  DailyQuizPrefetcher build(Dio dio) => DailyQuizPrefetcher(
        dio: dio,
        remote: remote,
        local: local,
      );

  Dio dioWith(_ScriptedAdapter adapter) =>
      Dio(BaseOptions(baseUrl: 'https://api.example.com'))
        ..httpClientAdapter = adapter;

  group('DailyQuizPrefetcher.prefetchOnce', () {
    test('resolves course id from /quiz/daily then caches the session',
        () async {
      final adapter = _ScriptedAdapter([
        _json({
          'success': true,
          'data': {
            'schedule': {'quiz_id': 42},
          },
        }),
      ]);
      const session = QuizSessionDto(
        id: '42',
        title: 'Daily',
        questions: [],
        durationSeconds: 600,
      );
      when(() => remote.getQuizSession('42')).thenAnswer((_) async => session);
      when(() => local.cacheSession(any())).thenAnswer((_) async {});

      final ok = await build(dioWith(adapter)).prefetchOnce();

      expect(ok, isTrue);
      verify(() => remote.getQuizSession('42')).called(1);
      verify(() => local.cacheSession(session)).called(1);
    });

    test('no-ops when the schedule has no resolvable id', () async {
      final adapter = _ScriptedAdapter([
        _json({
          'success': true,
          'data': {
            'schedule': <String, dynamic>{},
          },
        }),
      ]);

      final ok = await build(dioWith(adapter)).prefetchOnce();

      expect(ok, isFalse);
      verifyNever(() => local.cacheSession(any()));
    });

    test('stays quiet (returns false) when offline', () async {
      final adapter = _ScriptedAdapter([
        DioException(
          requestOptions: RequestOptions(path: '/quiz/daily'),
          type: DioExceptionType.connectionError,
        ),
      ]);

      final ok = await build(dioWith(adapter)).prefetchOnce();

      expect(ok, isFalse);
      verifyNever(() => local.cacheSession(any()));
    });

    test('does not re-prefetch the same calendar day', () async {
      final adapter = _ScriptedAdapter([
        _json({
          'success': true,
          'data': {
            'schedule': {'course_id': 7},
          },
        }),
      ]);
      when(() => remote.getQuizSession('7'))
          .thenAnswer((_) async => const QuizSessionDto(
                id: '7',
                title: 'x',
                questions: [],
                durationSeconds: 0,
              ));
      when(() => local.cacheSession(any())).thenAnswer((_) async {});

      final p = build(dioWith(adapter));
      expect(await p.prefetchOnce(), isTrue);
      // Second call same-day short-circuits before hitting the network.
      expect(await p.prefetchOnce(), isFalse);
      verify(() => remote.getQuizSession('7')).called(1);
    });
  });
}
