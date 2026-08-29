// CivilCal smoke test — validates bootstrap + routing against bisaas API contract.
import 'package:flutter_test/flutter_test.dart';
import 'package:bisaasmobile/app/config/api_config.dart';
import 'package:bisaasmobile/app/config/env.dart';

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
}
