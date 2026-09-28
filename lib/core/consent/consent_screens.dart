import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import 'consent_controller.dart';
import 'consent_state.dart';

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
    final theme = Theme.of(context);

    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(
          left: 24,
          right: 24,
          top: 24,
          bottom: 24 + MediaQuery.of(context).viewInsets.bottom,
        ),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Privacy choices', style: theme.textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'We collect nothing beyond what the app needs to work unless you '
                'allow it. You can change this at any time in Settings → Privacy.',
                style: theme.textTheme.bodyMedium,
              ),
              const SizedBox(height: 16),
              _Row(
                title: 'Necessary',
                subtitle: 'Sign-in, your saved work, and crash reports. '
                    'Required for the app to work.',
                value: true,
                enabled: false,
                onChanged: null,
              ),
              _Row(
                title: 'Functional',
                subtitle: 'Remember settings such as your language and filters.',
                value: _functional,
                onChanged: (v) => setState(() => _functional = v),
              ),
              _Row(
                title: 'Analytics',
                subtitle: 'Anonymous usage events that tell us which features '
                    'are useful. No question content is ever included.',
                value: _analytics,
                onChanged: (v) => setState(() => _analytics = v),
              ),
              _Row(
                title: 'Marketing',
                subtitle: 'Offers and promotions. Off unless you ask for it.',
                value: _marketing,
                onChanged: (v) => setState(() => _marketing = v),
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
                      : const Text('Save choices'),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: _saving ? null : _saveEssentialOnly,
                  child: const Text('Continue with necessary only'),
                ),
              ),
            ],
          ),
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
    final consent = ref.watch(consentProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Privacy')),
      body: consent.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => const Center(child: Text('Could not load your choices')),
        data: (state) => ListView(
          children: [
            ListTile(
              title: const Text('Necessary'),
              subtitle: const Text('Always on. Required for the app to work.'),
              trailing: const Icon(Icons.lock_outline),
              enabled: false,
            ),
            for (final entry in const [
              (ConsentCategory.functional, 'Functional', 'Remembered settings'),
              (ConsentCategory.analytics, 'Analytics', 'Anonymous usage events'),
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
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Turning off a category stops that collection from that moment. '
                'It does not delete data already collected — for that, contact '
                'privacy@bisaas.com.',
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
