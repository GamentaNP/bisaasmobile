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

    test('422 marks validation even without an error envelope', () {
      // The top-level `errors` shape the guide once promised was never
      // shipped by the server, so it is not parsed: field errors come from
      // error.details only. A bare 422 still marks validation via status.
      final e = ApiException.fromJson(422, {
        'message': 'The given data was invalid.',
        'errors': {'email': ['The email must be a valid email address.']},
      });
      expect(e.isValidation, isTrue);
      expect(e.fieldErrors, isNull);
    });

    test('validation field errors come from error.details (the real wire shape)', () {
      // The frozen envelope carries field errors at error.details — the
      // top-level `errors` mirror the guide once promised does not exist.
      final e = ApiException.fromJson(422, {
        'message': 'The token field is required.',
        'error': {
          'code': 'VALIDATION_ERROR',
          'details': {
            'platform': ['The selected platform is invalid.'],
            'token': ['The token field is required.'],
          },
        },
      });
      expect(e.isValidation, isTrue);
      expect(e.fieldErrors?['token'], isNotNull);
      expect(e.fieldErrors?['platform'], isNotNull);
    });

    test('error.details as an empty array (contract-allowed) yields null fieldErrors', () {
      // error.details is an object OR an empty JSON array; clients must
      // tolerate the array form without crashing.
      final e = ApiException.fromJson(422, {
        'message': 'The given data was invalid.',
        'error': {'code': 'VALIDATION_ERROR', 'details': <dynamic>[]},
      });
      expect(e.isValidation, isTrue);
      expect(e.fieldErrors, isNull);
    });

    test('ValidationFailure.fieldErrorTexts flattens list values to display strings', () {
      final failure = ErrorHandler.handle(
        ApiException.fromJson(422, {
          'message': 'The given data was invalid.',
          'error': {
            'code': 'VALIDATION_ERROR',
            'details': {
              'email': ['The email has already been taken.'],
              'password': ['too short', 'too common'],
              'note': 'bare string form',
              'blank': <String>[],
            },
          },
        }),
      );
      expect(failure, isA<ValidationFailure>());
      final texts = (failure as ValidationFailure).fieldErrorTexts;
      expect(texts['email'], 'The email has already been taken.');
      expect(texts['password'], 'too short\ntoo common');
      expect(texts['note'], 'bare string form');
      expect(texts.containsKey('blank'), isFalse);
    });

    test('newly mapped server codes resolve to their enum cases', () {
      expect(ApiErrorCode.fromRaw('AUTH_TOKEN_REVOKED'), ApiErrorCode.authTokenRevoked);
      expect(ApiErrorCode.fromRaw('AUTH_MFA_REQUIRED'), ApiErrorCode.authMfaRequired);
      expect(ApiErrorCode.fromRaw('MAINTENANCE_MODE'), ApiErrorCode.maintenanceMode);
      expect(ApiErrorCode.fromRaw('INSUFFICIENT_COINS'), ApiErrorCode.insufficientCoins);
      expect(ApiErrorCode.fromRaw('PLAN_UPGRADE_REQUIRED'), ApiErrorCode.planUpgradeRequired);
      expect(ApiErrorCode.fromRaw('FEATURE_DISABLED'), ApiErrorCode.featureDisabled);
      expect(ApiErrorCode.fromRaw('IDEMPOTENCY_KEY_REQUIRED'), ApiErrorCode.idempotencyKeyRequired);
    });

    test('isMaintenance keys on MAINTENANCE_MODE only, never on bare 503', () {
      // The server registry maps SERVICE_UNAVAILABLE and the whole AI/gateway
      // family to 503 as well (ApiErrorCode.php) — those feature-scoped
      // refusals must stay retryable, not route to the kill-switch screen.
      expect(
        ApiException.fromJson(503, {
          'error': {'code': 'MAINTENANCE_MODE', 'message': 'Under maintenance'},
        }).isMaintenance,
        isTrue,
      );
      expect(
        ApiException.fromJson(503, {
          'error': {'code': 'SERVICE_UNAVAILABLE', 'message': 'Circuit open'},
        }).isMaintenance,
        isFalse,
      );
      // Unmapped AI-family codes resolve to `unknown` and must not match.
      expect(
        ApiException.fromJson(503, {
          'error': {'code': 'AI_PROVIDER_CIRCUIT_OPEN', 'message': 'x'},
        }).isMaintenance,
        isFalse,
      );
      expect(
        ApiException.fromJson(500, {
          'error': {'code': 'INTERNAL_ERROR', 'message': 'x'},
        }).isMaintenance,
        isFalse,
      );
    });
  });

  group('ErrorHandler', () {
    test('validation without error.details → ValidationFailure, no field errors', () {
      final f = ErrorHandler.handle(
        ApiException.fromJson(422, {
          'message': 'Invalid input',
          // The top-level `errors` shape was never shipped by the server
          // and is not parsed; there is nothing to lift per-field.
          'errors': {'email': ['bad']},
        }),
      );
      expect(f, isA<ValidationFailure>());
      expect((f as ValidationFailure).fieldErrors, isNull);
    });

    test('validation from error.details → ValidationFailure with field errors', () {
      final f = ErrorHandler.handle(
        ApiException.fromJson(422, {
          'message': 'Invalid input',
          'error': {
            'code': 'VALIDATION_ERROR',
            'details': {'email': ['bad']},
          },
        }),
      );
      expect(f, isA<ValidationFailure>());
      final vf = f as ValidationFailure;
      expect(vf.fieldErrors?['email'], isNotNull);
    });

    test('MAINTENANCE_MODE → MaintenanceFailure, not a retryable network error', () {
      final f = ErrorHandler.handle(
        ApiException.fromJson(503, {
          'error': {'code': 'MAINTENANCE_MODE', 'message': 'Scheduled maintenance'},
        }),
      );
      expect(f, isA<MaintenanceFailure>());
      expect(f.message, 'Scheduled maintenance');
    });

    test('SERVICE_UNAVAILABLE 503 → NetworkFailure, never MaintenanceFailure', () {
      // Feature-scoped unavailability (AI circuit open, gateway not
      // configured, …) shares status 503 with the kill switch; only the
      // code tells them apart.
      final f = ErrorHandler.handle(
        ApiException.fromJson(503, {
          'error': {'code': 'SERVICE_UNAVAILABLE', 'message': 'Circuit open'},
        }),
      );
      expect(f, isA<NetworkFailure>());
      expect(f, isNot(isA<MaintenanceFailure>()));
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
      // Must stay in lockstep with the shipped `errTimeout` copy the l10n
      // audit froze (bdcdb9e) — the old literal drifted once already.
      expect(f.message, 'The request timed out. Check your connection and try again.');
    });

    test('unknown errors become NetworkFailure without crashing', () {
      final f = ErrorHandler.handle(StateError('weird'));
      expect(f, isA<NetworkFailure>());
      expect(f.message, contains('weird'));
    });
  });
}
