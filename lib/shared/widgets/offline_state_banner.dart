import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';

/// App-wide connectivity banner. Quiet when online; shows an amber "offline"
/// strip when the device loses network, and a brief green "back online /
/// syncing" confirmation when connectivity returns. Place near the top of a
/// shell body (below the app bar) — it animates its own height so it can stay
/// mounted.
class OfflineStateBanner extends ConsumerStatefulWidget {
  const OfflineStateBanner({super.key});

  @override
  ConsumerState<OfflineStateBanner> createState() => _OfflineStateBannerState();
}

class _OfflineStateBannerState extends ConsumerState<OfflineStateBanner> {
  bool _showSynced = false;
  Timer? _syncedTimer;

  @override
  void dispose() {
    _syncedTimer?.cancel();
    super.dispose();
  }

  void _onOnlineChanged(bool? prev, bool? next) {
    if (next == null) return;
    // Transition offline -> online: flash a "syncing" confirmation.
    if (prev == false && next) {
      setState(() => _showSynced = true);
      _syncedTimer?.cancel();
      _syncedTimer = Timer(const Duration(seconds: 3), () {
        if (mounted) setState(() => _showSynced = false);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    ref.listen(onlineStatusProvider, (p, n) => _onOnlineChanged(p?.value, n.value));
    final online = ref.watch(onlineStatusProvider).value;

    final offline = online == false;
    final visible = offline || _showSynced;

    return AnimatedSize(
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOut,
      alignment: Alignment.topCenter,
      child: !visible
          ? const SizedBox(width: double.infinity, height: 0)
          : Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              color: offline
                  ? AppColors.streakOrange.withValues(alpha: 0.16)
                  : AppColors.correctGreen.withValues(alpha: 0.16),
              child: Row(
                children: [
                  Icon(
                    offline ? Icons.wifi_off_rounded : Icons.cloud_done_rounded,
                    size: 16,
                    color: offline
                        ? AppColors.streakOrange
                        : AppColors.correctGreen,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      offline
                          ? "You're offline — progress will sync when you reconnect"
                          : 'Back online — syncing your queued activity',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: offline
                                ? AppColors.streakOrange
                                : AppColors.correctGreen,
                            fontWeight: FontWeight.w600,
                          ),
                    ),
                  ),
                ],
              ),
            ),
    );
  }
}
