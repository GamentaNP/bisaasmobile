/// The organization context shown to the user, and the actions it permits.
///
/// This is intentionally thin. The server resolves the organization from the
/// **credential**, and only accepts `X-Tenant` when an active membership backs
/// it; so the client's job is to remember a choice, assert it, and get out of
/// the way. There is no local authorization decision here, no name resolution
/// against a guessed id, and no fallback that "just uses the first one".
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/network/dio_client.dart';
import '../../../../core/security/tenant_providers.dart';
import '../../../../core/security/tenant_store.dart';
import '../../../../core/security/token_manager.dart';
import '../../data/organization_remote_data_source.dart';
import '../../domain/entities/organization.dart';

class OrganizationContext {
  const OrganizationContext({
    required this.selectedId,
    required this.organizations,
    required this.failure,
  });

  /// The persisted selection, or null when the user has not chosen one.
  final int? selectedId;

  /// The organizations the server says the caller may assert.
  ///
  /// Null only while the list is genuinely unknown; an empty list is a real
  /// answer (a platform-pool user) and also means "no switcher".
  final List<Organization>? organizations;

  /// The last tenant refusal the server reported, if any.
  final TenantFailure? failure;

  /// A switcher is renderable only when there is a list to render.
  bool get switcherAvailable =>
      organizations != null && organizations!.isNotEmpty;

  Organization? get selected {
    final id = selectedId;
    final all = organizations;
    if (id == null || all == null) return null;
    for (final organization in all) {
      if (organization.id == id) return organization;
    }
    return null;
  }

  /// A mismatch is fixed by signing in again; an inactive organization is not.
  bool get requiresReauthentication => failure == TenantFailure.mismatch;
}

class OrganizationController extends AsyncNotifier<OrganizationContext> {
  @override
  Future<OrganizationContext> build() async {
    final store = ref.watch(tenantStoreProvider);
    // Cached in its own provider: the store listener below invalidates this
    // controller on every selection change, and a membership fetch per tap
    // would be both wasteful and a new way to fail at exactly the wrong moment.
    final organizations = await ref.watch(
      organizationMembershipsProvider.future,
    );
    var selectedId = await store.read();

    // A selection the server no longer lists is stale (membership revoked, or
    // the organization was deleted). Drop it *before* subscribing, so the
    // clear cannot invalidate the build that is running.
    if (selectedId != null && !organizations.any((o) => o.id == selectedId)) {
      await store.clear();
      selectedId = null;
    }

    // The interceptor clears the selection and records the failure outside
    // Riverpod's knowledge; without this the switcher would keep showing the
    // organization the server just refused.
    void onChange() => ref.invalidateSelf();
    store.addListener(onChange);
    ref.onDispose(() => store.removeListener(onChange));

    return OrganizationContext(
      selectedId: selectedId,
      organizations: organizations,
      failure: store.failure,
    );
  }

  /// Selects [organizationId] and asserts it on subsequent requests.
  ///
  /// Refuses an id the server did not list. That list is the only truthful
  /// source of assertable ids; accepting an arbitrary integer here would be the
  /// client choosing a scope, which the server contract explicitly rejects.
  Future<void> use(int organizationId) async {
    final current = await future;
    final organizations = current.organizations;
    final offered =
        organizations?.any(
          (o) => o.id == organizationId && o.isActive,
        ) ??
        false;
    if (!offered) {
      throw ArgumentError.value(
        organizationId,
        'organizationId',
        'is not an active organization offered by this build',
      );
    }
    await ref.read(tenantStoreProvider).select(organizationId);
  }

  /// Stops asserting an organization. Single-membership users fall back to the
  /// credential's stamp, which is exactly the pre-switcher behaviour.
  Future<void> clearSelection() => ref.read(tenantStoreProvider).clear();

  /// Ends the local session so the router's auth guard sends the user to login.
  ///
  /// Required after `TENANT_MISMATCH`: the credential on this device belongs to
  /// a different organization, and only a fresh login can mint one that
  /// matches the choice. The server still holds the old PAT until it expires;
  /// the local token is discarded so it cannot be replayed.
  Future<void> signInAgain() async {
    await ref.read(tenantStoreProvider).clear();
    await ref.read(endSessionProvider)();
  }

  /// Dismisses the failure once the user has seen it.
  void acknowledgeFailure() =>
      ref.read(tenantStoreProvider).acknowledgeFailure();
}

/// The membership list endpoint. `DioClient` is initialized in `bootstrap()`;
/// a provider that is read before that is a wiring bug, not an empty list.
final organizationRemoteDataSourceProvider =
    Provider<OrganizationRemoteDataSource>((ref) {
      if (!DioClient.isInitialized) {
        throw StateError('DioClient not init — see bootstrap.dart');
      }
      return OrganizationRemoteDataSource(DioClient.instance.dio);
    });

/// The caller's assertable organizations, fetched once and shared.
///
/// A failure propagates: a network error must not render as "you belong to no
/// organizations", which is the same silent-empty-list bug the rest of the
/// app forbids. The switcher screen offers a retry.
final organizationMembershipsProvider = FutureProvider<List<Organization>>(
  (ref) {
    return ref.watch(organizationRemoteDataSourceProvider).fetchMemberships();
  },
  // Riverpod 3 retries a failed provider with exponential backoff by default.
  // That would keep the switcher in a loading/retrying state and hide the
  // failure from the screen's own Retry button; the user decides when to try
  // again, and the error has to reach them first.
  retry: (retryCount, error) => null,
);

/// Clears the local credential. A provider rather than a direct
/// `TokenManager.shared` call so a test can prove the session is ended without
/// a platform channel.
final endSessionProvider = Provider<Future<void> Function()>(
  (ref) => TokenManager.shared.clear,
);

final organizationControllerProvider =
    AsyncNotifierProvider<OrganizationController, OrganizationContext>(
      OrganizationController.new,
      retry: (retryCount, error) => null,
    );
