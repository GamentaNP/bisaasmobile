// ignore_for_file: prefer_int_literals, unawaited_futures

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:vibration/vibration.dart';

import '../../../../app/theme/app_colors.dart';

/// Triggers a brief Lottie at a given position (default = top of screen)
/// to celebrate a correct answer. Auto-removes after 600ms.
class AnswerFeedbackLottie extends StatefulWidget {
  const AnswerFeedbackLottie({
    required this.isCorrect,
    this.size = 120,
    super.key,
  });

  final bool isCorrect;
  final double size;

  static OverlayEntry show(BuildContext context, {required bool isCorrect, Offset? at}) {
    final entry = OverlayEntry(
      builder: (ctx) => Positioned(
        left: (at?.dx ?? MediaQuery.sizeOf(ctx).width / 2) - 60,
        top: (at?.dy ?? MediaQuery.sizeOf(ctx).height * 0.4) - 60,
        child: IgnorePointer(child: AnswerFeedbackLottie(isCorrect: isCorrect)),
      ),
    );
    Overlay.of(context, rootOverlay: true).insert(entry);
    return entry;
  }

  @override
  State<AnswerFeedbackLottie> createState() => _AnswerFeedbackLottieState();
}

class _AnswerFeedbackLottieState extends State<AnswerFeedbackLottie> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 700));
    _controller.forward();
    _haptic();
  }

  Future<void> _haptic() async {
    try {
      if (await Vibration.hasVibrator() == true) {
        Vibration.vibrate(duration: 30);
      }
    } catch (_) {}
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: widget.size,
      height: widget.size,
      child: Lottie.asset(
        widget.isCorrect
            ? 'assets/animations/correct_answer.json'
            : 'assets/animations/wrong_answer.json',
        fit: BoxFit.contain,
        repeat: false,
      ),
    );
  }
}

/// Float-up `+50 XP` text animation. Used after a correct answer.
class XpFloat extends StatefulWidget {
  const XpFloat({required this.amount, super.key});
  final int amount;

  static OverlayEntry show(BuildContext context, {required int amount, required Offset from}) {
    final entry = OverlayEntry(
      builder: (ctx) => XpFloatAnimator(from: from, amount: amount),
    );
    Overlay.of(context, rootOverlay: true).insert(entry);
    return entry;
  }

  @override
  State<XpFloat> createState() => _XpFloatState();
}

class _XpFloatState extends State<XpFloat> with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<Offset> _offset;
  late final Animation<double> _opacity;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: const Duration(milliseconds: 900));
    _offset = Tween<Offset>(begin: Offset.zero, end: const Offset(0, -2.0)).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutCubic),
    );
    _opacity = TweenSequence<double>(<TweenSequenceItem<double>>[
      TweenSequenceItem(tween: Tween(begin: 0.0, end: 1.0).chain(CurveTween(curve: Curves.easeIn)), weight: 20),
      TweenSequenceItem(tween: ConstantTween(1.0), weight: 50),
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 0.0).chain(CurveTween(curve: Curves.easeOut)), weight: 30),
    ]).animate(_controller);
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return FadeTransition(
      opacity: _opacity,
      child: SlideTransition(
        position: _offset,
        child: IgnorePointer(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.xpGold,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.bolt_rounded, color: Colors.white, size: 12),
                Text(
                  '+${widget.amount} XP',
                  style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class XpFloatAnimator extends StatelessWidget {
  const XpFloatAnimator({required this.from, required this.amount, super.key});
  final Offset from;
  final int amount;
  @override
  Widget build(BuildContext context) {
    return Positioned(
      left: from.dx - 30,
      top: from.dy - 30,
      child: XpFloat(amount: amount),
    );
  }
}
