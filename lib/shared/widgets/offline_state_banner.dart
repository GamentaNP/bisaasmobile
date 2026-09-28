import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../app/providers.dart';
import '../../app/theme/app_colors.dart';

/// App-wide connectivity banner. Quiet when online; shows an amber strip when
/// the API is genuinely unreachable, and a brief green "back online / syncing"
/// confirmation when it returns.
///
/// The state comes from `apiReachableProvider`, which learns from real request
/// outcomes — **not** from `connectivity_plus`. The radio reporting a network
/// is a different question from "can we reach `/api/v1`", and the two disagree
/// in both directions: a captive portal or a blocked API path reports
/// "connected" while every request fails, which previously produced a confident
/// "You're offline" strip to a user whose API calls were in fact succeeding.
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
    ref.listen(apiReachableProvider, (p, n) => _onOnlineChanged(p?.value, n.value));
    final reachable = ref.watch(apiReachableProvider).value;

    final offline = reachable == false;
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
                          ? "Can't reach our servers — progress syncs when the connection is back"
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
