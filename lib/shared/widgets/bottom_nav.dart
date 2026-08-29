import 'package:flutter/material.dart';

import '../../app/theme/app_icons.dart';

class AppBottomNav extends StatelessWidget {
  const AppBottomNav({super.key, required this.currentIndex, required this.onTap});
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return NavigationBar(
      selectedIndex: currentIndex,
      onDestinationSelected: onTap,
      destinations: const [
        NavigationDestination(icon: Icon(AppIcons.home), label: 'Home'),
        NavigationDestination(icon: Icon(AppIcons.quiz), label: 'Quiz'),
        NavigationDestination(icon: Icon(AppIcons.calculator), label: 'Tools'),
        NavigationDestination(icon: Icon(AppIcons.library), label: 'Library'),
        NavigationDestination(icon: Icon(AppIcons.profile), label: 'Profile'),
      ],
    );
  }
}
