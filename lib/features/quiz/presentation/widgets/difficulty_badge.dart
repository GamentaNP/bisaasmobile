import 'package:flutter/material.dart';

import '../../../../app/theme/app_colors.dart';

/// Visual difficulty indicator. `1` = easy, `2` = medium, `3` = hard, `4+` = expert.
class DifficultyBadge extends StatelessWidget {
  const DifficultyBadge({required this.difficulty, this.compact = false, super.key});

  final int difficulty;
  final bool compact;

  String get _label => switch (difficulty) {
        1 => 'Easy',
        2 => 'Medium',
        3 => 'Hard',
        _ => 'Expert',
      };

  Color get _color => switch (difficulty) {
        1 => AppColors.correctGreen,
        2 => AppColors.lifelineCyan,
        3 => AppColors.streakOrange,
        _ => AppColors.wrongRed,
      };

  IconData get _icon => switch (difficulty) {
        1 => Icons.sentiment_satisfied_alt_rounded,
        2 => Icons.bolt_rounded,
        3 => Icons.local_fire_department_rounded,
        _ => Icons.whatshot_rounded,
      };

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(horizontal: compact ? 8 : 10, vertical: compact ? 3 : 4),
      decoration: BoxDecoration(
        color: _color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _color.withValues(alpha: 0.4)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(_icon, color: _color, size: compact ? 11 : 14),
          SizedBox(width: compact ? 3 : 4),
          Text(
            _label,
            style: TextStyle(
              color: _color,
              fontSize: compact ? 10 : 11,
              fontWeight: FontWeight.bold,
              letterSpacing: 0.4,
            ),
          ),
        ],
      ),
    );
  }
}
