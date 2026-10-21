import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'consent_controller.dart';
import 'consent_state.dart';
import '../../l10n/app_localizations.dart';

/// The consent sheet.
///
/// Shown once, before the user has made a choice. Every non-essential category
/// starts **off**: a pre-ticked marketing box is the single most common way a
/// consent dialog becomes a dark pattern, and a user who has to untick things to
/// protect themselves has been asked for the wrong thing.
///
/// `necessary` is shown but not switchable. It is labelled as required and the
/// reason is stated, because a checkbox the user cannot touch with no
/// explanation reads as a broken control.
class ConsentSheet extends ConsumerStatefulWidget {
  const ConsentSheet({super.key});

  /// Returns true when the user made a choice, so the caller knows whether to
  /// keep waiting.
  static Future<bool> show(BuildContext context) async {
    final result = await showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      isDismissible: false,
      enableDrag: false,
      builder: (_) => const ConsentSheet(),
    );
    return result ?? false;
  }

  @override
  ConsumerState<ConsentSheet> createState() => _ConsentSheetState();
}

class _ConsentSheetState extends ConsumerState<ConsentSheet> {
  bool _functional = false;
  bool _analytics = false;
  bool _marketing = false;
  bool _saving = false;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        // The disclosure text scrolls; the two buttons do not. A consent
        // sheet whose primary action can sit below the fold is a sheet that
        // strands the user — and the longer, more accurate the disclosure
        // has to be, the more likely that is. Pinning the actions means
        // they are reachable at any font scale and on any screen height.
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(l10n.consentTitle, style: theme.textTheme.headlineSmall),
                    const SizedBox(height: 8),
                    Text(
                      // The wording has to survive a review. The previous
                      // copy claimed the app collects nothing beyond what it
                      // needs to work, which was not true: it registers a
                      // push token, reports crashes and sends a
                      // device-integrity signal, all before any choice is
                      // made. Guideline 5.1.1 and the Play Data Safety form
                      // both require the disclosure to name what is actually
                      // transmitted, so this paragraph lists it.
                      l10n.consentIntro,
                      style: theme.textTheme.bodyMedium,
                    ),
                    const SizedBox(height: 16),
                    _Row(
                      title: l10n.consentNecessary,
                      subtitle: l10n.consentNecessaryBody,
                      value: true,
                      enabled: false,
                      onChanged: null,
                    ),
                    _Row(
                      title: l10n.consentFunctional,
                      subtitle: l10n.consentFunctionalBody,
                      value: _functional,
                      onChanged: (v) => setState(() => _functional = v),
                    ),
                    _Row(
                      title: l10n.consentAnalytics,
                      subtitle: l10n.consentAnalyticsBody,
                      value: _analytics,
                      onChanged: (v) => setState(() => _analytics = v),
                    ),
                    _Row(
                      title: l10n.consentMarketing,
                      subtitle: l10n.consentMarketingBody,
                      value: _marketing,
                      onChanged: (v) => setState(() => _marketing = v),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: _saving ? null : _save,
                child: _saving
                    ? const SizedBox(
                        height: 18,
                        width: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Text(l10n.consentSaveChoices),
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: _saving ? null : _saveEssentialOnly,
                child: Text(l10n.consentNecessaryOnly),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    await ref.read(consentProvider.notifier).decide(
          functional: _functional,
          analytics: _analytics,
          marketing: _marketing,
        );
    if (mounted) Navigator.of(context).pop(true);
  }

  Future<void> _saveEssentialOnly() async {
    setState(() => _saving = true);
    await ref.read(consentProvider.notifier).decide(
          functional: false,
          analytics: false,
          marketing: false,
        );
    if (mounted) Navigator.of(context).pop(true);
  }
}

class _Row extends StatelessWidget {
  const _Row({
    required this.title,
    required this.subtitle,
    required this.value,
    this.onChanged,
    this.enabled = true,
  });

  final String title;
  final String subtitle;
  final bool value;
  final ValueChanged<bool>? onChanged;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final on = onChanged != null;
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      value: value,
      onChanged: on ? onChanged : null,
      title: Text(
        title,
        style: theme.textTheme.titleMedium?.copyWith(
          color: on ? null : theme.colorScheme.onSurfaceVariant,
        ),
      ),
      subtitle: Text(subtitle, style: theme.textTheme.bodySmall),
    );
  }
}

/// Full settings screen for changing or revoking consent.
class PrivacySettingsScreen extends ConsumerWidget {
  const PrivacySettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = AppLocalizations.of(context)!;
    final consent = ref.watch(consentProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.privacyMenu)),
      body: consent.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(l10n.consentLoadError)),
        data: (state) => ListView(
          children: [
            ListTile(
              title: Text(l10n.consentNecessary),
              subtitle: Text(l10n.consentNecessaryAlwaysOn),
              trailing: const Icon(Icons.lock_outline),
              enabled: false,
            ),
            for (final entry in const [
              (ConsentCategory.functional, 'Functional', 'Remembered settings'),
              (ConsentCategory.analytics, 'Analytics', 'Usage events, tied to '
                  'a device identifier'),
              (ConsentCategory.marketing, 'Marketing', 'Offers and promotions'),
            ])
              SwitchListTile(
                title: Text(entry.$2),
                subtitle: Text(entry.$3),
                value: state.granted(entry.$1),
                onChanged: (v) => v
                    ? _grant(context, ref, state, entry.$1)
                    : ref.read(consentProvider.notifier).revoke(entry.$1),
              ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.storage_outlined),
              title: Text(l10n.consentDataStored),
              subtitle: Text(l10n.consentDataStoredSubtitle),
              trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
              onTap: () => context.push('/privacy/data'),
            ),
            const Divider(),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                l10n.consentFootnote,
                style: theme.textTheme.bodySmall,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _grant(
    BuildContext context,
    WidgetRef ref,
    ConsentState state,
    ConsentCategory category,
  ) async {
    // Reuses `decide` with the other categories untouched, so granting one
    // choice cannot silently reset the others. `decided` is already true here —
    // the user reached this screen having made a choice once.
    bool keep(ConsentCategory other, bool value) => switch (other) {
          _ when other == category => true,
          _ => value,
        };
    await ref.read(consentProvider.notifier).decide(
          functional: keep(ConsentCategory.functional, state.functional),
          analytics: keep(ConsentCategory.analytics, state.analytics),
          marketing: keep(ConsentCategory.marketing, state.marketing),
        );
  }
}
