import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'package:bisaasmobile/core/network/api_exception.dart';
import 'package:bisaasmobile/core/network/auth_interceptor.dart';
import 'package:bisaasmobile/core/security/token_manager.dart';

/// Security tamper matrix (FLUTTER_SENIOR_REVIEW §15 / plan Task 20 spec 100).
///
/// Verifies the client never trusts forged/absent credentials and never leaks
/// a session when the token is tampered with. These complement (not duplicate)
/// `token_manager_test` (lifecycle), `refresh_interceptor_test` (401 rotation)
/// and `retry_idempotency_test` (replay).
class MockTokenManager extends Mock implements TokenManager {}

class _CapturingAdapter implements HttpClientAdapter {
  _CapturingAdapter();
  ResponseBody? response;
  final List<RequestOptions> captured = [];

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    captured.add(options);
    return response ??
        ResponseBody.fromString(
          jsonEncode({'success': true, 'data': const <String, dynamic>{}}),
          200,
          headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
        );
  }
}

ResponseBody _json(Object body, int code) => ResponseBody.fromString(
      jsonEncode(body),
      code,
      headers: {Headers.contentTypeHeader: [Headers.jsonContentType]},
    );

void main() {
  late MockTokenManager tokens;
  late _CapturingAdapter adapter;
  late Dio dio;

  setUp(() {
    tokens = MockTokenManager();
    adapter = _CapturingAdapter();
    dio = Dio(BaseOptions(baseUrl: 'https://api.example.com'))
      ..httpClientAdapter = adapter;
    dio.interceptors.add(AuthInterceptor(tokens));
  });

  group('AuthInterceptor — credential trust', () {
    test('absent token sends NO Authorization header (cannot forge session)',
        () async {
      when(() => tokens.readToken()).thenAnswer((_) async => null);
      when(() => tokens.readDeviceName()).thenAnswer((_) async => null);

      await dio.get<dynamic>('/me');

      expect(adapter.captured.single.headers.containsKey('Authorization'),
          isFalse);
    });

    test('empty/tampered token is rejected — no Bearer emitted', () async {
      when(() => tokens.readToken()).thenAnswer((_) async => '');
      when(() => tokens.readDeviceName()).thenAnswer((_) async => null);

      await dio.get<dynamic>('/me');

      expect(adapter.captured.single.headers['Authorization'], isNull);
    });

    test('valid token attaches Bearer + Accept json always', () async {
      when(() => tokens.readToken()).thenAnswer((_) async => '1|secret');
      when(() => tokens.readDeviceName()).thenAnswer((_) async => 'pixel-6');

      await dio.get<dynamic>('/me');

      final h = adapter.captured.single.headers;
      expect(h['Authorization'], 'Bearer 1|secret');
      expect(h['Accept'], 'application/json');
      expect(h['X-Device-Name'], 'pixel-6');
    });
  });

  group('AuthInterceptor — error mapping', () {
    test('forged/unknown server error code maps to ApiErrorCode.unknown',
        () async {
      when(() => tokens.readToken()).thenAnswer((_) async => '1|secret');
      when(() => tokens.readDeviceName()).thenAnswer((_) async => null);
      adapter.response = _json({
        'success': false,
        'error': {'code': 'CLIENT_MINTED_COINS', 'message': 'nope'},
      }, 400);

      Object? capturedError;
      try {
        await dio.get<dynamic>('/me');
      } on DioException catch (e) {
        capturedError = e.error;
      }

      expect(capturedError, isA<ApiException>());
      expect((capturedError! as ApiException).code, ApiErrorCode.unknown);
    });

    test('401 is surfaced (not swallowed) so caller can refresh-vs-logout',
        () async {
      when(() => tokens.readToken()).thenAnswer((_) async => 'expired');
      when(() => tokens.readDeviceName()).thenAnswer((_) async => null);
      adapter.response = _json({
        'success': false,
        'error': {'code': 'UNAUTHENTICATED', 'message': 'token expired'},
      }, 401);

      DioException? thrown;
      try {
        await dio.get<dynamic>('/me');
      } on DioException catch (e) {
        thrown = e;
      }

      expect(thrown, isNotNull);
      expect(thrown!.response?.statusCode, 401);
      expect(thrown.error, isA<ApiException>());
    });
  });

  group('TokenManager — session revocation', () {
    test('clear() removes token + expiry but keeps deviceName', () async {
      final storage = MockSecureStorage();
      final written = <String, String>{};
      final deleted = <String>[];
      when(() => storage.write(
            key: any(named: 'key'),
            value: any(named: 'value'),
          )).thenAnswer((inv) async {
        written[inv.namedArguments[#key] as String] =
            inv.namedArguments[#value] as String;
      });
      when(() => storage.delete(key: any(named: 'key')))
          .thenAnswer((inv) async {
        deleted.add(inv.namedArguments[#key] as String);
      });
      final tm = TokenManager(storage: storage);

      await tm.persist(
          token: '1|abc', expiresAt: '2027-01-01T00:00:00Z', deviceName: 'p6');
      await tm.clear();

      expect(deleted, containsAll(['auth_token', 'auth_expires_at']));
      expect(deleted, isNot(contains('device_name')));
    });

    test('unparseable expiry does NOT force a refresh loop', () async {
      final storage = MockSecureStorage();
      when(() => storage.read(key: 'auth_expires_at'))
          .thenAnswer((_) async => 'not-a-date');
      final tm = TokenManager(storage: storage);

      expect(await tm.shouldRefresh(), isFalse);
    });

    test('near-expiry (<7d) triggers proactive refresh', () async {
      final storage = MockSecureStorage();
      final in3 = DateTime.now().add(const Duration(days: 3)).toIso8601String();
      when(() => storage.read(key: 'auth_expires_at'))
          .thenAnswer((_) async => in3);
      final tm = TokenManager(storage: storage);

      expect(await tm.shouldRefresh(), isTrue);
    });
  });
}

class MockSecureStorage extends Mock implements FlutterSecureStorage {}
