// ignore_for_file: return_without_value, unawaited_futures

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:lottie/lottie.dart';
import 'package:vibration/vibration.dart';

import '../../../../app/theme/app_colors.dart';
import '../controllers/battle_controller.dart';

/// Matchmaking screen with 3-2-1 countdown on opponent found.
class BattleMatchmakingScreen extends ConsumerStatefulWidget {
  const BattleMatchmakingScreen({super.key});

  @override
  ConsumerState<BattleMatchmakingScreen> createState() => _BattleMatchmakingScreenState();
}

class _BattleMatchmakingScreenState extends ConsumerState<BattleMatchmakingScreen> {
  int _countdown = 3;
  Timer? _countdownTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(battleControllerProvider.notifier).fetchToken().then((_) {
        if (!mounted) return;
        ref.read(battleControllerProvider.notifier).findMatch();
      });
    });
    ref.listen(battleControllerProvider, (prev, next) {
      if (next.phase == BattlePhase.inProgress && prev?.phase != BattlePhase.inProgress) {
        _startCountdown();
      }
    });
  }

  void _startCountdown() {
    _countdown = 3;
    _countdownTimer?.cancel();
    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (t) async {
      try {
        if (await Vibration.hasVibrator() == true) {
          Vibration.vibrate(duration: 30);
        }
      } catch (_) {}
      if (!mounted) return;
      setState(() => _countdown--);
      if (_countdown <= 0) {
        t.cancel();
        if (mounted) Navigator.of(context).pushReplacementNamed('/battle/arena');
      }
    });
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(battleControllerProvider);
    if (state.phase == BattlePhase.countdown || _countdownTimer?.isActive == true) {
      return Scaffold(body: Center(child: Text('$_countdown', style: const TextStyle(fontSize: 96, fontWeight: FontWeight.bold, color: AppColors.brand))));
    }
    return Scaffold(
      appBar: AppBar(
        title: const Text('Find a Match'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () {
            ref.read(battleControllerProvider.notifier).reset();
            Navigator.of(context).pop();
          },
        ),
      ),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SizedBox(
                width: 160,
                height: 160,
                child: Lottie.asset('assets/animations/loading_engineering.json', repeat: true),
              ),
              const SizedBox(height: 24),
              Text(_phaseText(state.phase), style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600)),
              const SizedBox(height: 8),
              if (state.error != null)
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(state.error!, textAlign: TextAlign.center, style: const TextStyle(color: AppColors.wrongRed)),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _phaseText(BattlePhase p) => switch (p) {
        BattlePhase.fetchingToken => 'Securing connection…',
        BattlePhase.connectingFirebase => 'Connecting to realtime…',
        BattlePhase.searching => 'Searching for opponent…',
        BattlePhase.error => 'Match failed',
        _ => 'Preparing battle…',
      };
}
