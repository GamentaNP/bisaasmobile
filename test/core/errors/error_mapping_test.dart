import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bisaasmobile/core/errors/error_handler.dart';
import 'package:bisaasmobile/core/errors/failures.dart';
import 'package:bisaasmobile/core/network/api_exception.dart';

void main() {
  group('ApiException', () {
    test('maps known error codes, unknown codes fall back to generic', () {
      expect(ApiErrorCode.fromRaw('RATE_LIMIT_EXCEEDED'),
          ApiErrorCode.rateLimitExceeded);
      expect(ApiErrorCode.fromRaw('SOMETHING_NEW'), ApiErrorCode.unknown);
      expect(ApiErrorCode.fromRaw(null), ApiErrorCode.unknown);
    });

    test('fromJson parses the error envelope with request id', () {
      final e = ApiException.fromJson(429, {
        'success': false,
        'message': 'Too many attempts',
        'error': {
          'code': 'RATE_LIMIT_EXCEEDED',
          'message': 'Too many attempts',
          'request_id': 'req-42',
        },
      });
      expect(e.statusCode, 429);
      expect(e.code, ApiErrorCode.rateLimitExceeded);
      expect(e.message, 'Too many attempts');
      expect(e.requestId, 'req-42');
      expect(e.isAuthError, isFalse);
    });

    test('401 status marks auth errors regardless of code', () {
      final e = ApiException.fromJson(401, {
        'error': {'code': 'WHATEVER', 'message': 'x'},
      });
      expect(e.isAuthError, isTrue);
    });

    test('422 with field errors marks validation', () {
      final e = ApiException.fromJson(422, {
        'message': 'The given data was invalid.',
        'errors': {'email': ['The email must be a valid email address.']},
      });
      expect(e.isValidation, isTrue);
      expect(e.errors?['email'], isNotNull);
    });
  });

  group('ErrorHandler', () {
    test('validation ApiException → ValidationFailure with field errors', () {
      final f = ErrorHandler.handle(
        ApiException.fromJson(422, {
          'message': 'Invalid input',
          'errors': {'email': ['bad']},
        }),
      );
      expect(f, isA<ValidationFailure>());
      final vf = f as ValidationFailure;
      expect(vf.fieldErrors?['email'], isNotNull);
    });

    test('DioException carrying ApiException unwraps to NetworkFailure', () {
      final apiEx = ApiException.fromJson(403, {
        'error': {'code': 'FORBIDDEN', 'message': 'No access'},
      });
      final f = ErrorHandler.handle(DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.badResponse,
        error: apiEx,
      ));
      expect(f, isA<NetworkFailure>());
      expect(f.message, 'No access');
      expect((f as NetworkFailure).code, ApiErrorCode.forbidden);
    });

    test('connection timeouts map to a friendly message', () {
      final f = ErrorHandler.handle(DioException(
        requestOptions: RequestOptions(path: '/x'),
        type: DioExceptionType.connectionTimeout,
      ));
      expect(f.message, 'Connection failed. Check internet.');
    });

    test('unknown errors become NetworkFailure without crashing', () {
      final f = ErrorHandler.handle(StateError('weird'));
      expect(f, isA<NetworkFailure>());
      expect(f.message, contains('weird'));
    });
  });
}
