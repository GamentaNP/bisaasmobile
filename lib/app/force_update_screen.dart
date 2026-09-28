import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

import '../core/network/app_update_gate.dart';
import 'theme/app_colors.dart';

/// Blocking screen shown when the server refuses this build (HTTP 426).
///
/// Deliberately has no Retry and no dismiss: the server will refuse every
/// request from this build, so retrying can never succeed. The only way forward
/// is installing a newer version, which is why this is a gate rather than an
/// error banner.
class ForceUpdateScreen extends StatelessWidget {
  const ForceUpdateScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final gate = AppUpdateGate.instance;
    final theme = Theme.of(context);
    final url = StoreLinks.forPlatform(
      platform: gate.platform,
      fallback: defaultTargetPlatform,
    );

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
                    color: AppColors.brand.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.system_update_rounded,
                    size: 44,
                    color: AppColors.brand,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Update required',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  gate.minVersion == null
                      ? 'This version of CivilCal is no longer supported. '
                          'Please update to the latest version to continue.'
                      : 'This version of CivilCal is no longer supported. '
                          'Please update to version ${gate.minVersion} or later '
                          'to continue.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
                ),
                if (gate.currentVersion != null) ...[
                  const SizedBox(height: 8),
                  Text(
                    'Your version: ${gate.currentVersion}',
                    textAlign: TextAlign.center,
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                    ),
                  ),
                ],
                const SizedBox(height: 28),
                FilledButton.icon(
                  onPressed: () => unawaited(_openStore(context, url)),
                  icon: const Icon(Icons.download_rounded),
                  label: const Text('Update now'),
                ),
                const SizedBox(height: 10),
                Text(
                  'Your account and progress are safe — nothing is lost by updating.',
                  textAlign: TextAlign.center,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Future<void> _openStore(BuildContext context, String url) async {
    final messenger = ScaffoldMessenger.of(context);
    var launched = false;
    try {
      launched = await launchUrl(
        Uri.parse(url),
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      launched = false;
    }
    if (!launched) {
      // Don't leave the tap looking broken if no browser is available.
      messenger.showSnackBar(
        SnackBar(content: Text('Could not open the store. Visit $url')),
      );
    }
  }
}

/// Wraps the app and takes over the whole surface once [AppUpdateGate] latches.
class ForceUpdateGate extends StatelessWidget {
  const ForceUpdateGate({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: AppUpdateGate.instance,
      builder: (context, _) {
        if (AppUpdateGate.instance.isBlocked) {
          return const ForceUpdateScreen();
        }
        return child;
      },
    );
  }
}
