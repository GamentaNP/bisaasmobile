// CivilCal smoke test — validates bootstrap + routing against bisaas API contract.
import 'package:flutter_test/flutter_test.dart';
import 'package:bisaasmobile/app/config/api_config.dart';
import 'package:bisaasmobile/app/config/env.dart';
import 'package:bisaasmobile/core/network/api_exception.dart';

void main() {
  test('ApiConfig baseUrl is versioned v1', () {
    expect(ApiConfig.baseUrl.endsWith('/api/v1'), isTrue,
        reason: 'Client must always use /api/v1 — see MOBILE_API_INTEGRATION_GUIDE.md:11');
  });

  test('ApiConfig headers include Accept json', () {
    expect(ApiConfig.defaultHeaders['Accept'], 'application/json');
  });

  test('Env defaults to dev with bisaas.test', () {
    // In test, String.fromEnvironment defaults to dev
    expect(currentEnv().host, contains('bisaas'));
    expect(ApiConfig.baseUrl, contains('/api/v1'));
  });

  test('ApiException maps unknown error code to ApiErrorCode.unknown', () {
    final ex = ApiException.fromJson(
      500,
      {
        'error': {'code': 'TOTALLY_NEW_CODE', 'message': 'Unknown error'},
      },
      requestId: 'test-req-123',
    );
    expect(ex.code, ApiErrorCode.unknown);
    expect(ex.message, 'Unknown error');
    expect(ex.requestId, 'test-req-123');
  });

  test('ApiException maps known error codes accurately', () {
    final ex = ApiException.fromJson(
      401,
      {
        'error': {'code': 'AUTH_UNAUTHENTICATED', 'message': 'Unauthenticated'},
      },
    );
    expect(ex.code, ApiErrorCode.authUnauthenticated);
    expect(ex.isAuthError, isTrue);
  });
}
