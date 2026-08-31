import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../shared/widgets/offline_state_banner.dart';
import '../theme/app_icons.dart';

/// Scaffold with persistent bottom navigation bar for StatefulShellRoute branches.
class AppShellScaffold extends StatelessWidget {
  const AppShellScaffold({
    required this.navigationShell,
    super.key,
  });

  final StatefulNavigationShell navigationShell;

  void _onTap(int index) {
    navigationShell.goBranch(
      index,
      initialLocation: index == navigationShell.currentIndex,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          const OfflineStateBanner(),
          Expanded(child: navigationShell),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onTap,
        destinations: const [
          NavigationDestination(
            icon: Icon(AppIcons.home),
            selectedIcon: Icon(AppIcons.home),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.quiz),
            selectedIcon: Icon(AppIcons.quiz),
            label: 'Practice',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.calculator),
            selectedIcon: Icon(AppIcons.calculator),
            label: 'Calculators',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.courses),
            selectedIcon: Icon(AppIcons.courses),
            label: 'Courses',
          ),
          NavigationDestination(
            icon: Icon(AppIcons.profile),
            selectedIcon: Icon(AppIcons.profile),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
