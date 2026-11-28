/// The user-visible entry point for server-verified rewarded ads.
///
/// It renders nothing unless three gates agree: the operator's live switches
/// (`adEntryEnabledProvider`), a usable SDK (`adRewardReadyProvider`), and a
/// build that actually has ad IDs. The button never credits coins itself — the
/// server does that only after a valid claim.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';

import '../../core/ads/ad_reward_result.dart';
import '../../core/ads/ads_providers.dart';
import '../../app/theme/app_colors.dart';
import '../../l10n/app_localizations.dart';

class WatchToEarnButton extends ConsumerStatefulWidget {
  const WatchToEarnButton({super.key});

  @override
  ConsumerState<WatchToEarnButton> createState() => _WatchToEarnButtonState();
}

class _WatchToEarnButtonState extends ConsumerState<WatchToEarnButton> {
  bool _busy = false;
  String? _claimKey;

  Future<void> _watch() async {
    if (_busy) return;
    // One logical claim: a retry of a dropped claim must reuse this key so
    // the server replays the original ledger entry instead of crediting twice.
    _claimKey ??= const Uuid().v4();
    final key = _claimKey!;
    setState(() => _busy = true);

    final result = await ref.read(adRewardFlowProvider).run(
          claimIdempotencyKey: key,
        );
    if (!mounted) return;

    final l10n = AppLocalizations.of(context)!;
    final granted = result.rewarded;
    if (granted) _claimKey = null;

    final message = switch (result.outcome) {
      AdRewardOutcome.rewarded => l10n.adsRewardGranted,
      AdRewardOutcome.unavailable => l10n.adsRewardUnavailable,
      _ => l10n.adsRewardFailed,
    };
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: granted ? AppColors.correctGreen : AppColors.warnAmber,
      ),
    );
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    if (!ref.watch(adEntryEnabledProvider)) return const SizedBox.shrink();
    final ready = ref.watch(adRewardReadyProvider);
    // While the SDK initialises, or when it is unavailable, the entry point
    // simply does not exist. No disabled button, no error copy.
    if (!ready.hasValue || ready.value != true) return const SizedBox.shrink();

    final l10n = AppLocalizations.of(context)!;
    return OutlinedButton.icon(
      onPressed: _busy ? null : _watch,
      icon: _busy
          ? const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.play_circle_outline_rounded),
      label: Text(l10n.adsWatchToEarn),
    );
  }
}
