/// The organization switcher — only truthful when a list actually exists.
///
/// The list comes from `GET /api/v1/me/tenants`, the server's own answer to
/// "which organizations may this credential assert". Reachable from Settings
/// only when `OrganizationContext.switcherAvailable` is true. A deep link that
/// arrives with no rows still lands here; in that case the screen says there
/// is nothing to switch rather than rendering an empty list or a guessed
/// organization.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../l10n/app_localizations.dart';
import '../../../../core/security/tenant_store.dart';
import '../../domain/entities/organization.dart';
import '../controllers/organization_controller.dart';

class OrganizationSwitcherScreen extends ConsumerWidget {
  const OrganizationSwitcherScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final async = ref.watch(organizationControllerProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.organizationSwitchTitle)),
      body: async.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stackTrace) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(l10n.errRequestFailed, textAlign: TextAlign.center),
                const SizedBox(height: 16),
                FilledButton(
                  onPressed: () {
                    // The list is cached separately; a retry has to re-ask the
                    // server, not just rebuild from the cached failure.
                    ref.invalidate(organizationMembershipsProvider);
                    ref.invalidate(organizationControllerProvider);
                  },
                  child: Text(l10n.retry),
                ),
              ],
            ),
          ),
        ),
        data: (organizationContext) =>
            _OrganizationBody(context: organizationContext),
      ),
    );
  }
}

class _OrganizationBody extends ConsumerWidget {
  const _OrganizationBody({required this.context});

  final OrganizationContext context;

  Future<void> _signInAgain(BuildContext screenContext, WidgetRef ref) async {
    await ref.read(organizationControllerProvider.notifier).signInAgain();
    if (screenContext.mounted) screenContext.go('/login');
  }

  @override
  Widget build(BuildContext screenContext, WidgetRef ref) {
    final l10n = AppLocalizations.of(screenContext)!;
    final organizations = context.organizations;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (context.failure != null)
          Card(
            color: Theme.of(screenContext).colorScheme.errorContainer,
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.failure == TenantFailure.mismatch
                        ? l10n.organizationMismatchTitle
                        : l10n.organizationInactiveTitle,
                    style: Theme.of(screenContext).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    context.failure == TenantFailure.mismatch
                        ? l10n.organizationMismatchBody
                        : l10n.organizationInactiveBody,
                  ),
                  if (context.requiresReauthentication) ...[
                    const SizedBox(height: 12),
                    FilledButton(
                      onPressed: () => _signInAgain(screenContext, ref),
                      child: Text(l10n.organizationSignInAgain),
                    ),
                  ],
                ],
              ),
            ),
          ),
        if (context.failure != null) const SizedBox(height: 16),
        Text(
          l10n.organizationCurrent,
          style: Theme.of(screenContext).textTheme.labelLarge,
        ),
        const SizedBox(height: 4),
        Text(
          context.selected?.name ?? l10n.organizationNone,
          style: Theme.of(screenContext).textTheme.titleLarge,
        ),
        const SizedBox(height: 8),
        Text(l10n.organizationSwitchSubtitle),
        const SizedBox(height: 16),
        if (organizations == null || organizations.isEmpty)
          Text(l10n.organizationUnavailable)
        else
          ...organizations.map(
            (organization) => _OrganizationTile(
              organization: organization,
              selected: organization.id == context.selectedId,
            ),
          ),
      ],
    );
  }
}

class _OrganizationTile extends ConsumerWidget {
  const _OrganizationTile({
    required this.organization,
    required this.selected,
  });

  final Organization organization;
  final bool selected;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    return Card(
      child: ListTile(
        // An inactive organization is shown, not hidden: a user whose
        // workspace was closed needs to see why it cannot be used.
        enabled: organization.isActive && !selected,
        leading: Icon(
          organization.isActive ? Icons.business_outlined : Icons.block,
        ),
        title: Text(organization.name),
        subtitle: organization.slug == null ? null : Text(organization.slug!),
        trailing: selected ? const Icon(Icons.check) : null,
        onTap: organization.isActive && !selected
            ? () async {
                await ref
                    .read(organizationControllerProvider.notifier)
                    .use(organization.id);
                if (!context.mounted) return;
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      l10n.organizationNowUsing(organization.name),
                    ),
                  ),
                );
              }
            : null,
      ),
    );
  }
}
