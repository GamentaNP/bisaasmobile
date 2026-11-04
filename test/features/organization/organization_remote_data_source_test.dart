/// `GET /api/v1/me/tenants` — the switcher's only source of ids.
///
/// The shape is deliberate on the server (`MeTenantsController`):
/// `data.tenants`, active memberships only, no `is_active` field, no
/// pagination. Anything else is contract drift and must throw — an empty list
/// from a body the client did not understand would render as "you have no
/// organizations", which is the one thing the switcher must never lie about.
library;

import 'package:bisaasmobile/core/network/api_exception.dart';
import 'package:bisaasmobile/core/network/api_failure.dart';
import 'package:bisaasmobile/features/organization/data/organization_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../integration/support/fake_api.dart';

Map<String, dynamic> _membership(String name, int id) => <String, dynamic>{
  'id': id,
  'name': name,
  'slug': name.toLowerCase(),
  'role': 'learner',
};

void main() {
  group('the membership contract', () {
    test('reads data.tenants and keeps the server order', () async {
      final api = FakeApi(<String, FakeRoute>{})
        ..on(
          'GET',
          '/me/tenants',
          FakeRoute.ok(<String, dynamic>{
            'tenants': <Map<String, dynamic>>[
              _membership('Acme', 7),
              _membership('Zenith', 9),
            ],
          }),
        );

      final organizations = await OrganizationRemoteDataSource(
        dioFor(api),
      ).fetchMemberships();

      expect(organizations.map((o) => o.id), <int>[7, 9]);
      expect(organizations.first.name, 'Acme');
      expect(organizations.first.role, 'learner');
      // The route is not tenant-scoped and takes no parameters.
      expect(api.queryOf(0), isEmpty);
    });

    test('zero memberships is an empty list, not a violation', () async {
      final api = FakeApi(<String, FakeRoute>{})
        ..on(
          'GET',
          '/me/tenants',
          FakeRoute.ok(<String, dynamic>{'tenants': <dynamic>[]}),
        );

      final organizations = await OrganizationRemoteDataSource(
        dioFor(api),
      ).fetchMemberships();

      expect(organizations, isEmpty);
    });

    test('a bare data list is drift — the list lives under tenants', () async {
      final api = FakeApi(<String, FakeRoute>{})
        ..on(
          'GET',
          '/me/tenants',
          FakeRoute.ok(<String, dynamic>{}),
        );

      await expectLater(
        OrganizationRemoteDataSource(dioFor(api)).fetchMemberships(),
        throwsA(isA<ContractViolation>()),
      );
    });

    test('a malformed row invalidates the whole list', () async {
      // Dropping one row would silently hide an organization the user really
      // belongs to, and the switcher would offer a subset of the truth.
      final api = FakeApi(<String, FakeRoute>{})
        ..on(
          'GET',
          '/me/tenants',
          FakeRoute.ok(<String, dynamic>{
            'tenants': <dynamic>[
              _membership('Acme', 7),
              <String, dynamic>{'id': 'not-an-int', 'name': 'Broken'},
            ],
          }),
        );

      await expectLater(
        OrganizationRemoteDataSource(dioFor(api)).fetchMemberships(),
        throwsA(isA<ContractViolation>()),
      );
    });

    test('a 401 is an auth failure, not an empty membership list', () async {
      final api = FakeApi(<String, FakeRoute>{})
        ..on(
          'GET',
          '/me/tenants',
          FakeRoute.error(401, 'AUTH_UNAUTHENTICATED', 'Unauthenticated.'),
        );

      try {
        await OrganizationRemoteDataSource(dioFor(api)).fetchMemberships();
        fail('expected the request to fail');
      } on Object catch (error) {
        final mapped = toApiException(error);
        expect(mapped.code, ApiErrorCode.authUnauthenticated);
      }
    });
  });
}
