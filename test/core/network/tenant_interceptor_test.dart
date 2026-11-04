/// P5-22 — the `X-Tenant` assertion, end to end through a real Dio.
///
/// The server contract (`App\Http\Middleware\EnforceTenantScope`) is narrow:
///
///   * no header  → the credential's stamp decides (single-membership users
///     work with no client involvement at all);
///   * a header that disagrees with the credential → `403 TENANT_MISMATCH`;
///   * a header backed by an active membership → resolves the tenant for a
///     bearer client.
///
/// So the header must be **absent** unless the user explicitly selected an
/// organization, and a mismatch must surface as its own code. The failure this
/// guards against is a stale selection: it would break the very users who need
/// no switcher, and the symptom (a 403 on every request) looks like a broken
/// session rather than a stale value.
library;

import 'package:bisaasmobile/core/network/api_exception.dart';
import 'package:bisaasmobile/core/network/api_failure.dart';
import 'package:bisaasmobile/core/network/tenant_interceptor.dart';
import 'package:bisaasmobile/core/security/tenant_store.dart';
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../../integration/support/fake_api.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

void main() {
  late _MockSecureStorage storage;

  setUp(() {
    storage = _MockSecureStorage();
    when(() => storage.read(key: 'selected_tenant_id'))
        .thenAnswer((_) async => null);
    when(() => storage.write(
          key: 'selected_tenant_id',
          value: any(named: 'value'),
        )).thenAnswer((_) async {});
    when(() => storage.delete(key: 'selected_tenant_id'))
        .thenAnswer((_) async {});
  });

  TenantStore store() => TenantStore(storage: storage);

  Dio dioFor_(FakeApi api, TenantStore tenants) {
    final dio = dioFor(api);
    dio.interceptors.add(TenantInterceptor(tenants));
    return dio;
  }

  group('the header is an assertion, not a selection', () {
    test('absent when the user has not selected an organization', () async {
      // This is the single-membership majority. The token already carries the
      // tenant; adding a header here could only disagree with it.
      final api = FakeApi(<String, FakeRoute>{})
        ..on('GET', '/app/config', FakeRoute.ok(<String, dynamic>{'ok': true}));

      await dioFor_(api, store()).get<dynamic>('/app/config');

      expect(api.headerOf(0, 'X-Tenant'), isNull);
      expect(api.headerOf(0, TenantInterceptor.header), isNull);
    });

    test('present when an organization is selected', () async {
      final api = FakeApi(<String, FakeRoute>{})
        ..on('GET', '/quiz/courses', FakeRoute.ok(<String, dynamic>{'ok': true}));
      final tenants = store();
      await tenants.select(42);

      await dioFor_(api, tenants).get<dynamic>('/quiz/courses');

      expect(api.headerOf(0, 'X-Tenant'), '42');
    });

    test('a corrupt stored value is treated as no selection', () async {
      // Forwarding "abc" gets a 400 from the server (the assertion must be a
      // tenant id), which would make a corrupt local value a permanently
      // broken session. Absent is recoverable; malformed is not.
      when(() => storage.read(key: 'selected_tenant_id'))
          .thenAnswer((_) async => 'not-a-number');
      final api = FakeApi(<String, FakeRoute>{})
        ..on('GET', '/quiz/courses', FakeRoute.ok(<String, dynamic>{'ok': true}));

      await dioFor_(api, store()).get<dynamic>('/quiz/courses');

      expect(api.headerOf(0, 'X-Tenant'), isNull);
    });

    test('an unselected client never inherits a header from a retry', () async {
      // A retried RequestOptions is a clone; if the header were copied it would
      // outlive the selection that justified it.
      final api = FakeApi(<String, FakeRoute>{})
        ..on('GET', '/quiz/courses', FakeRoute.ok(<String, dynamic>{'ok': true}));
      final tenants = store();
      final dio = dioFor_(api, tenants);

      await tenants.select(42);
      await dio.get<dynamic>(
        '/quiz/courses',
        options: Options(headers: <String, dynamic>{'X-Tenant': '42'}),
      );
      await tenants.clear();
      await dio.get<dynamic>(
        '/quiz/courses',
        options: Options(headers: <String, dynamic>{'X-Tenant': '42'}),
      );

      expect(api.headerOf(0, 'X-Tenant'), '42');
      expect(api.headerOf(1, 'X-Tenant'), isNull);
    });
  });

  group('a mismatch is its own failure', () {
    Future<ApiException> failWith(
      int status,
      String code, {
      required TenantStore tenants,
      int? selected,
    }) async {
      final api = FakeApi(<String, FakeRoute>{})
        ..on(
          'GET',
          '/quiz/attempts/history',
          FakeRoute.error(status, code, 'Refused.'),
        );
      if (selected != null) await tenants.select(selected);

      try {
        await dioFor_(api, tenants).get<dynamic>('/quiz/attempts/history');
      } on Object catch (error) {
        return toApiException(error);
      }
      fail('expected the request to fail');
    }

    test('403 TENANT_MISMATCH keeps its code through the failure mapper', () async {
      final error = await failWith(
        403,
        'TENANT_MISMATCH',
        tenants: store(),
        selected: 42,
      );

      expect(error.code, ApiErrorCode.tenantMismatch);
      expect(error.isTenantMismatch, isTrue);
      expect(error.isTenantInactive, isFalse);
      // Distinct from a permission refusal: the remedy is a new login.
      expect(error.code, isNot(ApiErrorCode.forbidden));
    });

    test('the refused selection is cleared, and the failure is recorded', () async {
      final api = FakeApi(<String, FakeRoute>{})
        ..on(
          'GET',
          '/quiz/attempts/history',
          FakeRoute.error(403, 'TENANT_MISMATCH', 'Refused.'),
        );
      final tenants = store();
      await tenants.select(42);

      await expectLater(
        dioFor_(api, tenants).get<dynamic>('/quiz/attempts/history'),
        throwsA(anything),
      );

      expect(await tenants.read(), isNull);
      expect(tenants.failure, TenantFailure.mismatch);
      verify(() => storage.delete(key: 'selected_tenant_id')).called(1);
    });

    test('the next request after a mismatch asserts nothing', () async {
      // Retrying with the refused header would 403 forever; retrying *without*
      // it moves the user into the credential's organization silently. Neither
      // is acceptable — the UI must re-authenticate instead.
      final api = FakeApi(<String, FakeRoute>{})
        ..on(
          'GET',
          '/quiz/attempts/history',
          FakeRoute.error(403, 'TENANT_MISMATCH', 'Refused.'),
        )
        ..on('GET', '/quiz/courses', FakeRoute.ok(<String, dynamic>{'ok': true}));
      final tenants = store();
      await tenants.select(42);
      final dio = dioFor_(api, tenants);

      await expectLater(
        dio.get<dynamic>('/quiz/attempts/history'),
        throwsA(anything),
      );
      await dio.get<dynamic>('/quiz/courses');

      expect(api.headerOf(0, 'X-Tenant'), '42');
      expect(api.headerOf(1, 'X-Tenant'), isNull);
    });

    test('a plain 403 does not clear the selection', () async {
      // Lacking a role is not a tenant problem. Clearing the selection here
      // would cost the user their choice for an unrelated permission error.
      final tenants = store();
      await failWith(403, 'FORBIDDEN', tenants: tenants, selected: 42);

      expect(await tenants.read(), 42);
      expect(tenants.failure, isNull);
    });

    test('TENANT_INACTIVE is recorded but does not promise a re-login', () async {
      final tenants = store();
      final error = await failWith(
        403,
        'TENANT_INACTIVE',
        tenants: tenants,
        selected: 42,
      );

      expect(error.isTenantInactive, isTrue);
      expect(error.isTenantMismatch, isFalse);
      expect(tenants.failure, TenantFailure.inactive);
      expect(await tenants.read(), isNull);
    });
  });
}
