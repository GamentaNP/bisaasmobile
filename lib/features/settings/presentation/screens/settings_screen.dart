/// Settings — app language, biometric app lock, and session logout.
// ignore_for_file: simple_directive_paths
library;

import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../app/localization/app_languages.dart';
import '../../../../app/localization/locale_controller.dart';
import '../../../../app/providers.dart';
import '../../../../app/theme/script_fonts.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/security/biometric_auth.dart';
import '../../../../features/auth/presentation/controllers/auth_controller.dart';
import '../../../../features/profile/presentation/controllers/profile_skills_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
  bool _deleting = false;

  Future<void> _logout() async {
    // AuthRepositoryImpl.logout clears the token (best-effort server call);
    // the app-shell auth listener unregisters the FCM device token.
    try {
      await ref.read(authControllerProvider.notifier).logout();
    } catch (e) {
      AppLogger.w('Logout failed: $e');
    }
    if (!mounted) return;
    context.go('/login');
  }

  /// Store-policy account deletion: `DELETE /api/v1/account` (server-side
  /// erasure), then clear local token + session. Confirmation requires
  /// typing DELETE to prevent accidental taps.
  Future<void> _deleteAccount() async {
    final confirmed = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => const _DeleteAccountDialog(),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _deleting = true);
    try {
      await ref.read(dioProvider).delete<dynamic>('/account');
    } on DioException catch (e) {
      if (!mounted) return;
      setState(() => _deleting = false);
      final status = e.response?.statusCode;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            status == 403
                ? 'Subscription must be cancelled before deletion'
                : 'Could not delete account — please try again',
          ),
        ),
      );
      return;
    } catch (_) {
      if (!mounted) return;
      setState(() => _deleting = false);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Could not delete account — please try again')),
      );
      return;
    }
    if (!mounted) return;
    setState(() => _deleting = false);
    // Server revoked the PAT with the account; clear locally regardless.
    try {
      await ref.read(authControllerProvider.notifier).logout();
    } catch (e) {
      AppLogger.w('Post-delete logout failed: $e');
    }
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Your account has been deleted')),
    );
    context.go('/login');
  }

  Future<void> _toggleAppLock(bool value) async {
    if (value) {
      final can = await BiometricAuth(LocalAuthentication()).canCheck;
      if (!can) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('No biometrics enrolled on this device'),
          ),
        );
        return;
      }
    }
    await ref.read(appLockProvider).setEnabled(value);
    if (mounted) setState(() {});
  }

  Future<void> _pickLocale(Locale? current) async {
    final selected = await showModalBottomSheet<Locale?>(
      context: context,
      showDragHandle: true,
        builder: (context) => SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: _pickerRows(context, current),
          ),
        ),
    );
      if (selected == null && current == null) return;
      await ref.read(localeProvider.notifier).setLocale(selected);
      // Persist server-side too. `PATCH /me/locale` exists and validates
      // against config('app.supported_locales'); without this the preference
      // lived only in local prefs, so it was lost on reinstall and invisible to
      // anything server-side. Best-effort: a failed sync must not undo the
      // local choice the user just made.
      final code = selected?.languageCode;
      if (code != null) {
        try {
          await ref.read(profileRemoteDataSourceProvider).updateLocale(code);
        } catch (_) {
          if (!mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Language saved on this device only — could not reach the server.'),
            ),
          );
        }
      }
    }

  /// Language names come from the registry in their own script, so a user who
  /// cannot read English can still find their language. The previous list was
  /// four hardcoded strings (and two of those labels were mojibake in source).
  static List<Widget> _pickerRows(BuildContext context, Locale? current) {
    return [
      ListTile(
        title: const Text('System default'),
        trailing: current == null ? const Icon(Icons.check_rounded) : null,
        onTap: () => Navigator.of(context).pop<Locale?>(null),
      ),
      for (final lang in AppLanguages.all)
        ListTile(
          title: Text(
            lang.displayLabel,
            // The label is being read in that language, so it has to render in
            // that language's font. Resolving from the text rather than the
            // active locale is what makes a language nobody enumerated work.
            style: ScriptFonts.forText(
              Theme.of(context).textTheme.bodyLarge!,
              lang.displayLabel,
            ),
          ),
          trailing: current?.languageCode == lang.code
              ? const Icon(Icons.check_rounded)
              : null,
          onTap: () => Navigator.of(context).pop<Locale?>(Locale(lang.code)),
        ),
    ];
  }

  String _localeLabel(Locale? locale) {
    if (locale == null) return 'System default';
    final lang = AppLanguages.byCode(locale.languageCode);
    if (lang == null) return locale.languageCode;
    return lang.displayLabel;
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);
    final lock = ref.watch(appLockProvider);
    return Scaffold(
      appBar: AppBar(title: const Text('Settings')),
      body: ListView(
        children: [
          const _SectionHeader('Language'),
          ListTile(
            leading: const Icon(Icons.language_rounded),
            title: const Text('App language'),
            subtitle: Text(_localeLabel(locale)),
            trailing: const Icon(Icons.arrow_drop_down_rounded),
            onTap: () => unawaited(_pickLocale(locale)),
          ),
          const Divider(height: 1),
          const _SectionHeader('Security'),
          SwitchListTile(
            secondary: const Icon(Icons.fingerprint_rounded),
            title: const Text('Biometric app lock'),
            subtitle: const Text('Require biometrics after 30s in background'),
            value: lock.enabled,
            onChanged: (v) => unawaited(_toggleAppLock(v)),
          ),
          const Divider(height: 1),
          const _SectionHeader('Privacy'),
          ListTile(
            leading: const Icon(Icons.privacy_tip_outlined),
            title: const Text('Privacy choices'),
            subtitle: const Text('Analytics, functional and marketing consent'),
            trailing: const Icon(Icons.arrow_forward_ios_rounded, size: 16),
            onTap: () => context.push('/privacy'),
          ),
          const Divider(height: 1),
          const _SectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Log out'),
            onTap: () => unawaited(_logout()),
          ),
          ListTile(
            leading: _deleting
                ? const SizedBox(
                    width: 24,
                    height: 24,
                    child: Padding(
                      padding: EdgeInsets.all(2),
                      child: CircularProgressIndicator(strokeWidth: 2.5),
                    ),
                  )
                : const Icon(Icons.delete_forever_rounded,
                    color: Colors.redAccent),
            title: const Text('Delete account'),
            subtitle: const Text(
              'Permanently erase your account, attempts and purchases',
            ),
            enabled: !_deleting,
            onTap: () => unawaited(_deleteAccount()),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

/// Type-to-confirm dialog for irreversible account deletion.
class _DeleteAccountDialog extends StatefulWidget {
  const _DeleteAccountDialog();

  @override
  State<_DeleteAccountDialog> createState() => _DeleteAccountDialogState();
}

class _DeleteAccountDialogState extends State<_DeleteAccountDialog> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canConfirm = _controller.text.trim().toUpperCase() == 'DELETE';
    return AlertDialog(
      title: const Text('Delete account?'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'This permanently deletes your account, quiz history, coins and '
            'purchases. This cannot be undone.',
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: "Type 'DELETE' to confirm",
              border: OutlineInputBorder(),
            ),
            onChanged: (_) => setState(() {}),
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(false),
          child: const Text('Cancel'),
        ),
        FilledButton(
          style: FilledButton.styleFrom(backgroundColor: Colors.redAccent),
          onPressed: canConfirm ? () => Navigator.of(context).pop(true) : null,
          child: const Text('Delete'),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader(this.title);

  final String title;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title,
        style: Theme.of(context)
            .textTheme
            .labelMedium
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
