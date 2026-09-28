import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import 'theme/app_colors.dart';
import 'providers.dart';

/// Blocking screen for `maintenance: true` from `GET /app/config`.
///
/// This is the operator's kill-switch and the app had no way to honour it:
/// the endpoint was never called at all. Because the flag is server-authoritative
/// the app must not second-guess it with a local override — a local "skip"
/// would defeat the switch entirely, which is the opposite of its purpose.
///
/// It does offer Retry: maintenance is a temporary state and the operator may
/// lift it while the app is open, so the user needs a way to find out without
/// force-killing.
class MaintenanceScreen extends ConsumerWidget {
  const MaintenanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
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
                    color: AppColors.warnAmber.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.construction_rounded,
                    size: 44,
                    color: AppColors.warnAmber,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  "We'll be right back",
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'CivilCal is down for a short maintenance. Your account, '
                  'coins and progress are safe — nothing has been lost.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: () => ref.invalidate(appConfigProvider),
                  icon: const Icon(Icons.refresh_rounded),
                  label: const Text('Check again'),
                ),
                const SizedBox(height: 10),
                TextButton(
                  onPressed: () => _openSupport(context),
                  child: const Text('Contact support'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openSupport(BuildContext context) async {
    final messenger = ScaffoldMessenger.of(context);
    const url = 'mailto:support@bisaas.com';
    var ok = false;
    try {
      ok = await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
    } catch (_) {
      ok = false;
    }
    if (!ok) {
      messenger.showSnackBar(const SnackBar(content: Text('support@bisaas.com')));
    }
  }
}

/// Wraps the app and takes over the surface while maintenance is on.
///
/// Sits inside the force-update gate: an unsupported build cannot be fixed by
/// waiting, so that check is the more specific one and should win.
class MaintenanceGate extends ConsumerWidget {
  const MaintenanceGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final config = ref.watch(appConfigValueProvider);

    // A failed/unavailable config must not lock anyone out. Only an explicit
    // `maintenance: true` blocks.
    if (config?.maintenance == true) {
      return const MaintenanceScreen();
    }
    return child;
  }
}
