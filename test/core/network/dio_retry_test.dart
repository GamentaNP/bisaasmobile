import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bisaasmobile/core/network/request_id_interceptor.dart';
import 'package:bisaasmobile/core/network/retry_interceptor.dart';

void main() {
  group('RequestIdInterceptor', () {
    test('attaches X-Request-Id UUID header if absent', () async {
      final interceptor = RequestIdInterceptor();
      final options = RequestOptions(path: '/test');

      interceptor.onRequest(options, RequestInterceptorHandler());

      expect(options.headers.containsKey('X-Request-Id'), isTrue);
      expect(options.headers['X-Request-Id'], isNotEmpty);
    });

    test('preserves existing X-Request-Id if already set', () async {
      final interceptor = RequestIdInterceptor();
      final options = RequestOptions(
        path: '/test',
        headers: {'X-Request-Id': 'custom-uuid-123'},
      );

      interceptor.onRequest(options, RequestInterceptorHandler());

      expect(options.headers['X-Request-Id'], equals('custom-uuid-123'));
    });
  });

  group('RetryInterceptor', () {
    test('initializes with default maxRetries and baseDelay', () {
      final interceptor = RetryInterceptor(dio: Dio());
      expect(interceptor.maxRetries, equals(3));
      expect(interceptor.baseDelay, equals(const Duration(milliseconds: 500)));
    });
  });
}
