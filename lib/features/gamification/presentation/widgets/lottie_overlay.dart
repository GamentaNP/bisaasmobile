// ignore_for_file: unawaited_futures, prefer_int_literals

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:vibration/vibration.dart';

import '../../../../app/theme/app_colors.dart';

/// Centered full-screen Lottie overlay. Auto-dismisses after
/// [autoDismiss] (default 2.5s). Triggers heavy haptic on appear.
class LottieOverlay extends StatefulWidget {
  const LottieOverlay({
    required this.asset,
    required this.title,
    this.subtitle,
    this.color = AppColors.xpGold,
    this.autoDismiss = const Duration(milliseconds: 2500),
    this.size = 220,
    super.key,
  });

  final String asset;
  final String title;
  final String? subtitle;
  final Color color;
  final Duration autoDismiss;
  final double size;

  /// Helper that pushes the overlay onto the nearest [Navigator].
  static Future<void> show(BuildContext context, LottieOverlay overlay) {
    return showGeneralDialog<void>(
      context: context,
      barrierDismissible: true,
      barrierLabel: 'lottie-overlay',
      barrierColor: Colors.black.withValues(alpha: 0.6),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, anim, sec) => overlay,
      transitionBuilder: (ctx, anim, sec, child) => FadeTransition(opacity: anim, child: child),
    );
  }

  @override
  State<LottieOverlay> createState() => _LottieOverlayState();
}

class _LottieOverlayState extends State<LottieOverlay> {
  Timer? _timer;

  @override
  void initState() {
    super.initState();
    _triggerHaptic();
    _timer = Timer(widget.autoDismiss, _dismiss);
  }

  Future<void> _triggerHaptic() async {
    try {
      if (await Vibration.hasVibrator() == true) {
        Vibration.vibrate(duration: 50, amplitude: 200);
      }
    } catch (_) {}
  }

  void _dismiss() {
    if (mounted) Navigator.of(context).maybePop();
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: Center(
        child: GestureDetector(
          onTap: _dismiss,
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 32),
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: AppColors.surfaceDark,
              borderRadius: BorderRadius.circular(24),
              border: Border.all(color: widget.color.withValues(alpha: 0.4), width: 2),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: widget.size,
                  height: widget.size,
                  child: Lottie.asset(widget.asset, fit: BoxFit.contain, repeat: false),
                ),
                const SizedBox(height: 12),
                Text(
                  widget.title,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: widget.color,
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                    letterSpacing: 1.0,
                  ),
                ),
                if (widget.subtitle != null) ...[
                  const SizedBox(height: 4),
                  Text(
                    widget.subtitle!,
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: Colors.white, fontSize: 14),
                  ),
                ],
                const SizedBox(height: 12),
                const Text('Tap to dismiss', style: TextStyle(color: Colors.grey, fontSize: 11)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
