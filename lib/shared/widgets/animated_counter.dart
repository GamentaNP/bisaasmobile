import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';

class AnimatedCounter extends StatelessWidget {
  const AnimatedCounter({super.key, required this.value, this.style, this.duration = const Duration(milliseconds: 600)});
  final int value;
  final TextStyle? style;
  final Duration duration;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<int>(
      tween: IntTween(begin: 0, end: value),
      duration: duration,
      builder: (c, v, _) => Text('$v', style: style).animate().scale(duration: 150.ms),
    );
  }
}
