/// A scripted HTTP transport for cross-layer integration tests.
///
/// The unit tests in this repository stub the layer *below* the one they
/// test: a repository test mocks the data source, a DTO test feeds a map.
/// Neither ever exercises the HTTP layer, the Dio interceptor chain or the
/// envelope parsing together — which is exactly where the production bugs
/// this repository has been fixing live.
///
/// [FakeApi] sits at the bottom of the stack: it speaks real HTTP-shaped
/// `ResponseBody`s to a real `Dio`, so the whole chain runs:
///
/// ```text
/// Dio → interceptors → HttpClientAdapter → ResponseBody
///      → envelope → DTO → domain entity → repository → controller → state
/// ```
///
/// Routes are matched on `METHOD path` with the query string ignored, so a
/// test asserts on the *request* separately (see [FakeApi.requests]) when the
/// query matters — which is how the cursor-pagination migration is pinned.
library;

import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';

/// One canned response.
class FakeRoute {
  const FakeRoute(this.statusCode, this.body);

  /// A 200 with the canonical success envelope around [data].
  factory FakeRoute.ok(Map<String, dynamic> data, {String? message}) =>
      FakeRoute(
        200,
        <String, dynamic>{
          'success': true,
          'data': data,
          'message': message ?? 'ok',
          'timestamp': '2026-10-20T00:00:00+00:00',
          'api_version': 'v1',
        },
      );

  /// A 200 whose body is already a full envelope (for endpoints that publish
  /// their own `pagination` block next to `data`).
  factory FakeRoute.envelope(Map<String, dynamic> envelope) =>
      FakeRoute(200, envelope);

  /// A canonical error envelope.
  factory FakeRoute.error(
    int statusCode,
    String code,
    String message, {
    Map<String, dynamic>? details,
  }) {
    final error = <String, dynamic>{
      'code': code,
      'message': message,
    };
    if (details != null) error['details'] = details;
    return FakeRoute(
      statusCode,
      <String, dynamic>{
        'success': false,
        'error': error,
        'message': message,
      },
    );
  }

  final int statusCode;
  final Map<String, dynamic> body;
}

/// A scripted `HttpClientAdapter`.
class FakeApi implements HttpClientAdapter {
  FakeApi(this.routes);

  /// Routes keyed by `"METHOD /path"`, e.g. `"GET /quiz/questions"`.
  final Map<String, FakeRoute> routes;

  /// Every request that was made, in order.
  final List<RequestOptions> requests = [];

  /// Routes that were requested but not scripted.
  final List<String> misses = <String>[];

  /// Registers a route.
  void on(String method, String path, FakeRoute route) {
    routes['$method $path'] = route;
  }

  /// The query parameters of the nth request, or an empty map.
  Map<String, dynamic> queryOf(int index) {
    if (index >= requests.length) return const <String, dynamic>{};
    return requests[index].queryParameters;
  }

  /// The request body of the nth request, decoded from JSON when possible.
  Object? bodyOf(int index) {
    if (index >= requests.length) return null;
    final data = requests[index].data;
    if (data is Map) return data;
    if (data is String) {
      try {
        return jsonDecode(data);
      } on FormatException {
        return data;
      }
    }
    return data;
  }

  /// The request body of the nth request as a JSON object.
  ///
  /// Throws when the body is missing or is not an object — a test that
  /// asserts on a request body wants to fail loudly when there is no body.
  Map<String, dynamic> jsonBodyOf(int index) {
    final body = bodyOf(index);
    if (body is Map<String, dynamic>) return body;
    throw StateError('Request #$index has no JSON object body: $body');
  }

  /// The index of the first request matching [method] and a path suffix.
  int indexOfRequest(String method, String pathSuffix) {
    return requests.indexWhere(
      (r) => r.method == method && r.path.endsWith(pathSuffix),
    );
  }

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    requests.add(options);
    final key = '${options.method} ${options.path}';
    final route = routes[key];
    if (route == null) {
      misses.add(key);
      return ResponseBody.fromString(
        jsonEncode(<String, dynamic>{
          'success': false,
          'error': <String, dynamic>{
            'code': 'NOT_FOUND',
            'message': 'No fake route for $key',
          },
        }),
        404,
        headers: {
          Headers.contentTypeHeader: [Headers.jsonContentType],
        },
      );
    }
    return ResponseBody.fromString(
      jsonEncode(route.body),
      route.statusCode,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );
  }
}

/// Builds a `Dio` that talks to [api] and behaves like the production client:
/// the same base URL shape, the same default headers, and the same
/// 2xx-only `validateStatus` (so a 4xx/5xx surfaces as an error rather
/// than being silently accepted as data).
Dio dioFor(FakeApi api) {
  final dio = Dio(
    BaseOptions(
      baseUrl: 'https://bisaas.test/api/v1',
      connectTimeout: const Duration(seconds: 5),
      receiveTimeout: const Duration(seconds: 5),
      sendTimeout: const Duration(seconds: 5),
      headers: const <String, String>{
        'Accept': 'application/json',
        'Content-Type': 'application/json',
        'Accept-Language': 'en',
      },
      validateStatus: (s) => s != null && s >= 200 && s < 300,
    ),
  )..httpClientAdapter = api;
  return dio;
}
