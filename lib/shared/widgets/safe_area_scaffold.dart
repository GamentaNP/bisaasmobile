import 'package:flutter/material.dart';

import '../../app/theme/app_colors.dart';

/// Scaffold with the ambient glow background, safe areas and an optional
/// glass app bar — the standard premium screen shell.
class SafeAreaScaffold extends StatelessWidget {
  const SafeAreaScaffold({
    super.key,
    required this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.background,
    this.extendBodyBehindAppBar = false,
  });

  final Widget body;
  final PreferredSizeWidget? appBar;
  final Widget? bottomNavigationBar;
  final Widget? floatingActionButton;
  final Color? background;
  final bool extendBodyBehindAppBar;

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Scaffold(
      appBar: appBar,
      backgroundColor: background ?? (isDark ? AppColors.backgroundDark : AppColors.backgroundLight),
      body: SafeArea(child: body),
      bottomNavigationBar: bottomNavigationBar,
      floatingActionButton: floatingActionButton,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
    );
  }
}
