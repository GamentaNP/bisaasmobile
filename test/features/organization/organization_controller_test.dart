/// TN-09 — the organization context, fed by `GET /api/v1/me/tenants`.
///
/// Everything here follows from two server facts:
///
///   * the membership list is the only truthful source of assertable ids, and
///     it withholds inactive organizations and lapsed memberships;
///   * `X-Tenant` must name a value from that list, or `EnforceTenantScope`
///     answers `403 TENANT_MISMATCH`.
///
/// So the client's job is: render what the server listed, persist a choice,
/// and fail closed. No empty-list-as-success, no first-item fallback, no
/// locally-widened permission.
library;

import 'package:bisaasmobile/core/network/api_exception.dart';
import 'package:bisaasmobile/core/security/tenant_providers.dart';
import 'package:bisaasmobile/core/security/tenant_store.dart';
import 'package:bisaasmobile/features/organization/data/organization_remote_data_source.dart';
import 'package:bisaasmobile/features/organization/domain/entities/organization.dart';
import 'package:bisaasmobile/features/organization/presentation/controllers/organization_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

class _MockRemote extends Mock implements OrganizationRemoteDataSource {}

const _acme = Organization(
  id: 7,
  name: 'Acme Engineering',
  slug: 'acme',
  role: 'admin',
);
const _kathmandu = Organization(
  id: 9,
  name: 'Kathmandu Chapter',
  slug: 'kathmandu',
  role: 'learner',
);

void main() {
  late _MockSecureStorage storage;
  late _MockRemote remote;
  late TenantStore tenants;

  setUp(() {
    storage = _MockSecureStorage();
    when(
      () => storage.read(key: 'selected_tenant_id'),
    ).thenAnswer((_) async => null);
    when(
      () => storage.write(
        key: 'selected_tenant_id',
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(
      () => storage.delete(key: 'selected_tenant_id'),
    ).thenAnswer((_) async {});
    tenants = TenantStore(storage: storage);
    remote = _MockRemote();
  });

  ProviderContainer containerWith({
    List<Organization> organizations = const <Organization>[],
    ApiException? error,
    Future<void> Function()? endSession,
  }) {
    when(() => remote.fetchMemberships()).thenAnswer((_) async {
      if (error != null) throw error;
      return organizations;
    });
    final container = ProviderContainer(
      overrides: [
        tenantStoreProvider.overrideWithValue(tenants),
        organizationRemoteDataSourceProvider.overrideWithValue(remote),
        endSessionProvider.overrideWithValue(endSession ?? () async {}),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group("the list is the server's", () {
    test('a membership list makes the switcher available', () async {
      final container = containerWith(
        organizations: const [_acme, _kathmandu],
      );
      final state = await container.read(organizationControllerProvider.future);

      expect(state.organizations, hasLength(2));
      expect(state.switcherAvailable, isTrue);
      expect(state.organizations!.first.name, 'Acme Engineering');
      verify(() => remote.fetchMemberships()).called(1);
    });

    test('zero memberships is a real answer, and hides the switcher', () async {
      final container = containerWith();
      final state = await container.read(organizationControllerProvider.future);

      expect(state.organizations, isEmpty);
      expect(state.switcherAvailable, isFalse);
      expect(state.selected, isNull);
    });

    test(
      'a fetch failure propagates instead of rendering an empty list',
      () async {
        // The failure contract: "you belong to no organizations" and "the list
        // could not be loaded" must not look the same. The screen offers retry.
        final container = containerWith(
          error: const ApiException(
            statusCode: 503,
            code: ApiErrorCode.serviceUnavailable,
            message: 'down',
          ),
        );

        await expectLater(
          container.read(organizationControllerProvider.future),
          throwsA(isA<ApiException>()),
        );
        expect(
          container.read(organizationControllerProvider).value,
          isNull,
          reason: 'no state is produced from a failed list',
        );
      },
    );
  });

  group('selection is limited to what was listed', () {
    test('selecting a listed organization persists it', () async {
      final container = containerWith(
        organizations: const [_acme, _kathmandu],
      );
      await container.read(organizationControllerProvider.future);

      await container.read(organizationControllerProvider.notifier).use(7);

      verify(
        () => storage.write(key: 'selected_tenant_id', value: '7'),
      ).called(1);
      expect(await tenants.read(), 7);
      final state = await container.read(organizationControllerProvider.future);
      expect(state.selected?.name, 'Acme Engineering');
    });

    test('an id the server never listed cannot be selected', () async {
      final container = containerWith(organizations: const [_acme]);
      await container.read(organizationControllerProvider.future);

      await expectLater(
        container.read(organizationControllerProvider.notifier).use(99),
        throwsA(isA<ArgumentError>()),
      );
      verifyNever(
        () => storage.write(
          key: 'selected_tenant_id',
          value: any(named: 'value'),
        ),
      );
      expect(await tenants.read(), isNull);
    });

    test('a stored id the server no longer lists is dropped', () async {
      when(
        () => storage.read(key: 'selected_tenant_id'),
      ).thenAnswer((_) async => '99');
      final container = containerWith(organizations: const [_acme]);

      final state = await container.read(organizationControllerProvider.future);

      expect(state.selectedId, isNull);
      verify(() => storage.delete(key: 'selected_tenant_id')).called(1);
    });

    test('a stored id that is still listed survives', () async {
      when(
        () => storage.read(key: 'selected_tenant_id'),
      ).thenAnswer((_) async => '9');
      final container = containerWith(
        organizations: const [_acme, _kathmandu],
      );

      final state = await container.read(organizationControllerProvider.future);

      expect(state.selectedId, 9);
      expect(state.selected?.name, 'Kathmandu Chapter');
      verifyNever(() => storage.delete(key: 'selected_tenant_id'));
    });
  });

  group('the failure path', () {
    test(
      'a mismatch clears the selection and offers re-authentication',
      () async {
        final container = containerWith(organizations: const [_acme]);
        await container.read(organizationControllerProvider.future);
        await container.read(organizationControllerProvider.notifier).use(7);

        await tenants.reportFailure(TenantFailure.mismatch);
        final state = await container.read(
          organizationControllerProvider.future,
        );

        expect(state.selectedId, isNull);
        expect(state.failure, TenantFailure.mismatch);
        expect(state.requiresReauthentication, isTrue);
      },
    );

    test(
      'an inactive organization does not promise a new login will help',
      () async {
        final container = containerWith(organizations: const [_acme]);
        await container.read(organizationControllerProvider.future);

        await tenants.reportFailure(TenantFailure.inactive);
        final state = await container.read(
          organizationControllerProvider.future,
        );

        expect(state.failure, TenantFailure.inactive);
        expect(state.requiresReauthentication, isFalse);
      },
    );

    test('signing in again clears the tenant and the credential', () async {
      var ended = 0;
      final container = containerWith(
        organizations: const [_acme],
        endSession: () async => ended++,
      );
      await container.read(organizationControllerProvider.future);
      await container.read(organizationControllerProvider.notifier).use(7);

      await container
          .read(organizationControllerProvider.notifier)
          .signInAgain();

      expect(ended, 1, reason: 'the credential must not survive the refusal');
      expect(await tenants.read(), isNull);
      verify(() => storage.delete(key: 'selected_tenant_id')).called(1);
    });
  });
}
