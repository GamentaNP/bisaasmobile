/// The organization context shown to the user, and the actions it permits.
///
/// This is intentionally thin. The server resolves the organization from the
/// **credential**, and only accepts `X-Tenant` when an active membership backs
/// it; so the client's job is to remember a choice, assert it, and get out of
/// the way. There is no local authorization decision here, no name resolution
/// against a guessed id, and no fallback that "just uses the first one".
library;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/security/tenant_providers.dart';
import '../../../../core/security/tenant_store.dart';
import '../../../../core/security/token_manager.dart';
import '../../data/organization_directory.dart';
import '../../domain/entities/organization.dart';

class OrganizationContext {
  const OrganizationContext({
    required this.selectedId,
    required this.organizations,
    required this.failure,
  });

  /// The persisted selection, or null when the user has not chosen one.
  final int? selectedId;

  /// Null when no truthful list exists (see [OrganizationDirectory]).
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
    final directory = ref.watch(organizationDirectoryProvider);
    final organizations = directory.available;
    var selectedId = await store.read();

    // A selection this build's directory does not offer is stale (the list was
    // reprovisioned, or the organization was removed). Drop it *before*
    // subscribing, so the clear cannot invalidate the build that is running.
    // When there is no directory at all the selection is left alone — the
    // server remains the authority on whether the membership is real.
    if (selectedId != null &&
        organizations != null &&
        !organizations.any((o) => o.id == selectedId)) {
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
  /// Refuses an id the directory did not offer. The directory is the only
  /// truthful source of ids; accepting an arbitrary integer here would be the
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

/// The organization list, or a source that reports it has none.
final organizationDirectoryProvider = Provider<OrganizationDirectory>(
  (ref) => OrganizationDirectory(),
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
    );
