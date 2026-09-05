import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';
import '../../app/theme/app_icons.dart';
import '../../app/theme/app_typography.dart';

/// Duolongo bottom navigation — white slab with a 2px top rule, filled
/// green icon + w800 label for the active destination (sample tab bar).
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final divider =
        isDark ? AppColors.dividerDark : AppColors.dividerLight;
    final inactive =
        isDark ? AppColors.textTertiaryDark : AppColors.textTertiaryLight;

    Widget destination(IconData icon, String label, int index) {
      final selected = currentIndex == index;
      final color = selected ? AppColors.brand : inactive;
      return Expanded(
        child: InkWell(
          onTap: () => onTap(index),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, size: 26, color: color),
              const SizedBox(height: 2),
              Text(
                label,
                style: AppTypography.labelSmall.copyWith(
                  color: color,
                  fontSize: 11,
                  fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
        border: Border(top: BorderSide(color: divider, width: 2)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: [
              destination(AppIcons.home, 'Home', 0),
              destination(AppIcons.quiz, 'Quiz', 1),
              destination(AppIcons.calculator, 'Tools', 2),
              destination(AppIcons.library, 'Library', 3),
              destination(AppIcons.profile, 'Profile', 4),
            ],
          ),
        ),
      ),
    );
  }
}
