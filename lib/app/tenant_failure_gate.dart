/// Global tenant-refusal gate.
///
/// The interceptor records a `TENANT_MISMATCH` / `TENANT_INACTIVE` in
/// [TenantStore] and clears the stale assertion before any screen can react.
/// This widget is the *global* surface for that state: it sits above the
/// router so a refusal on any screen — not just Settings → Organization —
/// takes over the whole app with the right remedy.
///
/// The two failures are deliberately different:
///
///  * mismatch → the credential no longer matches the chosen workspace. The
///    assertion is already gone; offer a friendly "choose it again" re-auth.
///  * inactive → the workspace is closed. Re-authenticating cannot reopen it,
///    so there is **no retry** (automatic or otherwise); show a dedicated
///    full-screen state and only a sign-out escape hatch.
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/security/tenant_providers.dart';
import '../core/security/tenant_store.dart';
import '../features/organization/presentation/controllers/organization_controller.dart'
    show endSessionProvider;
import '../l10n/app_localizations.dart';

/// Wraps the app and replaces the surface while a tenant refusal is active.
///
/// Reads the store through a provider so tests can inject one, then follows
/// its `notifyListeners()` with a [ListenableBuilder] — no polling, no network
/// fetch, no retry. Resolving a display name locally (from the remembered
/// selection) is what keeps a closed workspace off the network entirely.
class TenantFailureGate extends ConsumerWidget {
  const TenantFailureGate({super.key, required this.child});

  final Widget child;

  Future<void> _endSession(WidgetRef ref) async {
    // Drop both halves of the stale identity. Clearing the token notifies the
    // router's refreshListenable, which sends the user to login; clearing the
    // tenant makes sure the next credential never inherits the refused scope.
    await ref.read(tenantStoreProvider).clear();
    await ref.read(endSessionProvider)();
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final store = ref.watch(tenantStoreProvider);
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        final failure = store.failure;
        if (failure == null) return child;
        if (failure == TenantFailure.mismatch) {
          return _TenantMismatchScreen(
            onSignInAgain: () => _endSession(ref),
          );
        }
        return _TenantInactiveScreen(
          workspaceName: store.failureTenantName,
          onSignOut: () => _endSession(ref),
        );
      },
    );
  }
}

class _TenantMismatchScreen extends StatelessWidget {
  const _TenantMismatchScreen({required this.onSignInAgain});

  final Future<void> Function() onSignInAgain;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.workspace_premium_outlined,
                    size: 44,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.tenantGateMismatchTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  l10n.tenantGateMismatchBody,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: () => unawaited(onSignInAgain()),
                  icon: const Icon(Icons.login_rounded),
                  label: Text(l10n.organizationSignInAgain),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _TenantInactiveScreen extends StatelessWidget {
  const _TenantInactiveScreen({this.workspaceName, required this.onSignOut});

  final String? workspaceName;
  final Future<void> Function() onSignOut;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  alignment: Alignment.center,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.errorContainer,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.lock_outlined,
                    size: 44,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  l10n.tenantGateInactiveTitle,
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  workspaceName == null
                      ? l10n.tenantGateInactiveBody
                      : l10n.tenantGateInactiveNamed(workspaceName!),
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 28),
                // No Retry: the workspace is closed and no amount of retrying
                // (automatic or manual) can reopen it. Only a deliberate sign
                // out, so a user with another account can move on.
                OutlinedButton.icon(
                  onPressed: () => unawaited(onSignOut()),
                  icon: const Icon(Icons.logout_rounded),
                  label: Text(l10n.tenantGateSignOut),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
