/// Cross-layer test for the store-policy account deletion contract.
///
/// Route (Play requirement for apps with account creation):
///   * `DELETE /api/v1/account` — server-side erasure; 403 = an active
///     subscription blocks deletion.
///
/// The regression pinned here: deletion used to be called straight off the
/// settings screen with a raw Dio, so nothing owned the endpoint and the
/// local session clear lived in a widget. Now the repository owns it — the
/// server call and the token clear happen together or not at all, and the
/// 403 "subscription active" case must NOT clear the session (the account
/// still exists server-side).
library;

import 'package:bisaasmobile/core/network/api_exception.dart';
import 'package:bisaasmobile/core/security/tenant_store.dart';
import 'package:bisaasmobile/core/security/token_manager.dart';
import 'package:bisaasmobile/features/auth/data/datasources/auth_remote_data_source.dart';
import 'package:bisaasmobile/features/auth/data/datasources/social_sign_in_gateway.dart';
import 'package:bisaasmobile/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import 'support/fake_api.dart';

class _MockTokenManager extends Mock implements TokenManager {}

class _MockGateway extends Mock implements SocialSignInGateway {}

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late FakeApi api;
  late _MockTokenManager tokens;
  late _MockSecureStorage tenantStorage;
  late AuthRepositoryImpl repo;

  setUp(() {
    api = FakeApi(<String, FakeRoute>{});
    tokens = _MockTokenManager();
    when(() => tokens.clear()).thenAnswer((_) async {});
    tenantStorage = _MockSecureStorage();
    when(() => tenantStorage.delete(key: 'selected_tenant_id'))
        .thenAnswer((_) async {});
    repo = AuthRepositoryImpl(
      remoteDataSource: AuthRemoteDataSource(dioFor(api)),
      tokenManager: tokens,
      socialSignInGateway: _MockGateway(),
      tenantStore: TenantStore(storage: tenantStorage),
    );
  });

  group('DELETE /account', () {
    test('success hits the route and clears the local session', () async {
      api.on('DELETE', '/account', FakeRoute.ok(<String, dynamic>{}));

      await repo.deleteAccount();

      expect(api.indexOfRequest('DELETE', '/account'), 0);
      verify(() => tokens.clear()).called(1);
    });

    test('403 (active subscription) propagates and keeps the session',
        () async {
      api.on(
        'DELETE',
        '/account',
        FakeRoute.error(403, 'FORBIDDEN', 'You have an active subscription'),
      );

      await expectLater(
        repo.deleteAccount(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.statusCode,
            'status',
            403,
          ),
        ),
      );

      verifyNever(() => tokens.clear());
    });

    test('a 500 propagates — an outage is not a deleted account', () async {
      api.on(
        'DELETE',
        '/account',
        FakeRoute.error(500, 'SERVER_ERROR', 'boom'),
      );

      await expectLater(
        repo.deleteAccount(),
        throwsA(
          isA<ApiException>().having(
            (e) => e.statusCode,
            'status',
            500,
          ),
        ),
      );

      verifyNever(() => tokens.clear());
    });
  });
}
