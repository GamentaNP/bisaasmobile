import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// Three lifelines: 50/50, Hint, Skip.
///
/// Each callback is fired when the user taps the corresponding chip.
/// The bar reports remaining uses via [remaining] map; once a key is
/// exhausted, the chip renders disabled. `null` remaining = unlimited.
class LifelineBar extends StatelessWidget {
  const LifelineBar({
    required this.onFiftyFifty,
    required this.onHint,
    required this.onSkip,
    this.remaining = const {'50_50': 1, 'hint': 1, 'skip': 1},
    super.key,
  });

  final VoidCallback onFiftyFifty;
  final VoidCallback onHint;
  final VoidCallback onSkip;
  final Map<String, int> remaining;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      children: [
        _Lifeline(
          icon: Icons.filter_5_rounded,
          label: '50/50',
          count: remaining['50_50'] ?? 0,
          onTap: onFiftyFifty,
        ),
        _Lifeline(
          icon: Icons.lightbulb_outline_rounded,
          label: 'Hint',
          count: remaining['hint'] ?? 0,
          onTap: onHint,
        ),
        _Lifeline(
          icon: Icons.skip_next_rounded,
          label: 'Skip',
          count: remaining['skip'] ?? 0,
          onTap: onSkip,
        ),
      ],
    );
  }
}

class _Lifeline extends StatelessWidget {
  const _Lifeline({required this.icon, required this.label, required this.count, required this.onTap});
  final IconData icon;
  final String label;
  final int count;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final exhausted = count <= 0;
    return Semantics(
      button: true,
      label: '$label lifeline, $count remaining',
      enabled: !exhausted,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: exhausted ? null : onTap,
        child: Opacity(
          opacity: exhausted ? 0.4 : 1.0,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: AppColors.lifelineCyan.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: AppColors.lifelineCyan.withValues(alpha: 0.4)),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(icon, size: 14, color: AppColors.lifelineCyan),
                const SizedBox(width: 4),
                Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: AppColors.lifelineCyan)),
                if (count > 0) ...[
                  const SizedBox(width: 4),
                  Text('×$count', style: const TextStyle(fontSize: 10, color: AppColors.lifelineCyan)),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}
