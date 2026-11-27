import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';
import '../../../../app/theme/app_motion.dart';
import '../../../../app/theme/app_radii.dart';
import '../../../../app/theme/app_shadows.dart';
import '../../../../l10n/app_localizations.dart';

/// Premium countdown for the target exam. Every digit change flips in 3D;
/// reduced-motion users get the same numbers with no animation at all.
class FlipCountdown extends StatefulWidget {
  const FlipCountdown({
    super.key,
    required this.targetDate,
    required this.daysRemaining,
    DateTime Function()? now,
  }) : _now = now ?? DateTime.now;

  /// ISO date published by the server (a date-only string is accepted too).
  final String? targetDate;

  /// Server-published days remaining, used when no target date is available.
  final int? daysRemaining;

  /// Injectable only so a widget test can hold the clock still.
  final DateTime Function() _now;

  @override
  State<FlipCountdown> createState() => _FlipCountdownState();
}

class _FlipCountdownState extends State<FlipCountdown> {
  Timer? _timer;
  late final DateTime? _target;
  late Duration _remaining;

  @override
  void initState() {
    super.initState();
    _target = _resolveTarget();
    _remaining = _timeLeft();
    // An expired countdown has nothing to tick: it stays at all zeros.
    if (_remaining > Duration.zero) {
      _timer = Timer.periodic(const Duration(seconds: 1), (_) => _tick());
    }
  }

  DateTime? _resolveTarget() {
    final iso = DateTime.tryParse(widget.targetDate?.trim() ?? '');
    // Keep the parsed zone: an ISO `Z` target stays UTC, a date-only server
    // value is already interpreted in the device's local zone.
    if (iso != null) return iso;
    final days = widget.daysRemaining;
    if (days == null) return null;
    return widget._now().add(Duration(days: days));
  }

  Duration _timeLeft() {
    final target = _target;
    if (target == null) return Duration.zero;
    final left = target.difference(widget._now());
    return left.isNegative ? Duration.zero : left;
  }

  void _tick() {
    final next = _timeLeft();
    if (next == _remaining) return;
    setState(() => _remaining = next);
    if (next == Duration.zero) {
      _timer?.cancel();
      _timer = null;
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    final reduceMotion = MediaQuery.disableAnimationsOf(context);
    final parts = _partsOf(_remaining);
    final caption = l10n.eiceCountdownParts(
      parts[0],
      parts[1],
      parts[2],
      parts[3],
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          l10n.eiceExamIn(caption),
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 6),
        Row(
          children: [
            for (final part in parts) _FlipUnit(value: part, animate: !reduceMotion),
          ],
        ),
      ],
    );
  }

  static List<String> _partsOf(Duration value) {
    final days = value.inDays;
    final hours = value.inHours % 24;
    final minutes = value.inMinutes % 60;
    final seconds = value.inSeconds % 60;
    return <String>[
      _twoDigits(days),
      _twoDigits(hours),
      _twoDigits(minutes),
      _twoDigits(seconds),
    ];
  }

  static String _twoDigits(int value) => value.toString().padLeft(2, '0');
}

class _FlipUnit extends StatelessWidget {
  const _FlipUnit({required this.value, required this.animate});

  final String value;
  final bool animate;

  @override
  Widget build(BuildContext context) {
    final box = Container(
      key: ValueKey<String>(value),
      width: 44,
      padding: const EdgeInsets.symmetric(vertical: 7),
      alignment: Alignment.center,
      decoration: BoxDecoration(
        gradient: AppColors.brandGradient,
        borderRadius: AppRadii.smAll,
        boxShadow: AppShadows.glowBrand,
      ),
      child: Text(
        value,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.bold,
          color: AppColors.backgroundLight,
        ),
      ),
    );

    final padded = Padding(
      padding: const EdgeInsets.only(right: 6),
      child: box,
    );
    if (!animate) return padded;

    return Padding(
      padding: const EdgeInsets.only(right: 6),
      child: AnimatedSwitcher(
        duration: AppMotion.base,
        switchInCurve: AppMotion.easeOut,
        switchOutCurve: AppMotion.easeInOut,
        transitionBuilder: (child, animation) {
          final slide = Tween<Offset>(
            begin: const Offset(0, 0.55),
            end: Offset.zero,
          ).animate(animation);
          return SlideTransition(
            position: slide,
            child: Transform(
              transform: Matrix4.identity()
                ..setEntry(3, 2, 0.0018)
                ..rotateX((1 - animation.value) * 0.9),
              alignment: Alignment.center,
              child: FadeTransition(opacity: animation, child: child),
            ),
          );
        },
        child: box,
      ),
    );
  }
}
