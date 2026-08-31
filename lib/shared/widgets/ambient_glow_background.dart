import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// CivilCal signature background: a dark base with two slow-drifting radial
/// glow blobs (brand cyan top-right, guild purple bottom-left) and an optional
/// subtle noise texture. Wrap screen bodies in this to get the premium
/// glassmorphic look described in FLUTTER_APP_MASTER_PLAN_2026 §22.2.
///
/// Respects the platform reduce-motion setting (blobs stop drifting) and keeps
/// the paint cheap (two gradients + a low-opacity noise layer) so it never
/// threatens the 60fps budget.
class AmbientGlowBackground extends StatefulWidget {
  const AmbientGlowBackground({
    required this.child,
    this.baseColor = AppColors.backgroundDark,
    this.showNoise = true,
    super.key,
  });

  final Widget child;
  final Color baseColor;
  final bool showNoise;

  @override
  State<AmbientGlowBackground> createState() => _AmbientGlowBackgroundState();
}

class _AmbientGlowBackgroundState extends State<AmbientGlowBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(seconds: 12),
  );

  @override
  void initState() {
    super.initState();
    _controller.repeat();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final reduceMotion = MediaQuery.maybeOf(context)?.disableAnimations ?? false;
    return Stack(
      fit: StackFit.expand,
      children: [
        ColoredBox(color: widget.baseColor),
        AnimatedBuilder(
          animation: _controller,
          builder: (context, _) {
            final t = reduceMotion ? 0.0 : _controller.value;
            return CustomPaint(
              painter: _GlowPainter(
                phase: t * 2 * math.pi,
                animate: !reduceMotion,
              ),
            );
          },
        ),
        if (widget.showNoise && !reduceMotion)
          const IgnorePointer(child: CustomPaint(painter: _NoisePainter())),
        widget.child,
      ],
    );
  }
}

class _GlowPainter extends CustomPainter {
  const _GlowPainter({required this.phase, required this.animate});
  final double phase;
  final bool animate;

  @override
  void paint(Canvas canvas, Size size) {
    final drift = animate ? math.sin(phase) : 0.0;

    // Top-right cyan blob (~15% opacity, large radius).
    final cyan = RadialGradient(
      center: Alignment(0.9 - 0.05 * drift, -0.9 + 0.05 * drift),
      radius: 0.9,
      colors: [
        AppColors.brand.withValues(alpha: 0.15),
        AppColors.brand.withValues(alpha: 0),
      ],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = cyan.createShader(Offset.zero & size),
    );

    // Bottom-left purple blob (~10% opacity).
    final purple = RadialGradient(
      center: Alignment(-0.9 + 0.05 * drift, 0.9 - 0.05 * drift),
      radius: 0.8,
      colors: [
        AppColors.comboPurple.withValues(alpha: 0.10),
        AppColors.comboPurple.withValues(alpha: 0),
      ],
    );
    canvas.drawRect(
      Offset.zero & size,
      Paint()..shader = purple.createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(_GlowPainter old) => old.phase != phase;
}

/// Very light static speckle overlay (~3% opacity) for texture. Deterministic
/// so it doesn't flicker between frames.
class _NoisePainter extends CustomPainter {
  const _NoisePainter();

  @override
  void paint(Canvas canvas, Size size) {
    final rnd = math.Random(42);
    final paint = Paint()..color = Colors.white.withValues(alpha: 0.03);
    const count = 220;
    for (var i = 0; i < count; i++) {
      canvas.drawCircle(
        Offset(rnd.nextDouble() * size.width, rnd.nextDouble() * size.height),
        rnd.nextDouble() * 1.2,
        paint,
      );
    }
  }

  @override
  bool shouldRepaint(covariant _NoisePainter old) => false;
}
