import 'package:flutter/material.dart';

import '../../app/theme/app_icons.dart';
import '../../app/theme/app_radii.dart';

/// Premium bottom navigation — pill indicator behind the selected icon,
/// brand glow, safe-area aware. Five destinations matching the shell.
class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentIndex, required this.onTap});

  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: [
        _destination(AppIcons.home, 'Home'),
        _destination(AppIcons.quiz, 'Quiz'),
        _destination(AppIcons.calculator, 'Tools'),
        _destination(AppIcons.library, 'Library'),
        _destination(AppIcons.profile, 'Profile'),
      ],
      indicatorColor: scheme.primary.withValues(alpha: 0.16),
      indicatorShape: RoundedRectangleBorder(
        borderRadius: AppRadii.mdAll,
      ),
    );
  }

  NavigationDestination _destination(IconData icon, String label) {
    return NavigationDestination(
      icon: Icon(icon),
      selectedIcon: Icon(icon, size: 24),
      label: label,
    );
  }
}
