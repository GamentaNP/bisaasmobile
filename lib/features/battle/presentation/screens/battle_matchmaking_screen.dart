import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lottie/lottie.dart';
import 'package:vibration/vibration.dart';

import '../../../../app/localization/l10n.dart';
import '../../../../app/theme/app_colors.dart';
import '../controllers/battle_controller.dart';
import '../../../../l10n/app_localizations.dart';

/// Matchmaking screen with a mode picker and a 3-2-1 countdown on match found.
class BattleMatchmakingScreen extends ConsumerStatefulWidget {
  const BattleMatchmakingScreen({super.key});

  @override
  ConsumerState<BattleMatchmakingScreen> createState() => _BattleMatchmakingScreenState();
}

class _BattleMatchmakingScreenState extends ConsumerState<BattleMatchmakingScreen> {
  static const _modes = <String>['1v1', '2v2', '3v3'];

  int _countdown = 3;
  Timer? _countdownTimer;
  bool _ticking = false;
  String _mode = _modes.first;

  @override
  void initState() {
    super.initState();
    ref.listen(battleControllerProvider, (prev, next) {
      if (next.phase == BattlePhase.inProgress && prev?.phase != BattlePhase.inProgress) {
        _startCountdown();
      }
    });
  }

  void _start() {
    _countdownTimer?.cancel();
    ref.read(battleControllerProvider.notifier).findMatch(mode: _mode);
  }

  void _startCountdown() {
    _countdown = 3;
    _countdownTimer?.cancel();
    _ticking = false;
    // Timer ticks are not serialised. Awaiting a platform channel inside the
    // callback used to let several ticks overlap, skip numbers and navigate
    // twice. Decide the tick synchronously, vibrate fire-and-forget.
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) {
      if (_ticking) return;
      _ticking = true;
      try {
        if (!mounted) {
          t.cancel();
          return;
        }
        setState(() => _countdown--);
        unawaited(_vibrate());
        if (_countdown <= 0) {
          t.cancel();
          // go_router only: `pushReplacementNamed` throws here because
          // MaterialApp.router has no onGenerateRoute. The arena is the PARENT
          // route `/battle`; the sibling screens already use context.go.
          context.go('/battle');
        }
      } finally {
        _ticking = false;
      }
    });
  }

  Future<void> _vibrate() async {
    try {
      if (await Vibration.hasVibrator() == true) {
        await Vibration.vibrate(duration: 30);
      }
    } catch (_) {
      // A missing vibrator is not a matchmaking failure.
    }
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final state = ref.watch(battleControllerProvider);
    if (state.phase == BattlePhase.countdown || _countdownTimer?.isActive == true) {
      return Scaffold(
        body: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                l10n.battleMatchStartingIn(_countdown),
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Semantics(
                label: l10n.battleMatchStartingIn(_countdown),
                child: Text(
                  '$_countdown',
                  style: const TextStyle(
                    fontSize: 72,
                    fontWeight: FontWeight.bold,
                    color: AppColors.brand,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              OutlinedButton.icon(
                onPressed: () {
                  _countdownTimer?.cancel();
                  ref.read(battleControllerProvider.notifier).reset();
                  context.go('/home');
                },
                icon: const Icon(Icons.close_rounded),
                label: Text(l10n.commonCancel),
              ),
            ],
          ),
        ),
      );
    }

    final busy = state.phase == BattlePhase.searching ||
        state.phase == BattlePhase.fetchingToken ||
        state.phase == BattlePhase.connectingFirebase;
    final failed = state.phase == BattlePhase.error;

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.battleFindMatch),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          tooltip: l10n.commonClose,
          onPressed: () {
            _countdownTimer?.cancel();
            ref.read(battleControllerProvider.notifier).reset();
            context.go('/home');
          },
        ),
      ),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                l10n.battleChooseMode,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium,
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                children: [
                  for (final mode in _modes)
                    ChoiceChip(
                      label: Text(_modeLabel(mode, l10n)),
                      selected: _mode == mode,
                      // Selecting a different queue while a search is in
                      // flight would leave the roster inconsistent.
                      onSelected: busy || failed
                          ? null
                          : (selected) {
                              if (selected) setState(() => _mode = mode);
                            },
                    ),
                ],
              ),
              const SizedBox(height: 24),
              if (busy)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 140,
                      height: 140,
                      child: Lottie.asset(
                        'assets/animations/loading_engineering.json',
                        repeat: true,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _phaseText(state.phase),
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
                    ),
                  ],
                )
              else if (failed)
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.error_outline_rounded, size: 48, color: AppColors.wrongRed),
                    const SizedBox(height: 12),
                    Text(
                      state.error ?? l10n.errRequestFailed,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.wrongRed),
                    ),
                    const SizedBox(height: 16),
                    FilledButton.icon(
                      onPressed: _start,
                      icon: const Icon(Icons.replay_rounded),
                      label: Text(l10n.retry),
                    ),
                  ],
                )
              else
                FilledButton.icon(
                  onPressed: _start,
                  icon: const Icon(Icons.search_rounded),
                  label: Text(l10n.battleFindMatch),
                  style: FilledButton.styleFrom(minimumSize: const Size.fromHeight(52)),
                ),
              const SizedBox(height: 8),
              OutlinedButton.icon(
                onPressed: () {
                  ref.read(battleControllerProvider.notifier).reset();
                  context.go('/home');
                },
                icon: const Icon(Icons.arrow_back_rounded),
                label: Text(l10n.commonGoBack),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _modeLabel(String mode, AppLocalizations l10n) => switch (mode) {
        '2v2' => l10n.battleMode2v2,
        '3v3' => l10n.battleMode3v3,
        _ => l10n.battleMode1v1,
      };

  String _phaseText(BattlePhase p) => switch (p) {
        BattlePhase.fetchingToken => appL10n().battlePhaseSecuring,
        BattlePhase.connectingFirebase => appL10n().battlePhaseConnecting,
        BattlePhase.searching => appL10n().battlePhaseSearching,
        BattlePhase.error => appL10n().battlePhaseMatchFailed,
        _ => appL10n().battlePhasePreparing,
      };
}
