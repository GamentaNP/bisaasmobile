/// Settings — app language, biometric app lock, and session logout.
// ignore_for_file: simple_directive_paths
library;

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:local_auth/local_auth.dart';

import '../../../../app/localization/locale_controller.dart';
import '../../../../app/providers.dart';
import '../../../../core/logging/app_logger.dart';
import '../../../../core/security/biometric_auth.dart';
import '../../../../features/auth/presentation/controllers/auth_controller.dart';

class SettingsScreen extends ConsumerStatefulWidget {
  const SettingsScreen({super.key});
  @override
  ConsumerState<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends ConsumerState<SettingsScreen> {
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
          children: [
            for (final option in _localeOptions)
              ListTile(
                title: Text(option.label),
                trailing:
                    option.locale?.languageCode == current?.languageCode ||
                            (option.locale == null && current == null)
                        ? const Icon(Icons.check_rounded)
                        : null,
                onTap: () => Navigator.of(context).pop(option.locale),
              ),
          ],
        ),
      ),
    );
    if (selected == null && current == null) return;
    await ref.read(localeProvider.notifier).setLocale(selected);
  }

  static const _localeOptions = <_LocaleOption>[
    _LocaleOption(null, 'System default'),
    _LocaleOption(Locale('en'), 'English'),
    _LocaleOption(Locale('ne'), 'नेपाली'),
    _LocaleOption(Locale('hi'), 'हिन्दी'),
  ];

  String _localeLabel(Locale? locale) {
    for (final option in _localeOptions) {
      if (option.locale?.languageCode == locale?.languageCode) return option.label;
    }
    return locale?.languageCode ?? 'System default';
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
          const _SectionHeader('Account'),
          ListTile(
            leading: const Icon(Icons.logout_rounded),
            title: const Text('Log out'),
            onTap: () => unawaited(_logout()),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}

class _LocaleOption {
  const _LocaleOption(this.locale, this.label);
  final Locale? locale;
  final String label;
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
