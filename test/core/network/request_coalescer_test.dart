import 'dart:async';
import 'dart:typed_data';

import 'package:bisaasmobile/core/network/request_coalescer.dart';
import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

/// A GET fired from six places should cost one round trip, not six.
///
/// This is not a micro-optimisation. `GET /quiz/courses` has six call sites,
/// `GET /me` fires twice on every cold start, and `GET /learning/today` has
/// three. On the 3G connections this app's users actually have, those duplicate
/// requests are the difference between a first paint that waits on seven
/// requests and one that waits on four.
void main() {
  late _CountingAdapter adapter;
  late Dio dio;

  setUp(() {
    adapter = _CountingAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://example.test/api/v1'))
      ..httpClientAdapter = adapter
      ..interceptors.add(RequestCoalescer());
  });

  Future<Response<dynamic>> get(
    String path, {
    Map<String, dynamic>? query,
    Options? options,
  }) {
    return dio.get<dynamic>(path, queryParameters: query, options: options);
  }

  group('coalescing', () {
    test('six identical GETs produce one network hit', () async {
      final responses = await Future.wait(
        List.generate(6, (_) => get('/quiz/courses')),
      );

      expect(adapter.hits, hasLength(1), reason: 'the other five should join');
      for (final response in responses) {
        expect(response.data, equals({'ok': true}));
        expect(response.statusCode, 200);
      }
    });

    test('each caller gets a response bound to its own RequestOptions', () async {
      // Handing the leader's Response over wholesale would leave every caller
      // reading another caller's request object.
      final responses = await Future.wait([
        get('/quiz/courses'),
        get('/quiz/courses'),
      ]);

      expect(
        responses.map((r) => identityHashCode(r.requestOptions)).toSet(),
        hasLength(2),
      );
    });

    test('a different query string is a different request', () async {
      await Future.wait([
        get('/syllabi', query: {'per_page': 1}),
        get('/syllabi', query: {'per_page': 20}),
      ]);

      expect(adapter.hits, hasLength(2));
    });

    test('query parameter order does not create a second request', () async {
      await Future.wait([
        get('/syllabi', query: {'page': 1, 'per_page': 20}),
        get('/syllabi', query: {'per_page': 20, 'page': 1}),
      ]);

      expect(adapter.hits, hasLength(1), reason: 'keys are sorted, so these match');
    });

    test('a different Accept-Language is a different request', () async {
      // A Nepali session must never be handed an English body.
      await Future.wait([
        get('/syllabi', options: Options(headers: {'Accept-Language': 'en'})),
        get('/syllabi', options: Options(headers: {'Accept-Language': 'ne'})),
      ]);

      expect(adapter.hits, hasLength(2));
    });
  });

  group('it is not a cache', () {
    test('a request after the first settles hits the network again', () async {
      await get('/quiz/courses');
      await get('/quiz/courses');

      expect(
        adapter.hits,
        hasLength(2),
        reason: 'serving stale data is a separate concern with separate rules',
      );
    });

    test('a failed request does not poison later ones', () async {
      adapter.status = 500;
      await expectLater(get('/quiz/courses'), throwsA(isA<DioException>()));

      adapter.status = 200;
      final response = await get('/quiz/courses');

      expect(response.statusCode, 200);
      expect(adapter.hits, hasLength(2));
    });
  });

  group('safety properties', () {
    test('a follower with a different credential is not given the leader body',
        () async {
      // Sign-out mid-flight: A's `/library/categories` is in the air when the
      // app signs in as B and asks for the same path. The body is
      // user-scoped on the server, so joining the leader would hand B A's file
      // counts. The credential is part of the key, so this is two requests.
      final a = dio.get<dynamic>(
        '/library/categories',
        options: Options(headers: {'Authorization': 'Bearer account-a'}),
      );
      final b = dio.get<dynamic>(
        '/library/categories',
        options: Options(headers: {'Authorization': 'Bearer account-b'}),
      );

      final responses = await Future.wait([a, b]);

      expect(adapter.hits, hasLength(2));
      for (final response in responses) {
        expect(response.statusCode, 200);
      }
    });

    test('a follower with the same credential is coalesced', () async {
      await Future.wait([
        dio.get<dynamic>(
          '/library/categories',
          options: Options(headers: {'Authorization': 'Bearer same'}),
        ),
        dio.get<dynamic>(
          '/library/categories',
          options: Options(headers: {'Authorization': 'Bearer same'}),
        ),
      ]);

      expect(adapter.hits, hasLength(1));
    });

    test('POST is never coalesced - two buyers must create two orders', () async {
      await Future.wait([
        dio.post<dynamic>('/economy/shop/purchase', data: {'sku': 'x'}),
        dio.post<dynamic>('/economy/shop/purchase', data: {'sku': 'x'}),
      ]);

      expect(
        adapter.hits,
        hasLength(2),
        reason: 'coalescing a mutation would silently drop an order',
      );
    });

    test('a retry replay is not joined to the request that failed', () async {
      adapter.status = 500;
      await expectLater(
        get('/quiz/courses'),
        throwsA(isA<DioException>()),
      );

      // RetryInterceptor replays with retry_attempt set. It must reach the
      // network rather than joining a future that already errored.
      adapter.status = 200;
      final response = await get(
        '/quiz/courses',
        options: Options(extra: {'retry_attempt': 1}),
      );

      expect(response.statusCode, 200);
      expect(adapter.hits, hasLength(2));
    });

    test('a streaming response is not shared', () async {
      await Future.wait([
        dio.get<dynamic>(
          '/learning/tutor',
          options: Options(responseType: ResponseType.stream),
        ),
        dio.get<dynamic>(
          '/learning/tutor',
          options: Options(responseType: ResponseType.stream),
        ),
      ]);

      expect(
        adapter.hits,
        hasLength(2),
        reason: 'two readers cannot share one stream body',
      );
    });
  });
}

/// Records every request and takes long enough that concurrent calls genuinely
/// overlap, which is the condition the coalescer exists to exploit.
class _CountingAdapter implements HttpClientAdapter {
  final List<String> hits = [];
  int status = 200;

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    hits.add('${options.method} ${options.path}');
    await Future<void>.delayed(const Duration(milliseconds: 60));
    const failure =
        '{"success":false,"message":"scripted failure","error":{"code":"SERVER_ERROR"}}';
    final body = status == 200 ? '{"ok":true}' : failure;
    return ResponseBody.fromString(
      body,
      status,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }

  @override
  void close({bool force = false}) {}
}
