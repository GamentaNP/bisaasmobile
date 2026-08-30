import 'dart:async';
import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:bisaasmobile/core/network/refresh_interceptor.dart';
import 'package:bisaasmobile/core/security/token_manager.dart';

class MockSecureStorage extends Mock implements FlutterSecureStorage {}

ResponseBody _json(Object body, int code) => ResponseBody.fromString(
      jsonEncode(body),
      code,
      headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      },
    );

class ScriptedAdapter implements HttpClientAdapter {
  ScriptedAdapter(this.responses);
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

const _okProtected = '{"success":true,"data":{"attemptId":7}}';

void main() {
  late MockSecureStorage storage;
  late TokenManager tokens;

  setUp(() {
    storage = MockSecureStorage();
    when(() => storage.read(key: any(named: 'key'))).thenAnswer((inv) async {
      final key = inv.namedArguments[#key] as String;
      return switch (key) {
        'auth_token' => 'expired-token',
        'device_name' => 'dev-1',
        _ => null,
      };
    });
    when(() => storage.write(
          key: any(named: 'key'),
          value: any(named: 'value'),
        )).thenAnswer((_) async {});
    when(() => storage.delete(key: any(named: 'key'))).thenAnswer((_) async {});
    tokens = TokenManager(storage: storage);
  });

  Dio buildDio(ScriptedAdapter adapter) {
    final dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
      ..httpClientAdapter = adapter;
    dio.interceptors.add(RefreshInterceptor(tokens, dio));
    return dio;
  }

  test('401 → refresh → original request replayed with the new token', () async {
    final adapter = ScriptedAdapter([
      _json({'message': 'expired'}, 401),
      _json(
        {
          'success': true,
          'data': {'token': 'fresh-token', 'expires_at': '2027-01-01T00:00:00Z'},
        },
        200,
      ),
      ResponseBody.fromString(_okProtected, 200, headers: {
        Headers.contentTypeHeader: [Headers.jsonContentType],
      }),
    ]);
    final dio = buildDio(adapter);

    final res = await dio.get<dynamic>('/quiz/attempts/7');
    expect(res.statusCode, 200);

    // Request 2 is the single-use rotation with the device header.
    expect(adapter.requests[1].path, '/auth/refresh');
    expect(adapter.requests[1].headers['X-Device-Name'], 'dev-1');
    // Request 3 is the replay carrying the rotated token — and can never
    // trigger a second refresh (skipAuthRefresh extra).
    expect(adapter.requests[2].headers['Authorization'], 'Bearer fresh-token');
    expect(adapter.requests[2].extra['skipAuthRefresh'], isTrue);
    verify(() => storage.write(key: 'auth_token', value: 'fresh-token')).called(1);
  });

  test('failed refresh clears the session and surfaces the original 401', () async {
    final adapter = ScriptedAdapter([
      _json({'message': 'expired'}, 401),
      _json({'message': 'refresh token revoked'}, 401),
    ]);
    final dio = buildDio(adapter);

    await expectLater(
      dio.get<dynamic>('/quiz/attempts/7'),
      throwsA(isA<DioException>()),
    );
    verify(() => storage.delete(key: 'auth_token')).called(1);
    // No replay after a failed rotation.
    expect(adapter.requests, hasLength(2));
  });

  test('non-401 errors pass through without touching the refresh endpoint',
      () async {
    final adapter = ScriptedAdapter([
      _json({'message': 'boom'}, 500),
    ]);
    final dio = buildDio(adapter);

    await expectLater(
      dio.get<dynamic>('/quiz/attempts/7'),
      throwsA(isA<DioException>()),
    );
    expect(adapter.requests, hasLength(1));
  });
}
