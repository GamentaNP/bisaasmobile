import 'package:flutter/material.dart';

import '../../core/security/app_lock.dart';
import '../../l10n/app_localizations.dart';

/// Full-screen biometric gate rendered above the app whenever [AppLock] is
/// locked (backgrounded past the grace period with lock enabled in settings).
class AppLockOverlay extends StatelessWidget {
  const AppLockOverlay({super.key, required this.lock, required this.child});

  final AppLock lock;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: lock,
      builder: (context, _) {
        if (!lock.isLocked) return child;
        return Stack(
          children: [
            ExcludeSemantics(child: child),
            Positioned.fill(child: _LockScreen(lock: lock)),
          ],
        );
      },
    );
  }
}

class _LockScreen extends StatelessWidget {
  const _LockScreen({required this.lock});

  final AppLock lock;

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final theme = Theme.of(context);
    return ColoredBox(
      color: theme.colorScheme.surface,
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.lock_rounded, size: 56, color: theme.colorScheme.primary),
            const SizedBox(height: 16),
            Text(l10n.appLocked, style: theme.textTheme.titleMedium),
            const SizedBox(height: 24),
            FilledButton.icon(
              onPressed: () => lock.challenge(reason: l10n.unlockCivilCal),
              icon: const Icon(Icons.fingerprint_rounded),
              label: Text(l10n.unlock),
            ),
          ],
        ),
      ),
    );
  }
}
