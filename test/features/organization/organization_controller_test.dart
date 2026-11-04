/// TN-09 (partial) — the organization context, fail-closed.
///
/// The server has no membership-list endpoint, so the client cannot know which
/// organizations a user belongs to. Everything here follows from that:
///
///   * no list → no switcher (never an empty one, never a guessed entry);
///   * only ids the build's directory offered may be selected — a free integer
///     would be the client choosing a scope, which `EnforceTenantScope`
///     explicitly refuses for anything but a membership-backed assertion;
///   * a `TENANT_MISMATCH` ends the local session rather than silently
///     retrying into whatever tenant the credential happens to carry.
library;

import 'package:bisaasmobile/core/security/tenant_providers.dart';
import 'package:bisaasmobile/core/security/tenant_store.dart';
import 'package:bisaasmobile/features/organization/data/organization_directory.dart';
import 'package:bisaasmobile/features/organization/presentation/controllers/organization_controller.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

class _MockSecureStorage extends Mock implements FlutterSecureStorage {}

const _twoOrganizations =
    '[{"id":7,"name":"Acme Engineering","slug":"acme","role":"admin","is_active":true},{"id":9,"name":"Closed Chapter","slug":"closed","role":"learner","is_active":false}]';

void main() {
  late _MockSecureStorage storage;
  late TenantStore tenants;

  setUp(() {
    storage = _MockSecureStorage();
    when(() => storage.read(key: 'selected_tenant_id'))
        .thenAnswer((_) async => null);
    when(
      () => storage.write(
        key: 'selected_tenant_id',
        value: any(named: 'value'),
      ),
    ).thenAnswer((_) async {});
    when(() => storage.delete(key: 'selected_tenant_id'))
        .thenAnswer((_) async {});
    tenants = TenantStore(storage: storage);
  });

  ProviderContainer containerWith({
    OrganizationDirectory? directory,
    Future<void> Function()? endSession,
  }) {
    final container = ProviderContainer(
      overrides: [
        tenantStoreProvider.overrideWithValue(tenants),
        if (directory != null)
          organizationDirectoryProvider.overrideWithValue(directory),
        endSessionProvider.overrideWithValue(endSession ?? () async {}),
      ],
    );
    addTearDown(container.dispose);
    return container;
  }

  group('without a directory there is no switcher', () {
    test('an empty define reports no organizations', () async {
      final container = containerWith(
        directory: OrganizationDirectory(source: ''),
      );
      final state = await container.read(organizationControllerProvider.future);

      expect(state.organizations, isNull);
      expect(state.switcherAvailable, isFalse);
      expect(state.selected, isNull);
    });

    test('malformed JSON fails closed instead of half-parsing', () async {
      final container = containerWith(
        directory: OrganizationDirectory(source: '{"id":7,"name":"Acme"}'),
      );
      final state = await container.read(organizationControllerProvider.future);

      expect(state.organizations, isNull);
      expect(state.switcherAvailable, isFalse);
    });

    test('a row with a non-integer id invalidates the whole list', () async {
      // Dropping just the bad row would silently hide an organization the
      // user really belongs to, with no explanation for why it is missing.
      final container = containerWith(
        directory: OrganizationDirectory(
          source: '[{"id":"7","name":"Acme"},{"id":9,"name":"Other"}]',
        ),
      );
      final state = await container.read(organizationControllerProvider.future);

      expect(state.organizations, isNull);
    });

    test('an id the directory never offered cannot be selected', () async {
      // This is the fail-closed path: without a list, `use()` must not persist
      // an arbitrary scope.
      final container = containerWith(
        directory: OrganizationDirectory(source: ''),
      );
      await container.read(organizationControllerProvider.future);

      await expectLater(
        container.read(organizationControllerProvider.notifier).use(7),
        throwsA(isA<ArgumentError>()),
      );
      expect(await tenants.read(), isNull);
      verifyNever(
        () => storage.write(
          key: 'selected_tenant_id',
          value: any(named: 'value'),
        ),
      );
    });
  });

  group('with a directory the context is real', () {
    test('lists the organizations the build was provisioned for', () async {
      final container = containerWith(
        directory: OrganizationDirectory(source: _twoOrganizations),
      );
      final state = await container.read(organizationControllerProvider.future);

      expect(state.switcherAvailable, isTrue);
      expect(state.organizations, hasLength(2));
      expect(state.organizations!.first.name, 'Acme Engineering');
      expect(state.organizations!.last.isActive, isFalse);
    });

    test('selecting an offered organization persists it', () async {
      final container = containerWith(
        directory: OrganizationDirectory(source: _twoOrganizations),
      );
      await container.read(organizationControllerProvider.future);

      await container.read(organizationControllerProvider.notifier).use(7);

      verify(
        () => storage.write(key: 'selected_tenant_id', value: '7'),
      ).called(1);
      expect(await tenants.read(), 7);
      final state = await container.read(organizationControllerProvider.future);
      expect(state.selectedId, 7);
      expect(state.selected?.name, 'Acme Engineering');
    });

    test('an inactive organization cannot be selected', () async {
      final container = containerWith(
        directory: OrganizationDirectory(source: _twoOrganizations),
      );
      await container.read(organizationControllerProvider.future);

      await expectLater(
        container.read(organizationControllerProvider.notifier).use(9),
        throwsA(isA<ArgumentError>()),
      );
      expect(await tenants.read(), isNull);
    });

    test('a stored id the directory no longer offers is dropped', () async {
      when(() => storage.read(key: 'selected_tenant_id'))
          .thenAnswer((_) async => '99');
      final container = containerWith(
        directory: OrganizationDirectory(source: _twoOrganizations),
      );

      final state = await container.read(organizationControllerProvider.future);

      expect(state.selectedId, isNull);
      verify(() => storage.delete(key: 'selected_tenant_id')).called(1);
    });

    test('without a directory a stored id is left for the server to judge', () async {
      // The directory is a convenience for the switch surface, not an
      // authority on membership. A provisioned build that lost its define
      // must not silently stop asserting a selection the server still accepts.
      when(() => storage.read(key: 'selected_tenant_id'))
          .thenAnswer((_) async => '7');
      final container = containerWith(
        directory: OrganizationDirectory(source: ''),
      );

      final state = await container.read(organizationControllerProvider.future);

      expect(state.selectedId, 7);
      expect(state.switcherAvailable, isFalse);
      verifyNever(
        () => storage.delete(key: 'selected_tenant_id'),
      );
    });
  });

  group('the failure path', () {
    test(
      'a mismatch clears the selection and offers re-authentication',
      () async {
        final container = containerWith(
          directory: OrganizationDirectory(source: _twoOrganizations),
        );
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
        final container = containerWith(
          directory: OrganizationDirectory(source: _twoOrganizations),
        );
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
        directory: OrganizationDirectory(source: _twoOrganizations),
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
