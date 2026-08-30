import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bisaasmobile/core/network/retry_interceptor.dart';

/// Scripted adapter that returns queued responses per attempt and records
/// every request it sees — verifies retry counts and re-sent headers without
/// real HTTP.
class ScriptedAdapter implements HttpClientAdapter {
  ScriptedAdapter(this.responses);

  /// One entry per incoming request; a DioException entry throws.
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
    if (requests.length > responses.length) {
      throw StateError('Unexpected extra request ${options.method} ${options.path}');
    }
    final entry = responses[requests.length - 1];
    if (entry is DioException Function(RequestOptions)) {
      throw entry(options);
    }
    if (entry is DioException) throw entry;
    return entry as ResponseBody;
  }
}

ResponseBody ok() => ResponseBody.fromString(
      '{"success":true,"data":{}}',
      200,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

ResponseBody status(int code) =>
    ResponseBody.fromString('{"message":"no"}', code);

DioException timeoutErr(RequestOptions options) => DioException(
      // Real adapters throw with the actual request options — the retry
      // counter lives in options.extra.
      requestOptions: options,
      type: DioExceptionType.connectionTimeout,
    );

Dio _dioWith(ScriptedAdapter adapter, {Duration? baseDelay, int? maxRetries}) {
  final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
    ..httpClientAdapter = adapter;
  dio.interceptors.add(
    RetryInterceptor(
      dio: dio,
      baseDelay: baseDelay ?? Duration.zero,
      maxRetries: maxRetries ?? 3,
    ),
  );
  return dio;
}

void main() {
  test('GET 5xx retries and succeeds on a later attempt', () async {
    final adapter = ScriptedAdapter([status(500), status(500), ok()]);
    final dio = _dioWith(adapter);

    final res = await dio.get<dynamic>('/things');
    expect(res.statusCode, 200);
    expect(adapter.requests, hasLength(3));
  });

  test('POST without Idempotency-Key is never retried on 5xx', () async {
    final adapter = ScriptedAdapter([status(500)]);
    final dio = _dioWith(adapter);

    await expectLater(
      dio.post<dynamic>('/quiz/attempts/start', data: {'question': 1}),
      throwsA(isA<DioException>()),
    );
    // Exactly one request — no replay of a non-idempotent POST.
    expect(adapter.requests, hasLength(1));
  });

  test('POST with Idempotency-Key is retried and the key is re-sent', () async {
    final adapter = ScriptedAdapter([status(500), ok()]);
    final dio = _dioWith(adapter);

    await dio.post<dynamic>(
      '/quiz/attempts/start',
      options: Options(headers: {'Idempotency-Key': 'uuid-123'}),
      data: {'question': 1},
    );
    expect(adapter.requests, hasLength(2));
    expect(
      adapter.requests.every((r) => r.headers['Idempotency-Key'] == 'uuid-123'),
      isTrue,
    );
  });

  test('429 is retried even for non-idempotent POSTs', () async {
    final adapter = ScriptedAdapter([
      ResponseBody.fromString(
        '{"message":"slow down"}',
        429,
        headers: {
          'retry-after': ['0'],
        },
      ),
      ok(),
    ]);
    final dio = _dioWith(adapter);

    final res = await dio.post<dynamic>('/battle/move');
    expect(res.statusCode, 200);
    expect(adapter.requests, hasLength(2));
  });

  test('429 honors integer Retry-After seconds over base backoff', () async {
    final adapter = ScriptedAdapter([
      ResponseBody.fromString(
        '{"message":"slow down"}',
        429,
        headers: {
          'retry-after': ['0'],
        },
      ),
      ok(),
    ]);
    // One-hour base delay — if Retry-After were ignored this would hang.
    final dio = _dioWith(adapter, baseDelay: const Duration(hours: 1));

    final res = await dio.get<dynamic>('/things');
    expect(res.statusCode, 200);
  });

  test('connection errors on GET retry, then give up after maxRetries', () async {
    // Scripted as tear-offs so each throw carries the real request options.
    final adapter = ScriptedAdapter([
      timeoutErr,
      timeoutErr,
      timeoutErr,
      timeoutErr,
    ]);
    final dio = _dioWith(adapter, maxRetries: 3);

    await expectLater(dio.get<dynamic>('/things'), throwsA(isA<DioException>()));
    // 1 original + 3 retries.
    expect(adapter.requests, hasLength(4));
  });

  test('429 POST still counts against maxRetries', () async {
    final adapter = ScriptedAdapter([status(429), status(429), status(429)]);
    final dio = _dioWith(adapter, maxRetries: 2);

    await expectLater(
      dio.post<dynamic>('/battle/move'),
      throwsA(isA<DioException>()),
    );
    // 1 original + 2 retries — capped.
    expect(adapter.requests, hasLength(3));
  });
}
