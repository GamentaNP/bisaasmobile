// ignore_for_file: prefer_int_literals

import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// Circular badge with current level + optional title tooltip.
class LevelBadge extends StatelessWidget {
  const LevelBadge({required this.level, this.size = 56, this.title, super.key});
  final int level;
  final double size;
  final String? title;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Level $level${title != null ? ", $title" : ""}',
      child: Tooltip(
        message: title ?? 'Level $level',
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: const LinearGradient(
              colors: [AppColors.xpGold, AppColors.streakOrange],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            border: Border.all(color: Colors.white.withValues(alpha: 0.6), width: 2),
            boxShadow: [
              BoxShadow(color: AppColors.xpGold.withValues(alpha: 0.4), blurRadius: 8, offset: const Offset(0, 2)),
            ],
          ),
          alignment: Alignment.center,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('LV', style: TextStyle(color: Colors.white, fontSize: size * 0.18, fontWeight: FontWeight.bold, letterSpacing: 0.5)),
              Text('$level', style: TextStyle(color: Colors.white, fontSize: size * 0.36, fontWeight: FontWeight.bold, height: 1.0)),
            ],
          ),
        ),
      ),
    );
  }
}
